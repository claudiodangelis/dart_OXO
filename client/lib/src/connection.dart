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

part of client_library;

class Connection {

  WebSocket ws;
  String url;
  Game game;

  Connection(this.url, this.game) {
    _init();
  }

  void _init() {
    ws = new WebSocket(this.url);
    ws.onOpen.listen((e){
      // Connection established
    });

    ws.onClose.listen((e){
      // Server connection lost
    });

    ws.onMessage.listen((e){
      // Client receives a message from server
      Map dataFromServer = JSON.decode(e.data);
      // Choosing an action accordingly to command sent by server
      switch(dataFromServer["cmd"]) {
        case "start":
          // Both players are ready to start
          // Assigning players' data to local objects
          game.me.myTurn =
              JSON.decode(
                  dataFromServer["arg"][game.me.number.toString()]
                  )["myTurn"];

          game.me.points =
              JSON.decode(
                  dataFromServer["arg"][game.me.number.toString()]
                  )["points"];

          game.opponent.nickname =
              JSON.decode(
                  dataFromServer["arg"][game.opponent.number.toString()]
                  )["nickname"];

          game.opponent.points =
              JSON.decode(
                  dataFromServer["arg"][game.opponent.number.toString()]
                  )["points"];

          updateGameStats(game);
          if(game.me.myTurn) {
            queue((){
              updateStatus("It's your turn");
            });
          } else {
            queue((){
              updateStatus("It's ${game.opponent.nickname}'s turn");
            });
          }
          // Clearing `occupiedCells`
          game.occupiedCells.clear();
          contextGame.clearRect(0, 0, 600, 600);
          drawGrid();
          // End of start command
          break;

        case "accessDenied":
          // There's no room for you, showing an error
          accessDenied();
          break;
        case "setNumber":
          // Player receives his player number
          game.me.number = dataFromServer["arg"];
          game.opponent.number = (game.me.number % 2) + 1;
          if(game.me.number == 1) {
            // I'm the first player, gonna wait for second
            updateStatus("Please wait for the second player to join in.");
          } else {
            // I'm the second player, we can start playing
            updateStatus("Game is about to start.");
          }
          hideLogin();
          // End setNumber command
          break;
        case "move":
          // Receiving move's data

          int cell = dataFromServer["arg"]["cell"];
          int player = dataFromServer["arg"]["player"];

          // Add cell to occupied cell, so you can't click on it
          game.occupiedCells.add(cell);

          // Draws the cell accordingly to player
          drawCell(contextGame, cell, player);

          // Toggle turns
          game.me._toggleTurn();
          game.opponent._toggleTurn();

          if(game.me.myTurn) {
            updateStatus("It's your turn");
          } else {
            updateStatus("It's ${game.opponent.nickname}'s turn.");
          }
          // End move command
          break;
        case "end":
          // Setting `myTurn` to false to prevent user's click
          game.me.myTurn = false;

          // Checking if someone won the game
          if(dataFromServer["arg"] != "drawn") {
            // Receiving data about the end of the game from the server
            List<int> triple = dataFromServer["arg"]["triple"];
            int number = dataFromServer["arg"]["winner"];
            highlightCells(triple, number);
            if(game.me.number == number) {
              updateStatus("You won!");
            } else {
              updateStatus("${game.opponent.nickname} won.");
            }

          } else {
            // Nobody won, showing a message
            updateStatus("Drawn game. Nobody wins.");
          }
          // End "end" command
          break;
        case "reset":
          // We lost a connection, resetting all the data
          updateGameStats(game);
          game.me._reset();
          game.opponent._reset();
          // Clearing occupied cells
          game.occupiedCells.clear();
          // Showing the login panel
          showLogin();
          break;
        case "message":
          // Shows the message received from server
          updateStatus(dataFromServer["arg"]);
          break;
      }
    });
  }


  void send(Map message) {
    // Sends stringified map-based message to server
    ws.send(JSON.encode(message));
  }
}