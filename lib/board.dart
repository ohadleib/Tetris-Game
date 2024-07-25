import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'piece.dart';
import 'tile.dart';
import 'values.dart' as values;

const int rowLength = 10;
const int colLength = 15;

List<List<values.TetrisShape?>> gameBoard = List.generate(
  colLength,
  (_) => List.generate(rowLength, (_) => null),
);

class GameBoard extends StatefulWidget {
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late Piece currentPiece; // חלק נוכחי
  int currentScore = 0; // ניקוד
  bool gameOver = false; // משתנה לסיום המשחק

  @override
  void initState() {
    // התחלת משחק מיידית
    super.initState();
    startGame();
  }

  void startGame() {
    createNewPiece(); // יצירת חלק אקראי
    gameLoop(Duration(milliseconds: 500)); // מהירות
  }

  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        clearLines(); // ניקוי שדות
        checkLanding(); // בדיקת נחיתה
        if (gameOver) {
          timer.cancel();
          showGameOverDialog(); // הצגת הודעת סיום המשחק
        }
        currentPiece.movePiece(values.Direction.down);
      });
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Game Over'), // כותרת הודעת סיום
        content: Text('Your Score is: $currentScore'),
        actions: [
          TextButton(
            onPressed: () {
              resetGame(); // איפוס משחק
              Navigator.of(context).pop();
            },
            child: Text('PLAY AGAIN'), // הפעלה מחדש
          ),
        ],
      ),
    );
  }

  bool checkCollision({values.Direction? direction}) {
    return currentPiece.position.any((pos) {
      int row = (pos / rowLength).floor();
      int col = pos % rowLength;
      if (direction == values.Direction.left) col -= 1; // תזוזה שמאלה
      if (direction == values.Direction.right) col += 1; // תזוזה ימינה
      if (direction == values.Direction.down) row += 1; // תזוזה למטה
      return row >= colLength ||
          col < 0 ||
          col >= rowLength ||
          (row >= 0 && col >= 0 && gameBoard[row][col] != null);
    });
  }

  void checkLanding() {
    if (checkCollision(direction: values.Direction.down)) {
      for (int pos in currentPiece.position) {
        int row = (pos / rowLength).floor();
        int col = pos % rowLength;
        if (row >= 0 && row < colLength && col >= 0 && col < rowLength) {
          gameBoard[row][col] = currentPiece.type; // הנחת על הלוח
        }
      }
      createNewPiece();
    }
  }

  bool isGameOver() {
    return gameBoard[0].any((cell) => cell != null);
  }

  void createNewPiece() {
    currentPiece = Piece(
        type: values.TetrisShape
            .values[Random().nextInt(values.TetrisShape.values.length)]);
    currentPiece.initiallizePiece(); // תיקון השגיאה כאן
    if (isGameOver()) gameOver = true;
  }

  void clearLines() {
    for (int row = colLength - 1; row >= 0; row--) {
      if (gameBoard[row].every((cell) => cell != null)) {
        // אם השורה מלאה
        for (int r = row; r > 0; r--)
          gameBoard[r] = List.from(gameBoard[r - 1]);
        gameBoard[0] = List.generate(rowLength, (_) => null);
        currentScore++;
      }
    }
  }

  void moveLeft() {
    if (!checkCollision(direction: values.Direction.left)) {
      setState(() => currentPiece.movePiece(values.Direction.left));
    }
    checkLanding();
  }

  void moveRight() {
    if (!checkCollision(direction: values.Direction.right)) {
      setState(() => currentPiece.movePiece(values.Direction.right));
    }
    checkLanding();
  }

  void rotatePieceBoard() {
    setState(() {
      currentPiece.rotatePiece();
      if (checkCollision(direction: values.Direction.down)) {
        currentPiece.rotatePiece();
      }
    });
    checkLanding();
  }

  void resetGame() {
    gameBoard = List.generate(
      colLength,
      (_) => List.generate(rowLength, (_) => null),
    );
    gameOver = false;
    currentScore = 0;
    createNewPiece();
    startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: rowLength * colLength,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rowLength,
                ),
                itemBuilder: (context, index) {
                  int row = (index / rowLength).floor();
                  int col = index % rowLength;
                  Color color;
                  if (currentPiece.position.contains(index)) {
                    color = currentPiece.color;
                  } else if (gameBoard[row][col] != null) {
                    color = values.tetrisShapeColors[gameBoard[row][col]]!;
                  } else {
                    color = Color.fromARGB(255, 48, 48, 48);
                  }
                  return Tile(color: color);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                "SCORE: $currentScore",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: moveLeft,
                    color: Colors.grey,
                    icon: Icon(Icons.arrow_back_ios),
                  ),
                  IconButton(
                    onPressed: rotatePieceBoard,
                    color: Colors.grey,
                    icon: Icon(Icons.rotate_right),
                  ),
                  IconButton(
                    onPressed: moveRight,
                    color: Colors.grey,
                    icon: Icon(Icons.arrow_forward_ios),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
