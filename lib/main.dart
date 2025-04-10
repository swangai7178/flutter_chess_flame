import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

void main() {
  runApp(GameWidget(game: ChessGame()));
}



class ChessGame extends FlameGame with TapDetector {
  late Sprite whiteKing;
  final int boardSize = 8;
  Vector2? selectedPiecePosition; // To store the selected piece position
  Vector2 kingPosition = Vector2(4, 7); // Initial position of the king (e1)
  String? errorMessage; // To store error messages

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    whiteKing = await loadSprite('whiteking.png');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final squareSize = (size.x < size.y ? size.x : size.y) / boardSize;
    final offsetX = (size.x - squareSize * boardSize) / 2;
    final offsetY = (size.y - squareSize * boardSize) / 2;

    final paintWhite = Paint()..color = const Color(0xFFF0D9B5);
    final paintBlack = Paint()..color = const Color(0xFFB58863);

    // Draw board
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        final isWhite = (row + col) % 2 == 0;
        final paint = isWhite ? paintWhite : paintBlack;
        canvas.drawRect(
          Rect.fromLTWH(
            offsetX + col * squareSize,
            offsetY + row * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }

    // Highlight selected piece
    if (selectedPiecePosition != null) {
      final highlightPaint = Paint()..color = Colors.yellow.withOpacity(0.5);
      canvas.drawRect(
        Rect.fromLTWH(
          offsetX + selectedPiecePosition!.x * squareSize,
          offsetY + selectedPiecePosition!.y * squareSize,
          squareSize,
          squareSize,
        ),
        highlightPaint,
      );
    }

    // Draw white king at its current position
    final kingSize = Vector2(squareSize, squareSize);
    final kingPos = Vector2(
      offsetX + kingPosition.x * squareSize,
      offsetY + kingPosition.y * squareSize,
    );
    whiteKing.render(canvas, position: kingPos, size: kingSize);

    // Render error message if it exists
    if (errorMessage != null) {
      final textStyle = TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
      textStyle.render(canvas, errorMessage!, Vector2(10, size.y - 30));
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    final squareSize = (size.x < size.y ? size.x : size.y) / boardSize;
    final offsetX = (size.x - squareSize * boardSize) / 2;
    final offsetY = (size.y - squareSize * boardSize) / 2;

    final pos = info.eventPosition.global;
    final col = ((pos.x - offsetX) / squareSize).floor();
    final row = ((pos.y - offsetY) / squareSize).floor();

    if (col < 0 || col >= boardSize || row < 0 || row >= boardSize) {
      errorMessage = 'Tapped outside the board';
      print('Tapped outside the board');
      return;
    }

    final tappedPosition = Vector2(col.toDouble(), row.toDouble());

    // If no piece is selected, select the piece
    if (selectedPiecePosition == null) {
      if (tappedPosition == kingPosition) {
        selectedPiecePosition = kingPosition;
        errorMessage = null; // Clear error message
        print('Selected king at square: $row, $col');
      } else {
        errorMessage = 'No piece at the selected square';
        print('No piece at the selected square');
      }
    } else {
      // If a piece is already selected, attempt to move it
      if (selectedPiecePosition == kingPosition) {
        final dx = (col - kingPosition.x).abs();
        final dy = (row - kingPosition.y).abs();

        // Check if the move is valid for a king (one square in any direction)
        if ((dx <= 1 && dy <= 1) && !(dx == 0 && dy == 0)) {
          // Update king's position
          kingPosition = tappedPosition;
          selectedPiecePosition = null; // Deselect the piece
          errorMessage = null; // Clear error message
          print('Moved king to square: $row, $col');
        } else {
          errorMessage = 'Invalid move for a king';
          print('Invalid move for a king');
        }
      }
    }
  }
}
