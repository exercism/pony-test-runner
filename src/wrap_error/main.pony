use @exit[None](forced_exit_code: I32)
use "files"
use "json"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let compile_error_file: FilePath = FilePath(FileAuth(env.root), compile_outpath())

    try
      if (not compile_error_file.exists()) then
        fatal_error("error: failed to find compiler output - please raise an issue on exercism/pony-test-runner")
        error
      end

      let filelines: FileLines = File(compile_error_file).lines()

      let rv: String trn = recover trn String end
      for line in filelines do
        rv.append(consume line)
      end
      rv

      fatal_error(consume rv)
      error
    end


  fun compile_outpath(): String val =>
    let rv: String val =
      try
        env.args.apply(1)?
      else
        "/foo"
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
//      @exit(0)
