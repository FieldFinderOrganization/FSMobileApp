import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/pitch_entity.dart';
import '../pages/pitch_detail_screen.dart';

class PitchCard extends StatefulWidget {
  final PitchEntity pitch;

  const PitchCard({super.key, required this.pitch});

  @override
  State<PitchCard> createState() => _PitchCardState();
}

class _PitchCardState extends State<PitchCard>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _snapFromX = 0.0;
  double _snapFromY = 0.0;
  static const double _maxTilt = 0.14; // ~8 degrees

  late final AnimationController _snapBack;
  late final Animation<double> _snapCurve;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _snapCurve = CurvedAnimation(parent: _snapBack, curve: Curves.easeOut);
    _snapCurve.addListener(_onSnapTick);
  }

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    setState(() {
      _tiltX = lerpDouble(_snapFromX, 0.0, _snapCurve.value)!;
      _tiltY = lerpDouble(_snapFromY, 0.0, _snapCurve.value)!;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final cardWidth = MediaQuery.of(context).size.width * 0.82;
    final dx = details.delta.dx / cardWidth * _maxTilt * 8;
    final dy = details.delta.dy / 240.0 * _maxTilt * 8;
    setState(() {
      _tiltX = (_tiltX + dx).clamp(-_maxTilt, _maxTilt);
      _tiltY = (_tiltY + dy).clamp(-_maxTilt, _maxTilt);
    });
  }

  void _snapToCenter() {
    _snapFromX = _tiltX;
    _snapFromY = _tiltY;
    _snapBack.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PitchDetailScreen(pitch: widget.pitch),
        ),
      ),
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _snapToCenter(),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tiltY)
          ..rotateY(_tiltX),
        child: RepaintBoundary(child: _buildCard()),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient fallback
            widget.pitch.primaryImage.isNotEmpty
                ? Image.network(
                    widget.pitch.primaryImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildGradientFallback(),
                  )
                : _buildGradientFallback(),
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
            // Tilt shimmer — static diagonal highlight, opacity shifts with tilt
            Positioned.fill(
              child: Opacity(
                opacity: ((_tiltX.abs() + _tiltY.abs()) / (_maxTilt * 2))
                    .clamp(0.0, 1.0) * 0.18,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.pitch.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.pitch.displayType} · ${widget.pitch.environment}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  IntrinsicWidth(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.pitch.price.toStringAsFixed(0)}k/h',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 48, color: Colors.white24),
      ),
    );
  }
}
