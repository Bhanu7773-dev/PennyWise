import 'package:flutter/material.dart';

/// A widget that displays a number with a smooth scrolling animation
class AnimatedDigitText extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedDigitText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedDigitText> createState() => _AnimatedDigitTextState();
}

class _AnimatedDigitTextState extends State<AnimatedDigitText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _oldValue = '';
  String _currentValue = '';
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _oldValue = widget.value;
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(AnimatedDigitText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = _currentValue;
      _currentValue = widget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? const TextStyle(fontSize: 34);
    
    // Measure dimensions
    final textPainter = TextPainter(
      text: TextSpan(text: '0', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final digitWidth = textPainter.width + 2;
    final digitHeight = textPainter.height;

    // First build - no animation
    if (_isFirstBuild) {
      _isFirstBuild = false;
      return _buildStaticText(_currentValue, textStyle, digitWidth, digitHeight);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        
        // Animation complete - show static
        if (progress >= 1.0 || !_controller.isAnimating) {
          return _buildStaticText(_currentValue, textStyle, digitWidth, digitHeight);
        }
        
        // During animation
        return _buildAnimatedText(
          _oldValue, 
          _currentValue, 
          progress, 
          textStyle, 
          digitWidth, 
          digitHeight,
        );
      },
    );
  }

  Widget _buildStaticText(
    String value, 
    TextStyle style, 
    double digitWidth, 
    double digitHeight,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: value.split('').map((char) {
        final isDigit = RegExp(r'[0-9]').hasMatch(char);
        
        if (isDigit) {
          return SizedBox(
            width: digitWidth,
            height: digitHeight,
            child: Center(child: Text(char, style: style)),
          );
        } else {
          final charPainter = TextPainter(
            text: TextSpan(text: char, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          
          return SizedBox(
            width: charPainter.width + 1,
            height: digitHeight,
            child: Center(child: Text(char, style: style)),
          );
        }
      }).toList(),
    );
  }

  Widget _buildAnimatedText(
    String oldValue,
    String newValue,
    double progress,
    TextStyle style,
    double digitWidth,
    double digitHeight,
  ) {
    // Extract only digits from both values
    final oldDigits = oldValue.replaceAll(RegExp(r'[^0-9]'), '');
    final newDigits = newValue.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Pad to same length
    final maxDigitLen = oldDigits.length > newDigits.length 
        ? oldDigits.length 
        : newDigits.length;
    final paddedOldDigits = oldDigits.padLeft(maxDigitLen, '0');
    
    // Build the new value with animations
    int digitIndex = 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: newValue.split('').map((char) {
        final isDigit = RegExp(r'[0-9]').hasMatch(char);
        
        if (isDigit) {
          // Get corresponding old and new digit
          final newDigitPosition = newDigits.length - 1 - (newDigits.length - 1 - digitIndex);
          final oldDigitIdx = paddedOldDigits.length - (newDigits.length - newDigitPosition);
          
          final newDigit = int.parse(char);
          final oldDigit = oldDigitIdx >= 0 && oldDigitIdx < paddedOldDigits.length
              ? int.parse(paddedOldDigits[oldDigitIdx])
              : 0;
          
          digitIndex++;
          
          // Animate if digits are different
          if (oldDigit != newDigit) {
            return _buildAnimatedDigit(
              oldDigit, 
              newDigit, 
              progress, 
              style, 
              digitWidth, 
              digitHeight,
            );
          } else {
            return SizedBox(
              width: digitWidth,
              height: digitHeight,
              child: Center(child: Text(char, style: style)),
            );
          }
        } else {
          final charPainter = TextPainter(
            text: TextSpan(text: char, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          
          return SizedBox(
            width: charPainter.width + 1,
            height: digitHeight,
            child: Center(child: Text(char, style: style)),
          );
        }
      }).toList(),
    );
  }

  Widget _buildAnimatedDigit(
    int oldDigit,
    int newDigit,
    double progress,
    TextStyle style,
    double digitWidth,
    double digitHeight,
  ) {
    return SizedBox(
      width: digitWidth,
      height: digitHeight,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            // Old digit sliding up and out
            Transform.translate(
              offset: Offset(0, -digitHeight * progress),
              child: Opacity(
                opacity: 1 - progress,
                child: Text(oldDigit.toString(), style: style),
              ),
            ),
            // New digit sliding up from below
            Transform.translate(
              offset: Offset(0, digitHeight * (1 - progress)),
              child: Opacity(
                opacity: progress,
                child: Text(newDigit.toString(), style: style),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
