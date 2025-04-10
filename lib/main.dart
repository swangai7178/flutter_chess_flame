import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

void main() {
  runApp(GameWidget(game: ChessGame()));
}



class ChessGame extends FlameGame with TapDetector {
  late Sprite whiteKing, whiteQueen, whiteRook, whiteBishop, whiteKnight, whitePawn;
  final int boardSize = 8;
  Vector2? selectedPiecePosition; // To store the selected piece position
  Map<Vector2, String> pieces = {}; // To store pieces and their positions
  String? errorMessage; // To store error messages

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    whiteKing = await loadSprite('whiteking.png');
    whiteQueen = await loadSprite('whitequeen.png');
    whiteRook = await loadSprite('whiterook.png');
    whiteBishop = await loadSprite('whitebishop.png');
    whiteKnight = await loadSprite('whiteknight.png');
    whitePawn = await loadSprite('whitepawn.png');

    // Initialize pieces
    pieces[Vector2(4, 7)] = 'king'; // e1
    pieces[Vector2(3, 7)] = 'queen'; // d1
    pieces[Vector2(0, 7)] = 'rook'; // a1
    pieces[Vector2(7, 7)] = 'rook'; // h1
    pieces[Vector2(2, 7)] = 'bishop'; // c1
    pieces[Vector2(5, 7)] = 'bishop'; // f1
    pieces[Vector2(1, 7)] = 'knight'; // b1
    pieces[Vector2(6, 7)] = 'knight'; // g1
    for (int i = 0; i < boardSize; i++) {
      pieces[Vector2(i.toDouble(), 6)] = 'pawn'; // pawns on row 6
    }
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

    // Draw pieces
    final pieceSprites = {
      'king': whiteKing,
      'queen': whiteQueen,
      'rook': whiteRook,
      'bishop': whiteBishop,
      'knight': whiteKnight,
      'pawn': whitePawn,
    };

    for (final entry in pieces.entries) {
      final position = entry.key;
      final piece = entry.value;
      final sprite = pieceSprites[piece];
      if (sprite != null) {
        final pieceSize = Vector2(squareSize, squareSize);
        final piecePos = Vector2(
          offsetX + position.x * squareSize,
          offsetY + position.y * squareSize,
        );
        sprite.render(canvas, position: piecePos, size: pieceSize);
      }
    }

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
      if (pieces.containsKey(tappedPosition)) {
        selectedPiecePosition = tappedPosition;
        errorMessage = null; // Clear error message
        print('Selected piece at square: $row, $col');
      } else {
        errorMessage = 'No piece at the selected square';
        print('No piece at the selected square');
      }
    } else {
      // If a piece is already selected, attempt to move it
      final selectedPiece = pieces[selectedPiecePosition];
      if (selectedPiece != null) {
        final dx = (col - selectedPiecePosition!.x).abs();
        final dy = (row - selectedPiecePosition!.y).abs();

        bool isValidMove = false;

        switch (selectedPiece) {
          case 'king':
            isValidMove = (dx <= 1 && dy <= 1) && !(dx == 0 && dy == 0);
            break;
          case 'queen':
            isValidMove = (dx == dy || dx == 0 || dy == 0);
            break;
          case 'rook':
            isValidMove = (dx == 0 || dy == 0);
            break;
          case 'bishop':
            isValidMove = (dx == dy);
            break;
          case 'knight':
            isValidMove = (dx == 2 && dy == 1) || (dx == 1 && dy == 2);
            break;
          case 'pawn':
            isValidMove = (dy == 1 && dx == 0 && row < selectedPiecePosition!.y);
            break;
        }

        if (isValidMove) {
          // Update piece's position
          pieces.remove(selectedPiecePosition);
          pieces[tappedPosition] = selectedPiece;
          selectedPiecePosition = null; // Deselect the piece
          errorMessage = null; // Clear error message
          print('Moved $selectedPiece to square: $row, $col');
        } else {
          errorMessage = 'Invalid move for $selectedPiece';
          print('Invalid move for $selectedPiece');
        }
      }
    }
  }
}
