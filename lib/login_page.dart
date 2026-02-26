import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth               = FirebaseAuth.instance;

  String _errorMessage = '';
  bool   _isLoading    = false;
  bool   _obscurePass  = true;

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _slideAnim;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 0.75).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080809),
      body: Stack(
        children: [
          // ── Animated background grid ──────────────────────────
          Positioned.fill(child: _GridBackground(pulse: _pulseAnim)),

          // ── Radial glow top-left ──────────────────────────────
          Positioned(
            top: -180,
            left: -180,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 520,
                height: 520,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFef4444).withOpacity(_pulseAnim.value * 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom-right accent glow ──────────────────────────
          Positioned(
            bottom: -200,
            right: -200,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3b82f6).withOpacity(_pulseAnim.value * 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _fadeCtrl,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              ),
              child: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo block ──────────────────────────
                    _LogoBlock(),
                    const SizedBox(height: 40),

                    // ── Card ────────────────────────────────
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFef4444),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFef4444)
                                          .withOpacity(0.6),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'ADMIN ACCESS',
                                style: TextStyle(
                                  color: Color(0xFFf5f5f5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22c55e)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFF22c55e)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  '● SECURE',
                                  style: TextStyle(
                                    color: Color(0xFF22c55e),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Email field
                          _FieldLabel('EMAIL ADDRESS'),
                          const SizedBox(height: 6),
                          _StyledField(
                            controller: _emailController,
                            hint: 'admin@roadeye.io',
                            icon: Icons.alternate_email_rounded,
                            obscure: false,
                          ),
                          const SizedBox(height: 18),

                          // Password field
                          _FieldLabel('PASSWORD'),
                          const SizedBox(height: 6),
                          _StyledField(
                            controller: _passwordController,
                            hint: '••••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePass,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF555560),
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Error
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _ErrorBanner(message: _errorMessage),
                          ],
                          const SizedBox(height: 24),

                          // Login button
                          _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFef4444),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _PrimaryButton(
                                  label: 'SIGN IN',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: _login,
                                ),
                          const SizedBox(height: 20),

                          // Divider + sign up
                          Row(
                            children: [
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: const Color(0xFF222226))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'NEW HERE?',
                                  style: TextStyle(
                                    color: Color(0xFF444450),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: const Color(0xFF222226))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _SecondaryButton(
                            label: 'CREATE ADMIN ACCOUNT',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/signup'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Footer
                    const Text(
                      'RoadEye OS  ·  Hazard Intelligence Platform',
                      style: TextStyle(
                        color: Color(0xFF333338),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      if (_emailController.text == 'test@example.com' &&
          _passwordController.text == '123') {
        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      }
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Signup Page
// ─────────────────────────────────────────────────────────────────────────────
// NOTE: Keep this in the same file or split into signup_page.dart as needed.


// ─────────────────────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LogoBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon mark
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF0f0f11),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2a2a2e)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFef4444).withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.remove_road_rounded,
            color: Color(0xFFef4444),
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'RoadEye OS',
          style: TextStyle(
            color: Color(0xFFf5f5f5),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'HAZARD INTELLIGENCE PLATFORM',
          style: TextStyle(
            color: Color(0xFF555560),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222226)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF555560),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.obscure,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Color(0xFFe5e5e5),
        fontSize: 14,
        letterSpacing: 0.3,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF333338), fontSize: 14),
        prefixIcon:
            Icon(icon, color: const Color(0xFF444450), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0c0c0e),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF222226)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF222226)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFFef4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFef4444), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFef4444), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onPressed});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFFf87171), const Color(0xFFef4444)]
                  : [const Color(0xFFef4444), const Color(0xFFdc2626)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFef4444)
                    .withOpacity(_hovered ? 0.45 : 0.25),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _SecondaryButton(
      {required this.label, required this.onPressed});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF1e1e22)
                : const Color(0xFF17171a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF3a3a3e)
                  : const Color(0xFF222226),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: _hovered
                    ? const Color(0xFFe5e5e5)
                    : const Color(0xFF666670),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated grid background ─────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  final Animation<double> pulse;
  const _GridBackground({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => CustomPaint(
        painter: _GridPainter(opacity: pulse.value * 0.045),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double opacity;
  _GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFef4444).withOpacity(opacity)
      ..strokeWidth = 0.5;

    const spacing = 48.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Intersection dots
    final dotPaint = Paint()
      ..color = const Color(0xFFef4444).withOpacity(opacity * 2.5);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.opacity != opacity;
}