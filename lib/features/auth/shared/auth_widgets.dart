import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Shared Auth Widgets ───────────────────────────────────────────────────────
// Đặt tại đây để tất cả auth screens có thể reuse mà không bị circular import

const _primaryRed = Color(0xFF7B0323);

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? errorText;
  final Function(String)? onChanged;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  final TextInputType keyboardType;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.errorText,
    this.onChanged,
    this.isPassword = false,
    this.isVisible = false,
    this.onToggleVisibility,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: !enabled
                ? const Color(0xFFF0F0F0)
                : hasError
                    ? const Color(0xFFFFEEEE)
                    : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            onChanged: onChanged,
            keyboardType: keyboardType,
            enabled: enabled,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFFBBBBBB),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: hasError ? Colors.redAccent : const Color(0xFFAAAAAA),
                size: 20,
              ),
              suffixIcon: isPassword && enabled
                  ? IconButton(
                      icon: Icon(
                        isVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFFAAAAAA),
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 5),
            child: Text(
              errorText!,
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [const Color(0xFF7B0323), const Color(0xFFAA0033)]
                : [Colors.grey.shade300, Colors.grey.shade300],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B0323).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

/// Decorative floating blob background — dùng chung cho tất cả auth screens
class AuthBackground extends StatelessWidget {
  final Animation<double> floatAnim;
  final Size size;
  final List<BlobConfig> blobs;

  const AuthBackground({
    super.key,
    required this.floatAnim,
    required this.size,
    required this.blobs,
  });

  factory AuthBackground.standard({
    required Animation<double> floatAnim,
    required Size size,
  }) {
    return AuthBackground(
      floatAnim: floatAnim,
      size: size,
      blobs: [
        BlobConfig(
          top: -80,
          right: -80,
          width: 280,
          height: 280,
          alpha: 0.18,
          dxFactor: 0,
          dyFactor: 0.5,
        ),
        BlobConfig(
          bottom: 150,
          left: -60,
          width: 200,
          height: 200,
          alpha: 0.10,
          dxFactor: 0,
          dyFactor: -0.7,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: blobs.map((b) => _buildBlob(b)).toList());
  }

  Widget _buildBlob(BlobConfig b) {
    Widget blob = AnimatedBuilder(
      animation: floatAnim,
      builder: (_, _) => Transform.translate(
        offset: Offset(
          floatAnim.value * b.dxFactor,
          floatAnim.value * b.dyFactor,
        ),
        child: Container(
          width: b.width,
          height: b.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _primaryRed.withValues(alpha: b.alpha),
                _primaryRed.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );

    return Positioned(
      top: b.top,
      bottom: b.bottom,
      left: b.left,
      right: b.right,
      child: blob,
    );
  }
}

class BlobConfig {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double width;
  final double height;
  final double alpha;
  final double dxFactor;
  final double dyFactor;

  const BlobConfig({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.width,
    required this.height,
    required this.alpha,
    this.dxFactor = 0,
    required this.dyFactor,
  });
}

/// Logo badge dùng chung
class AuthLogoBadge extends StatelessWidget {
  final IconData icon;

  const AuthLogoBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _primaryRed,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
