import 'package:flutter/material.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

double scale = 0.8;

class DrawingPage extends StatefulWidget {
  final client;
  final String name;
  final String? ip;

  DrawingPage({Key? key, required this.client, required this.name, required this.ip})
      : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<Offset> points = [];
  bool isEraserMode = false;
  late Size size;

  @override
  Widget build(BuildContext context) {
    bool darkmode = isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Page'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                Offset localPosition = details.localPosition;
                if (_isInsideDrawingArea(localPosition, size)) {
                  points.add(localPosition);
                }
              });
            },
            onPanEnd: (details) {
              points.add(Offset(-1, -1));
            },
            child: CustomPaint(
              painter: DrawingPainter(
                  points: points,
                  isEraserMode: isEraserMode,
                  size: size,
                  isDarkMode: darkmode),
              size: Size.infinite,
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "clearbtn",
            onPressed: () {
              setState(() {
                points.clear();
              });
            },
            child: Icon(Icons.clear),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "undobtn",
            onPressed: () {
              setState(() {
                if (points.isNotEmpty) {
                  int removeCount = points.length >= 40 ? 40 : points.length;
                  for (int i = 0; i < removeCount; i++) {
                    points.removeLast();
                  }
                }
              });
            },
            child: Icon(Icons.undo),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "sendbtn",
            onPressed: () {
              if (points.isNotEmpty) {
                String svgData = generateSvgData(size.width, size.height);
                print('Sending SVG data: $svgData');
                points.clear();
                widget.client.write(
                    {"Username": widget.name, "SVG": svgData, "Status": "SVG", "IP": widget.ip});
              } else {
                print('Points are empty. No SVG data to send.');
              }
            },
            child: Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  bool _isInsideDrawingArea(Offset position, Size size) {
    double rectangleWidth = size.width * scale;
    double rectangleHeight = size.height * scale;
    double rectangleLeft = (size.width - rectangleWidth) / 2;
    double rectangleTop = (size.height - rectangleHeight) / 2;

    Rect drawingArea = Rect.fromLTWH(
        rectangleLeft, rectangleTop, rectangleWidth, rectangleHeight);
    return drawingArea.contains(position);
  }

  String generateSvgData(double width, double height) {
    StringBuffer svgData =
        StringBuffer('<svg width="$width" height="$height">');
    svgData.write('<rect width="$width" height="$height" fill="white" />');

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset(-1, -1) && points[i + 1] != Offset(-1, -1)) {
        svgData.write(
            '<line x1="${points[i].dx}" y1="${points[i].dy}" x2="${points[i + 1].dx}" y2="${points[i + 1].dy}" stroke="black" stroke-width="2"/>');
      }
    }
    svgData.write('</svg>');

    String formattedSvgData = svgData.toString().replaceAllMapped(
        RegExp(r'(\w)="([^"]*)"'), (match) => '${match[1]}="${match[2]}" ');

    return formattedSvgData;
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final bool isEraserMode;
  final Size size;
  final bool isDarkMode;

  DrawingPainter({
    required this.points,
    required this.isEraserMode,
    required this.size,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size _) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    Paint backgroundPaint = Paint()..color = Colors.white;

    double rectangleWidth = size.width * scale;
    double rectangleHeight = size.height * scale;

    double rectangleLeft = (size.width - rectangleWidth) / 2;
    double rectangleTop = (size.height - rectangleHeight) / 2;

    Size newsize = Size(rectangleWidth, rectangleHeight);

    canvas.drawRect(
      Offset(rectangleLeft, rectangleTop) & newsize,
      backgroundPaint,
    );

    Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isDarkMode) {
      borderPaint.color = Colors.grey[300]!;
    } else {
      borderPaint.color = Colors.black;
    }

    canvas.drawRect(
      Offset(rectangleLeft, rectangleTop) & newsize,
      borderPaint,
    );

    // Draw lines
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset(-1, -1) && points[i + 1] != Offset(-1, -1)) {
        paint.color = Colors.black;
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
