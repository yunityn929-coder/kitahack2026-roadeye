import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool   _isLoading   = false;
  bool   _obscurePass = true;
  bool   _obscureConf = true;
  String _errorMessage = '';

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _slideAnim;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080809),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _GridPainter(opacity: _pulseAnim.value * 0.045),
              ),
            ),
          ),

          Positioned(
            top: -180,
            right: -180,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 520,
                height: 520,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3b82f6)
                          .withOpacity(_pulseAnim.value * 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -200,
            left: -200,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFef4444)
                          .withOpacity(_pulseAnim.value * 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
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
                      _LogoBlock(),
                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111113),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: const Color(0xFF222226)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3b82f6),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3b82f6)
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'CREATE ACCOUNT',
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
                                    color: const Color(0xFF3b82f6)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFF3b82f6)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'ADMIN ONLY',
                                    style: TextStyle(
                                      color: Color(0xFF3b82f6),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            _FieldLabel('USERNAME'),
                            const SizedBox(height: 6),
                            _StyledField(
                              controller: _usernameController,
                              hint: 'johndoe',
                              icon: Icons.person_outline_rounded,
                              obscure: false,
                              accentColor: const Color(0xFF3b82f6),
                            ),
                            const SizedBox(height: 18),

                            _FieldLabel('EMAIL ADDRESS'),
                            const SizedBox(height: 6),
                            _StyledField(
                              controller: _emailController,
                              hint: 'admin@roadeye.io',
                              icon: Icons.alternate_email_rounded,
                              obscure: false,
                              accentColor: const Color(0xFF3b82f6),
                            ),
                            const SizedBox(height: 18),

                            _FieldLabel('PASSWORD'),
                            const SizedBox(height: 6),
                            _StyledField(
                              controller: _passwordController,
                              hint: '••••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePass,
                              accentColor: const Color(0xFF3b82f6),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF555560),
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                            const SizedBox(height: 18),

                            _FieldLabel('CONFIRM PASSWORD'),
                            const SizedBox(height: 6),
                            _StyledField(
                              controller: _confirmController,
                              hint: '••••••••••',
                              icon: Icons.lock_reset_rounded,
                              obscure: _obscureConf,
                              accentColor: const Color(0xFF3b82f6),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConf
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF555560),
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConf = !_obscureConf),
                              ),
                            ),

                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(message: _errorMessage),
                            ],
                            const SizedBox(height: 24),

                            _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF3b82f6),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _BlueButton(
                                    label: 'CREATE ACCOUNT',
                                    icon: Icons.person_add_alt_1_rounded,
                                    onPressed: _signup,
                                  ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                    child: Container(
                                        height: 1,
                                        color: const Color(0xFF222226))),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'HAVE AN ACCOUNT?',
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
                            _GhostButton(
                              label: 'BACK TO LOGIN',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
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
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'All fields are required');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Signup failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}


class _LogoBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF555560),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final Color accentColor;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.obscure,
    this.suffixIcon,
    this.accentColor = const Color(0xFFef4444),
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
            color: Color(0xFFe5e5e5), fontSize: 14, letterSpacing: 0.3),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF333338), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF444450), size: 18),
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
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFef4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFFef4444).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFef4444), size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFef4444), fontSize: 12)),
            ),
          ],
        ),
      );
}

class _BlueButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _BlueButton(
      {required this.label,
      required this.icon,
      required this.onPressed});
  @override
  State<_BlueButton> createState() => _BlueButtonState();
}

class _BlueButtonState extends State<_BlueButton> {
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
                  ? [const Color(0xFF60a5fa), const Color(0xFF3b82f6)]
                  : [const Color(0xFF3b82f6), const Color(0xFF2563eb)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3b82f6)
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

class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _GhostButton({required this.label, required this.onPressed});
  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
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