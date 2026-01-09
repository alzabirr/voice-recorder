import 'package:flutter/cupertino.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;

  const WaveformWidget({
    super.key,
    required this.amplitudes,
    this.color = CupertinoColors.systemRed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: WaveformPainter(amplitudes: amplitudes, color: color),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;
    
    // iOS Style: Latest bar is at the center, scrolling to the LEFT.
    const barWidth = 2.0;
    const gap = 4.0;
    const barTotalWidth = barWidth + gap;

    // 3. Paint for the bars (Gradient & Glow)
    final bool isRed = color.value == CupertinoColors.systemRed.value || color.value == const Color(0xFFFF3B30).value;
    
    final barGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isRed ? [
        const Color(0xFFFF5252), // Lighter red top
        const Color(0xFFFF3B30), // Classic red center
        const Color(0xFFFF5252), // Lighter red bottom
      ] : [
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.8),
      ],
    );

    final paint = Paint()
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    // Paint for the "Past" bars
    final pastPaint = Paint()
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    // Paint for the center indicator line (Always Dark Red)
    final centerLinePaint = Paint()
      ..color = const Color(0xFFB71C1C).withValues(alpha: 0.8)
      ..strokeWidth = 1.5;

    // Draw the active/past bars starting from the center and going left
    final count = amplitudes.length;
    final maxLeftBars = (centerX / barTotalWidth).floor();

    for (int i = 0; i < count && i < maxLeftBars; i++) {
        final amplitude = amplitudes[count - 1 - i];
        
        // Balanced amplitude normalization
        // Range: -60dB (silence) to 0dB (max)
        double normalized = (amplitude + 60) / 60; 
        normalized = normalized.clamp(0.0, 1.0);
        
        // Cubic curve to suppress background noise (noise gate effect)
        // Low amplitude sounds will be significantly reduced
        double curved = normalized * normalized * normalized; 
        
        // Balanced minimum height
        double heightFactor = 0.02 + 0.98 * curved;
        final height = heightFactor * size.height;

        final x = centerX - (i * barTotalWidth);
        final rect = Rect.fromLTRB(x - barWidth/2, centerY - height/2, x + barWidth/2, centerY + height/2);
        
        if (i == 0) {
          // Active bar with full gradient
          paint.shader = barGradient.createShader(rect);
          canvas.drawLine(Offset(x, centerY - height / 2), Offset(x, centerY + height / 2), paint);
        } else {
          // Past bars: consistent opacity, only fade at the very edge (last 20%)
          final fadeProgress = i / maxLeftBars;
          double opacity = 0.9; // Higher base opacity for better visibility
          
          if (fadeProgress > 0.8) {
             final edgeFade = (1.0 - fadeProgress) / 0.2; 
             opacity *= edgeFade;
          }
          
          pastPaint.color = color.withValues(alpha: opacity);
          canvas.drawLine(Offset(x, centerY - height / 2), Offset(x, centerY + height / 2), pastPaint);
        }
    }

    // 4. Draw the center playhead line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      centerLinePaint,
    );

    // 5. Draw top and bottom boundary lines (Subtle white rails)
    final railPaint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), railPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), railPaint);
  }

  double _easeInQuad(double t) {
    return t * t;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; 
  }
}
