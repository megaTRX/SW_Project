import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  static const _blue = Color(0xFF5B8DEF);
  static const _purple = Color(0xFF6C63E0);
  static const _bg = Color(0xFFEEF2F7);

  void _onLogin() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text.trim();
    if (id.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('http://172.30.1.84:8000/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'username=$id&password=$pw',
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아이디 또는 비밀번호가 틀렸어요'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결할 수 없어요'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSocial(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider 로그인 준비 중'),
        backgroundColor: _purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              const Center(child: Icon(Icons.health_and_safety_rounded, size: 68, color: _blue)),
              const SizedBox(height: 14),
              const Center(child: Text('OASIS', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: _blue, letterSpacing: 5))),
              const SizedBox(height: 4),
              const Center(child: Text('CareBot Admin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _purple))),
              const SizedBox(height: 3),
              const Center(child: Text('노인 케어 챗봇 관리자 시스템', style: TextStyle(fontSize: 13, color: Color(0xFFA0AABC)))),
              const SizedBox(height: 32),
              const _Label('아이디'),
              const SizedBox(height: 6),
              _Input(hint: 'admin', ctrl: _idCtrl),
              const SizedBox(height: 14),
              const _Label('비밀번호'),
              const SizedBox(height: 6),
              _Input(hint: '••••••••', ctrl: _pwCtrl, obscure: true),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('테스트 계정: admin / 1234', style: TextStyle(fontSize: 11, color: Color(0xFFB0BAC9)))),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleSocialBtn(
                    color: const Color(0xFFFEE500),
                    logo: const _KakaoLogo(),
                    onTap: () => _onSocial('카카오'),
                  ),
                  const SizedBox(width: 16),
                  _CircleSocialBtn(
                    color: const Color(0xFF03C75A),
                    logo: const Text('N', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    onTap: () => _onSocial('네이버'),
                  ),
                  const SizedBox(width: 16),
                  _CircleSocialBtn(
                    color: Colors.white,
                    border: true,
                    logo: const Icon(Icons.apple, color: Colors.black, size: 30),
                    onTap: () => _onSocial('애플'),
                  ),
                  const SizedBox(width: 16),
                  _CircleSocialBtn(
                    color: Colors.white,
                    border: true,
                    logo: const _GoogleLogo(),
                    onTap: () => _onSocial('구글'),
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 원형 소셜 버튼 ──
class _CircleSocialBtn extends StatelessWidget {
  final Color color;
  final Widget logo;
  final bool border;
  final VoidCallback onTap;
  const _CircleSocialBtn({required this.color, required this.logo, required this.onTap, this.border = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: border ? Border.all(color: const Color(0xFFDDE3EE), width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(child: logo),
      ),
    );
  }
}

// ── 카카오 로고 (말풍선) ──
class _KakaoLogo extends StatelessWidget {
  const _KakaoLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30, height: 30,
    child: CustomPaint(painter: _KakaoPainter()),
  );
}

class _KakaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..color = const Color(0xFF3C1E1E);
    canvas.drawOval(Rect.fromLTWH(0, s.height * 0.05, s.width, s.height * 0.75), paint);
    final tail = Path()
      ..moveTo(s.width * 0.28, s.height * 0.70)
      ..lineTo(s.width * 0.15, s.height * 0.98)
      ..lineTo(s.width * 0.45, s.height * 0.78)
      ..close();
    canvas.drawPath(tail, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── 구글 로고 (컬러 그라데이션 G) ──
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC04),
          Color(0xFFEA4335),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── 공통 위젯 ──
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3D4561)));
}

class _Input extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final bool obscure;
  const _Input({required this.hint, required this.ctrl, this.obscure = false});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, obscureText: obscure,
    style: const TextStyle(fontSize: 15, color: Color(0xFF1A2233)),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Color(0xFFC0C8D8)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE3EE), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE3EE), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.5)),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Container(height: 1, color: const Color(0xFFDDE3EE))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('소셜 로그인', style: TextStyle(fontSize: 12, color: Color(0xFFB0BAC9))),
      ),
      Expanded(child: Container(height: 1, color: const Color(0xFFDDE3EE))),
    ],
  );
}