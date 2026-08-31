import 'dart:ui' as ui;
import 'dart:math' show sqrt, max;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ThemeReveal extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;
  final ui.Image? previousImage;
  final Offset center;

  const ThemeReveal({
    super.key,
    required this.child,
    required this.animation,
    this.previousImage,
    this.center = Offset.zero,
  });

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal> {
  @override
  Widget build(BuildContext context) {
    if (widget.previousImage == null || widget.animation.value == 1.0) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: The "old" screenshot
        CustomPaint(
          painter: _ImagePainter(widget.previousImage!),
          size: Size.infinite,
        ),
        // Foreground: The "new" theme content, clipped
        ClipPath(
          clipper: _CircularRevealClipper(
            center: widget.center,
            fraction: widget.animation.value,
          ),
          child: widget.child,
        ),
      ],
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double fraction;

  _CircularRevealClipper({required this.center, required this.fraction});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    // Calculate max radius to cover the screen from the center point
    final double maxRadius = calcMaxRadius(size, center);

    path.addOval(Rect.fromCircle(center: center, radius: maxRadius * fraction));
    return path;
  }

  static double calcMaxRadius(Size size, Offset center) {
    final double w = max(center.dx, size.width - center.dx);
    final double h = max(center.dy, size.height - center.dy);
    return sqrt(w * w + h * h);
  }

  @override
  bool shouldReclip(covariant _CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}

/// Controller to wrap the app/screen and manage the state
class ThemeRevealController extends StatefulWidget {
  final Widget child;

  const ThemeRevealController({super.key, required this.child});

  static ThemeRevealControllerState of(BuildContext context) {
    return context.findAncestorStateOfType<ThemeRevealControllerState>()!;
  }

  @override
  State<ThemeRevealController> createState() => ThemeRevealControllerState();
}

class ThemeRevealControllerState extends State<ThemeRevealController>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _lastScreenshot;
  Offset _center = Offset.zero;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> changeTheme({
    required VoidCallback setTheme,
    required Offset center,
  }) async {
    // 1. Capture screenshot of current state
    final boundary =
        _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      // Must ignore the pixel ratio for the simple painter or handle scaling.
      // Usually matching the logical size is easiest if we draw it 1:1.
      // But findRenderObject usually acts in physical pixels.
      // Let's rely on standard capture.
      final image = await boundary.toImage(
        pixelRatio: View.of(context).devicePixelRatio,
      );
      setState(() {
        _lastScreenshot = image;
        _center = center;
      });
    }

    // 2. Update the theme (callback to provider)
    setTheme();

    // 3. Reset animation and play
    _controller.value = 0.0;
    _controller.forward().then((_) {
      setState(() {
        _lastScreenshot = null; // Cleanup memory
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ThemeReveal(
            animation: _controller,
            previousImage: _lastScreenshot,
            center: _center,
            child: widget.child,
          );
        },
      ),
    );
  }
}
