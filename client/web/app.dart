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

import 'dart:html';
import 'package:dart_OXO_client/client_library.dart';

void main() {
  // Drawing logo
  drawLogo();

  // Instantiating a new Game() class
  Game game = new Game();

  // Initializing WebSocket connection
  Connection conn = new Connection("ws://" + window.location.host + "/ws",game);

  // Binding the login function to the login button's onClick event and setting
  // player's nickname
  loginBtn.onClick.listen((e) {
    if(inputNickname.value != "") {
      game.me.nickname = inputNickname.value;
      conn.send({"cmd":"getNumber","arg":game.me.nickname});
    }
  });

  // Binding the onClick canvas' event
  canvasGame.onClick.listen((MouseEvent e){
    // Sending click
    int cell = getCellFromCoordinates(e.offset.x, e.offset.y);

    // Checking if it's your turn and if the cell is not occupied
    if(game.me.myTurn && !game.occupiedCells.contains(cell)) {
      conn.send({
        "cmd" : "move",
        "arg" : {
          "player" : game.me.number,
          "cell"   : cell
        }
      });
    }
  });
}