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

part of server_library;

class GameHandler {

  Player playerOne;
  Player playerTwo;
  int moves;
  int lastFirstTurn;
  bool hasWinner;

  /*
   * Representing grid's cells as list:
   *   Indexes:
   *   0 1 2  first row
   *   3 4 5  second row
   *   6 7 8  third row
   *
   *   Values:
   *   0 = blank
   *   1 = player 1
   *   2 = player 2
   */

  List grid;

  int gameStatus;

  GameHandler() {
    gameStatus = 0;
    moves;
    hasWinner;
  }

  Set<WebSocket> wsConnections= new Set<WebSocket>();
  onConnection(WebSocket conn) {
    // Server receives a message
    void onMessage(String message) {
      Map dataFromClient = JSON.parse(message);
      // Choosing an action accordingly to received command
      switch(dataFromClient["cmd"]){
        case "getNumber":
          // Checking if there's room for one more player
          if(wsConnections.length==2) {
            conn.add(JSON.stringify({"cmd":"accessDenied"}));
          } else {
            if (playerOne == null) {
              // First player to join, assigning
              playerOne = new Player(dataFromClient["arg"]);
              // Sending the number to the client
              conn.add(JSON.stringify({"cmd":"setNumber","arg":1}));
              // Adding the connections to wsConnections
              wsConnections.add(conn);
            } else {
              // Player one exists, so assigning to player two
              playerTwo = new Player(dataFromClient["arg"]);
              // Sending the number to the client
              conn.add(JSON.stringify({"cmd":"setNumber","arg":2}));
              // Adding the connections to wsConnections
              wsConnections.add(conn);

              // Two players, we can start
              // Sending both players data to players
              this._start();
          }
          // end getNumber command
          }
          break;
        case "move":
          int cell = dataFromClient["arg"]["cell"];
          int player = dataFromClient["arg"]["player"];
          grid[cell] = player;

          // Sending move to players
          _sendToAll({"cmd":"move","arg":{
              "cell": cell,
              "player": player
              }
            });

          moves++;
          // Checking if someone won.
          // "5" is the minimum number of moves to win
          if(moves > 4){
            List<int> isWinningPair = this._hasWon(player, cell);
            if(!isWinningPair.isEmpty){
              // We have a winner, let's get the game ended
              hasWinner = true;
              List<int> triple = [cell];
              isWinningPair.forEach((singleCell){
                triple.add(singleCell);
              });

              switch(player){
                case 1:
                  playerOne.points++;
                  break;
                case 2:
                  playerTwo.points++;
                  break;
              }

              _sendToAll({"cmd":"end", "arg":{
                  "winner": player,
                  "triple" : triple
                }});
              _countdown();
            }
          }
          if(moves == 9 && !hasWinner) {
            // Reached the maximum number of moves and still no winner
            _sendToAll({"cmd":"end", "arg":"drawn"});
            _countdown();
          }

          // end move command
          break;
      }
    }

    conn.listen(onMessage,
      onDone: (() {
        // Connection lost, removing
        if(wsConnections.contains(conn)) {
          wsConnections.remove(conn);
          _reset();
        }
      }),
      onError: (e) {
        // Connection lost, removing
        wsConnections.remove(conn);
        _reset();
      }
    );
  }

  void _countdown() {
    // Letting players know that a new game is about to start
    int count = 0;
    // Waits two seconds before launching the countdown
    new Timer(new Duration(seconds:2), (){
      new Timer.periodic(new Duration(seconds:1), (Timer timer){
        if (count==3) {
          timer.cancel();
          _start();
        }
        _sendToAll({
          "cmd":"message",
          "arg":"Starting a new game in ${3 - count} seconds..."
        });
        count++;
      });

    });
  }

  void _reset() {
    // Resetting local data
    _sendToAll({"cmd":"reset"});
    playerOne = null;
    playerTwo = null;
    wsConnections.clear();
  }

  void _sendToAll(Map message){
    // Sending a message to players
    wsConnections.forEach((WebSocket conn){
      conn.add(JSON.stringify(message));
    });
  }

  void _start() {
    // Initial values:
    grid = [0,0,0,0,0,0,0,0,0];
    moves=0;
    hasWinner = false;

    // Switch turns
    if(playerOne.myTurn == null || playerTwo.myTurn == null){
      playerOne.myTurn = true;
      playerTwo.myTurn = false;
    } else {
      playerOne.myTurn=playerTwo.myTurn;
      playerTwo.myTurn=!playerOne.myTurn;
    }

    _sendToAll({"cmd":"start","arg":{
      "1":playerOne._serialize(),
      "2":playerTwo._serialize()
    }});
  }
  List<int> _hasWon(int player, int cell){
    switch(cell){
      case 0:
        List<List<int>> pairs = [[1,2],[3,6],[4,8]];
        return _checkPairs(pairs, player);
        break;
      case 1:
        List<List<int>> pairs = [[4,7],[0,2]];
        return _checkPairs(pairs, player);
        break;
      case 2:
        List<List<int>> pairs = [[0,1],[4,6],[5,8]];
        return _checkPairs(pairs, player);
        break;
      case 3:
        List<List<int>> pairs = [[0,6],[4,5]];
        return _checkPairs(pairs, player);
        break;
      case 4:
        List<List<int>> pairs = [[0,8],[1,7],[2,6],[3,5]];
        return _checkPairs(pairs, player);
        break;
      case 5:
        List<List<int>> pairs = [[2,8],[3,4]];
        return _checkPairs(pairs, player);
        break;
      case 6:
        List<List<int>> pairs = [[0,3],[2,4],[7,8]];
        return _checkPairs(pairs, player);
        break;
      case 7:
        List<List<int>> pairs = [[1,4],[6,8]];
        return _checkPairs(pairs, player);
        break;
      case 8:
        List<List<int>> pairs = [[0,4],[2,5],[6,7]];
        return _checkPairs(pairs, player);
        break;
    }
    return [];
  }

  List<int> _checkPairs(List<List<int>> pairs, int player){
    for (List<int> pair in pairs){
      if(grid[pair[0]]==player && grid[pair[1]]==player) {
        return pair;
      }
    }
    return [];
  }
}