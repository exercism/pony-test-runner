use "json"
use "files"

actor Main
  let env: Env
  let test_source: Array[String] trn = recover trn [] end
  let jdoc: JsonDoc = JsonDoc
  let mainjsonobj: JsonObject = JsonObject

  new create(env': Env) =>
		env = env'

		let pony_test_results_file: FilePath = FilePath(FileAuth(env.root), compile_outpath())
		let ponytest_source_file: FilePath = FilePath(FileAuth(env.root), compile_testpony())

    mainjsonobj.data("version") = I64(2)
    mainjsonobj.data("status") = "pass"

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

  fun compile_testpony(): String val =>
    let rv: String val =
      try
        env.args.apply(2)?
      else
        "/no_test.pony_found"
      end

    rv


  fun compile_outpath(): String val =>
    let rv: String val =
      try
        env.args.apply(1)?
      else
        "/no_sources_found"
      end

    rv

  fun fatal_error(text: String) =>
    let doc: JsonDoc = JsonDoc
    let obj: JsonObject = JsonObject

    obj.data("version") = I64(3)
    obj.data("status") = "error"
    obj.data("message") = text
    doc.data = obj

    env.out.print(doc.string(where indent="  ", pretty_print=true))

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
        jsonobj.data("version") = I64(2)
        jsonobj.data("status") = "fail"
        jsonobj.data("name") = test_source.apply(linenum - 2)?
        jsonobj.data("test_code") = test_source.apply(linenum - 1)?
        jsonobj.data("message") = ":".join(rarray.values())
      end
    end
    jsonobj

