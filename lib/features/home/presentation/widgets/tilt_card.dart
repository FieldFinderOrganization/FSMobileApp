import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double maxTilt;

  const TiltCard({
    super.key,
    required this.child,
    this.onTap,
    this.maxTilt = 0.04,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Offset _localPosition = Offset.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(TapDownDetails d) {
    _localPosition = d.localPosition;
    _ctrl.forward();
  }

  void _release() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onDown,
      onTapCancel: _release,
      onTapUp: (_) {
        _release();
        widget.onTap?.call();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              final t = Curves.easeOutCubic.transform(_ctrl.value);
              double rx = 0, ry = 0;
              if (_size.width > 0 && _size.height > 0) {
                final dx = (_localPosition.dx / _size.width) * 2 - 1;
                final dy = (_localPosition.dy / _size.height) * 2 - 1;
                ry = -dx * widget.maxTilt * t;
                rx = dy * widget.maxTilt * t;
              }
              final scale = 1 - 0.02 * t;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(rx)
                  ..rotateY(ry)
                  ..scale(scale, scale),
                child: child,
              );
            },
            child: widget.child,
          );
        },
      ),
    );
  }
}
