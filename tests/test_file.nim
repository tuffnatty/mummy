from std/appdirs import getTempDir
from std/os import removeFile
from std/paths import Path, `/`
from std/strutils import repeat

import httpclient, mummy


const filename = string(getTempDir() / "mummy_test".Path)

proc handler(request: Request) =
  echo request
  doAssert request.uri == request.path
  case request.uri:
  of "/file":
    if request.httpMethod == "GET":
      let headers = mummy.HttpHeaders(@[("Content-Type", "text/plain")])
      var file = open(filename)
      request.respondFile(200, headers, file)
      file.close
  doAssert request.responded == true


writeFile(filename, "abcdefghijklmnopqrstuvwxyz".repeat(10000))

let server = newServer(handler)

var requesterThread: Thread[void]

proc requesterProc() =
  server.waitUntilReady()

  block:
    let client = newHttpClient()
    let response = client.request("http://localhost:8081/file")
    doAssert response.headers["Content-Length"] == "260000"
    doAssert response.body == "abcdefghijklmnopqrstuvwxyz".repeat(10000)

  echo "Done, shut down the server"
  server.close()

createThread(requesterThread, requesterProc)

# Start the server
server.serve(Port(8081))

removeFile filename
