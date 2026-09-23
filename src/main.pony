use "json"
use "files"
use "debug"
use "process"
use "collections"
use "backpressure"

actor Main
  let env: Env
  let test_source: Array[String] trn = recover trn [] end
  let exercism_version: I64 = 2
  var slug: String
  var workdir: String
  var inputdir: String
  var outputdir: String
  var tps: Array[String val] = Array[String val]
  var results: Array[JSONObject] = Array[JSONObject]

  new create(env': Env) =>
		env = env'
    slug = try env.args(1)? else "/noworkdir" end
    workdir = try env.args(2)? else "/noworkdir" end
    inputdir = try env.args(3)? else "/noinputdir" end
    outputdir = try env.args(4)? else "/nooutputdir" end
    
    Debug.out("Workdir: " + workdir)
    Debug.out("InputDir: " + inputdir)
    Debug.out("OutputDir: " + outputdir)

    match OpenFile(FilePath(FileAuth(env.root), workdir + "/test.pony"))
    | let file: File => Debug.out("test.pony file found")
      for line in file.lines() do
        tps.push(consume line)
      end
    | let err: FileErrNo => Debug.out("test.pony failed")
    end

    // Test if the compilation output exists…
    var execfp: FilePath = FilePath(FileAuth(env.root), workdir + "/" + slug)
    if (execfp.exists()) then
      Debug.out(workdir + "/" + slug + " exists")
      go_execution()
    else
      Debug.out(workdir + "/" + slug + " does NOT exist")
      compilation_failure()
    end

  fun compilation_failure() =>
    let coutfp: FilePath = FilePath(FileAuth(env.root), workdir + "/" + "compile.stdout")
    let cerrfp: FilePath = FilePath(FileAuth(env.root), workdir + "/" + "compile.stderr")

    var compout: String trn = recover iso String end
    if (coutfp.exists()) then
      match OpenFile(coutfp)
      | let file: File => compout.append(file.read_string(file.size()))
      end
    else
      Debug.out("coutfp does not exist")
    end

    if (cerrfp.exists()) then
      match OpenFile(cerrfp)
      | let file: File => compout.append(file.read_string(file.size()))
      end
    else
      Debug.out("cerrfp does not exist")
    end
    failure(consume compout)


  fun failure(str: String) =>

    var doc: JSONObject = JSONObject
      .update("version", exercism_version)
      .update("status", "error")
      .update("message", str)

    write_json(JSONPrinter.pretty(doc))

  fun ref go_execution() => None
    let notifier: ProcessNotify iso = ProcessRunner(this)
    let fp: FilePath = FilePath(FileAuth(env.root), workdir + "/" + slug)
    let args: Array[String] val = [slug; "--verbose"]

    match StartProcess(StartProcessAuth(env.root), ApplyReleaseBackpressureAuth(env.root), consume notifier, fp, args, env.vars)
    | let pm: ProcessMonitor => None
    | let err: ProcessError => Debug.out("Failed: " + err.string())
    end

  be result(str: String val) =>
    var testres: JSONObject = JSONObject
    (var linenum: I32,
     var test: String val,
     var desc: String val,
     var mess: String val,
     var verdict: Bool) = parse_line(str)
    Debug.out("Linenum: " + linenum.string())
    Debug.out("Desc: " + desc)
    Debug.out("Test: " + test)
    Debug.out("Verdict: " + verdict.string())

    testres = testres
                .update("status", if (verdict) then "pass" else "fail" end)
                .update("test_code", test)
                .update("name", strip_comment(desc))
    
    if (not verdict) then
      testres = testres.update("message", mess)
    end
    results.push(testres)

  be success() => 
    final_assembly(
      JSONObject
        .update("version", exercism_version)
        .update("status", "pass")
    )

  be fail() => Debug.out("fail")
    final_assembly(
      JSONObject
        .update("version", exercism_version)
        .update("status", "fail")
    )

  fun final_assembly(jo: JSONObject) =>
    var jsonarray: JSONArray = JSONArray
    for res in results.values() do
      jsonarray = jsonarray.push(res)
    end
    var final = jo.update("tests", jsonarray)

    write_json(JSONPrinter.pretty(final))

  fun parse_line(str: String): (I32, String val, String val, String val, Bool) =>
    var line: I32 = 0
    var test: String val = ""
    var desc: String val = ""
    var mess: String val = ""
    var verdict: Bool = false
    var s: Array[String val] = str.split_by(":")
    try
      line = s(1)?.i32()?
      test = tps(line.usize() - 1)?.clone().>strip()
      desc = tps(line.usize() - 2)?.clone().>strip()
      mess = strip_assert(str).clone().>strip()

      if (str.contains("passed")) then verdict = true end
    end
    (line, test, desc, mess, verdict)

  fun write_json(str: String) =>
    let fp: FilePath = FilePath(FileAuth(env.root), outputdir + "/results.json")
    let file: File = File(fp)
    file.set_length(0)
    file.write(str + "\n")
    file.dispose()

  fun strip_comment(str: String): String =>
    try
      let idx: ISize = str.find("// ")?
      str.substring(idx+3)
    else
      str
    end

  fun strip_assert(str: String): String =>
    try
      let idx: ISize = str.find("Assert ")?
      str.substring(idx)
    else
      str
    end
//		let pony_test_results_file: FilePath = FilePath(FileAuth(env.root), compile_outpath())
//		let ponytest_source_file: FilePath = FilePath(FileAuth(env.root), compile_testpony())
//
//    let doc: JSONObject = JSONObject
//      .update("version", exercism_version)
//      .update("status", "pass")


 //   env.out.print(JSONPrinter.pretty(doc))
    /*
    try
			if (not pony_test_results_file.exists()) then
				fatal_error("error: We were unable to find any output from our tests - please raise an issue on exercism/pony-test-runner")
				error
			end
			if (not ponytest_source_file.exists()) then
				fatal_error("error: We were unable to find the test.pony file for your exercise - please raise an issue on exercism/pony-test-runner")
				error
			end

      let srclines: FileLines = File(ponytest_source_file).lines()
      for srcline in srclines do
        test_source.push(consume srcline)
      end

      let result_lines: FileLines = File(pony_test_results_file).lines()

      let jsonresults: Array[JsonType] = Array[JsonType]

      for result_line in result_lines do
        let res: String val = consume result_line
        if (res.contains("Assert")) then
          if (res.contains(" passed.  Got ")) then
            jsonresults.push(pass(res))
            continue
          end
          if (res.contains(" failed.  Expected ")) then
            jsonresults.push(fail(res))
            continue
          end
          fatal_error(res)
        end
      end
      mainjsonobj.data("tests") = JsonArray.from_array(jsonresults)
      jdoc.data = mainjsonobj
      env.out.print(jdoc.string(where indent="  ", pretty_print=true))
		end

  fun pass(str: String): JsonObject =>
    let jsonobj: JsonObject = JsonObject
    let rarray: Array[String] = str.split_by(":")
    var remainder: String = ""

    try
      let filename: String = rarray.shift()?
      let linenum: USize = rarray.shift()?.usize()?
      try
        jsonobj.data("status") = "pass"
        jsonobj.data("name") = test_source.apply(linenum - 2)?
        jsonobj.data("test_code") = test_source.apply(linenum - 1)?
      end
    end
    jsonobj

  fun ref fail(str: String): JsonObject =>
    let jsonobj: JsonObject = JsonObject
    let rarray: Array[String] = str.split_by(":")
    var remainder: String = ""

    try
      let filename: String = rarray.shift()?
      let linenum: USize = rarray.shift()?.usize()?
      try
        mainjsonobj.data("status") = "fail"
        jsonobj.data("status") = "fail"
        jsonobj.data("name") = strip_comment(test_source.apply(linenum - 2)?)
        jsonobj.data("test_code") = test_source.apply(linenum - 1)?.clone().>lstrip()
        jsonobj.data("message") = ":".join(rarray.values()).>lstrip()
      end
    end
    jsonobj

*/
