import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

double scale = 0.8;

class DrawingPage extends StatefulWidget {
  final client;
  final String name;
  final String? ip;

  DrawingPage(
      {Key? key, required this.client, required this.name, required this.ip})
      : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class ColoredPoint {
  final Offset point;
  final Color color;

  ColoredPoint({required this.point, required this.color});
}

class _DrawingPageState extends State<DrawingPage> {
  List<ColoredPoint> points = [];
  bool isEraserMode = false;
  late Size size;
  Color backgroundColor = Colors.white; // Background color
  Color selectedColor = Colors.black; // Default stroke color

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
                  points.add(
                      ColoredPoint(point: localPosition, color: selectedColor));
                }
              });
            },
            onPanEnd: (details) {
              points.add(
                  ColoredPoint(point: Offset(-1, -1), color: selectedColor));
            },
            child: CustomPaint(
              painter: DrawingPainter(
                points: points,
                isEraserMode: isEraserMode,
                size: size,
                isDarkMode: darkmode,
                backgroundColor: backgroundColor,
              ),
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
            mini: true,
            child: Icon(Icons.clear),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "undobtn",
            onPressed: () {
              setState(() {
                if (points.isNotEmpty) {
                  int removeCount = points.length >= 40 ? 40 : points.length;
                  points.removeRange(
                      points.length - removeCount, points.length);
                }
              });
            },
            mini: true,
            child: Icon(Icons.undo),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "colorbtn",
            onPressed: () {
              _showColorPicker(isBackground: false);
            },
            mini: true,
            child: Icon(Icons.color_lens),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "backgroundbtn",
            onPressed: () {
              _showColorPicker(isBackground: true);
            },
            mini: true,
            child: Icon(Icons.format_paint),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "sendbtn",
            onPressed: () {
              if (points.isNotEmpty) {
                String svgData = generateSvgData(size.width, size.height);
                sendSVGData(svgData, widget.name, widget.ip);
              } else {
                print('Points are empty. No SVG data to send.');
              }
            },
            mini: true,
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
        StringBuffer("<svg width='$width' height='$height'>");
    svgData.write(
        "<rect width='$width' height='$height' fill='${colorToHex(backgroundColor)}' />");

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].point != Offset(-1, -1) &&
          points[i + 1].point != Offset(-1, -1)) {
        String colorHex = colorToHex(points[i].color);
        svgData.write(
            "<line x1='${points[i].point.dx}' y1='${points[i].point.dy}' x2='${points[i + 1].point.dx}' y2='${points[i + 1].point.dy}' stroke='$colorHex' stroke-width='2'/>");
      }
    }
    svgData.write('</svg>');
    return svgData.toString();
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  void sendSVGData(String svgData, String name, String? ip) async {
    points.clear();

    await widget.client
        .write({'Username': widget.name, 'Status': "SVG", 'IP': widget.ip, "SVG-data": svgData});
  }

  void _showColorPicker({required bool isBackground}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              isBackground ? "Wähle Hintergrundfarbe" : "Wähle Stiftfarbe"),
          content: SingleChildScrollView(
            child: MaterialColorPicker(
              circleSize: 50.0,
              spacing: 10.0,
              elevation: 10.0,
              allowShades: true,
              onColorChange: (color) {
                setState(() {
                  if (isBackground) {
                    backgroundColor = color;
                  } else {
                    selectedColor = color;
                  }
                });
              },
              selectedColor: isBackground ? backgroundColor : selectedColor,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<ColoredPoint> points;
  final bool isEraserMode;
  final Size size;
  final bool isDarkMode;
  final Color backgroundColor;

  DrawingPainter({
    required this.points,
    required this.isEraserMode,
    required this.size,
    required this.isDarkMode,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size _) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    Paint backgroundPaint = Paint()..color = backgroundColor;

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

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].point != Offset(-1, -1) &&
          points[i + 1].point != Offset(-1, -1)) {
        paint.color = points[i].color; // Set the color for each segment
        canvas.drawLine(points[i].point, points[i + 1].point, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
