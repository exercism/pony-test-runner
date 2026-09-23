use "files"
use "debug"
use "process"
use "buffered"
use "backpressure"

class ProcessRunner is ProcessNotify
  let outbuf: Reader = Reader
  let errbuf: Reader = Reader
  let main: Main tag

  new iso create(main': Main tag) =>
    main = main'

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    outbuf.append(consume data)

  fun ref stderr(process: ProcessMonitor ref, data: Array[U8] iso) =>
    errbuf.append(consume data)

  fun ref failed(process: ProcessMonitor ref, err: ProcessError) => None
    Debug.out(err.string())

  fun ref dispose(
    process: ProcessMonitor ref,
    child_exit_status: ProcessExitStatus)
  =>
    match child_exit_status
    | let exited: Exited =>
      handle_exit(exited.exit_code())
    | let signaled: Signaled =>
      Debug.out(
        "Child terminated by signal: "
          + signaled.signal().string())
    end

  fun ref handle_exit(exitcode: I32) =>
    var line: String val = ""
    try
      while (true) do
        line = outbuf.line()?
        if (line.contains("Assert") and line.contains("test.pony")) then
          main.result(line)
        end
      end
    end
    if (exitcode == 0) then
      main.success()
    else
      main.fail()
    end

