//   Copyright 2013 Claudio d'Angelis <claudiodangelis@gmail.com>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

import 'dart:io';
import 'dart:async';

import 'package:dart_OXO_server/server_library.dart';

void runServer(String basePath, int port) {

  GameHandler gameHandler = new GameHandler();

  defaultRequestHandler(HttpRequest request) {
    String path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    File file = new File('${basePath}${path}');
    file.exists().then((bool found) {
      if (found) {
        file.openRead().pipe(request.response);
      } else {
        request.response.statusCode = HttpStatus.NOT_FOUND;
        request.response.close();
      }
    });
  }

  HttpServer.bind("0.0.0.0", port).then((HttpServer server) {
    print("Server is running —> http://localhost:${port}");
    var sc = new StreamController();
    sc.stream.transform(new WebSocketTransformer()).listen(
        gameHandler.onConnection
        );

    server.listen((HttpRequest request) {
      if(request.uri.path == "/ws") {
        // Redirecting request to websocket handler
        sc.add(request);
      } else {
        defaultRequestHandler(request);
      }
    });
  });
}

void main() {
  // Running the server
  runServer("../../client/build/web", 4000);
}
