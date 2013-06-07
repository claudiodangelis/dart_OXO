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

// These are all the DOM elements that we have to handle

DivElement loginPanel = query("#loginPanel");
DivElement gamePanel = query("#gamePanel");
InputElement inputNickname = query("#inputNickname");
ButtonElement loginBtn = query("#loginBtn");
CanvasElement canvasGame = query("#canvas");
CanvasElement canvasLogo = query("#logo");
CanvasRenderingContext2D contextLogo = canvasLogo.context2D;
CanvasRenderingContext2D contextGame = canvasGame.context2D;
ParagraphElement status = query("#status");
ParagraphElement meStats = query("#meStats");
ParagraphElement opponentStats = query("#opponentStats");

void drawGrid() {
  // A blank grid is drawn

  // Inner borders
  contextGame.strokeStyle = "#999";
  contextGame.lineWidth = 1;
  contextGame.beginPath();

  drawLine(contextGame, 200, 0, 200, 600);
  drawLine(contextGame, 400, 0, 400, 600);
  drawLine(contextGame, 0, 200, 600, 200);
  drawLine(contextGame, 0, 400, 600, 400);

  contextGame.closePath();
  contextGame.stroke();
}

void drawLine(CanvasRenderingContext2D context, fromX, fromY, toX, toY) {
  // Helper function, it draws a line
  context.moveTo(fromX,fromY);
  context.lineTo(toX, toY);
}

void drawCell(CanvasRenderingContext2D context, int cell, int number) {
  // This draws an "O" if player's number is 1, otherwise a "X"
  int x = cell % 3 * 200;
  int y = cell ~/ 3 * 200;

  // Player 1 has O
  // Player 2 has X

  switch(number){
    case 1:
      drawO(context, x, y);
      break;
    case 2:
      drawX(context, x, y);
      break;
  }
}

void drawO(CanvasRenderingContext2D context, int x, int y) {

  // Draws an "O"
  int circleX = x + 100;
  int circleY = y + 100;

  // Line style
  context.strokeStyle = "#0096D2";
  context.lineWidth = 15;

  // Begin drawing
  context.beginPath();
  context.moveTo(circleX + 85, circleY);
  context.arc(circleX,circleY,85, 0, 2*Math.PI);
  context.closePath();
  context.stroke();

}
void drawX(CanvasRenderingContext2D context, int x, int y) {

  //Draws a "X"
  var lineX = x;
  var lineY = y;

  // Line style
  context.strokeStyle = "#00D8C5";
  context.lineWidth = 15;

  context.beginPath();
  drawLine(context, lineX + 20, lineY + 20,  lineX + 180, lineY + 180);
  drawLine(context, lineX + 20, lineY + 180, lineX + 180, lineY + 20);
  context.closePath();
  context.stroke();

}

void highlightCells(List<int> triple, int number) {

  // Fills background of the 3 "winning" cells
  triple.forEach((int cell){

    int x = cell % 3 * 200;
    int y = cell ~/ 3 * 200;

    contextGame.beginPath();
    contextGame.rect(x, y, 200, 200);
    contextGame.fillStyle = "#f8f8ff";
    contextGame.fill();

    switch(number){
      case 1:
        drawO(contextGame, x, y);
        break;
      case 2:
        drawX(contextGame, x, y);
        break;
    }
  });
  drawGrid();
}

void drawLogo() {
  // Draws the logo
  drawO(contextLogo, 0,0);
  drawX(contextLogo, 200,0);
  drawO(contextLogo, 400,0);
}


void updateStatus(String message) {
  // Updates the status box
  status.text = message;
}

void hideLogin() {
  // Hides the login panel and shows the game panel

  loginPanel.style.visibility = "hidden";
  loginPanel.style.display="none";

  gamePanel.style.visibility = "visible";
  gamePanel.style.display = "block";

}

void showLogin() {
  // Hides the game panel and shows the login panel

  loginPanel.style.visibility = "visible";
  loginPanel.style.display = "block";

  gamePanel.style.visibility = "hidden";
  gamePanel.style.display = "none";
}

void updateGameStats(Game game) {

  // Updates game statistics
  meStats.innerHtml = "${symbol(game.me)} ${game.me.nickname}: ${game.me.points}";
  opponentStats.innerHtml =
      "${symbol(game.opponent)} ${game.opponent.nickname}: ${game.opponent.points}";
}


Future queue(callback()) {
  // Waits a little bit before running the callback
  return new Future.delayed(new Duration(milliseconds:50), callback);
}

String symbol(Player player){
  // Puts O/X characters accordingly to the player's number
  if (player.number==1) {
    return "<span class='symbol o'>O</span>";
  } else {
    return "<span class='symbol x'>X</span>";
  }
}

void accessDenied() {
  // No room for another player, it shows an error
  ParagraphElement error = new ParagraphElement();
  error.style
    ..color = "#a52a2a"
    ..marginLeft = "auto"
    ..marginRight = "auto"
    ..width = "600px"
    ..backgroundColor = "#FFBABA"
    ..marginTop = "25px"
    ..borderRadius = "15px"
    ..padding = "20px";

  error.text = "Oops, there are already two players in, please try again later";

  loginPanel.append(error);

  new Timer(new Duration(seconds:5),(){
    error.remove();
  });

}

int getCellFromCoordinates(int x, int y) {
  // canvas size 600x600, cell size 200x200
  // convert (x,y) to cell: y*3 + x
  return ((y ~/ 200) * 3) + (x ~/ 200);
}
