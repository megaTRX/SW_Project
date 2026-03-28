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

  static const _blue   = Color(0xFF5B8DEF);
  static const _purple = Color(0xFF6C63E0);
  static const _bg     = Color(0xFFEEF2F7);

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
        Uri.parse('http://localhost:8000/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': id, 'password': pw}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아이디 또는 비밀번호가 틀렸어요'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버에 연결할 수 없어요'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _onSocial(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$provider 로그인 준비 중'),
      backgroundColor: _purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
              const SizedBox(height: 14),
              _SocialBtn(label: '카카오로 로그인', bg: const Color(0xFFFEE500), textColor: const Color(0xFF191919), logo: const _KakaoLogo(), onTap: () => _onSocial('카카오')),
              const SizedBox(height: 8),
              _SocialBtn(label: '네이버로 로그인', bg: const Color(0xFF03C75A), textColor: Colors.white, logo: const _NaverLogo(), onTap: () => _onSocial('네이버')),
              const SizedBox(height: 8),
              _SocialBtn(label: 'Google로 로그인', bg: Colors.white, textColor: const Color(0xFF3C4043), borderColor: const Color(0xFFDDE3EE), logo: const _GoogleLogo(), onTap: () => _onSocial('구글')),
              const SizedBox(height: 8),
              _SocialBtn(label: 'Apple로 로그인', bg: const Color(0xFF1A1A1A), textColor: Colors.white, logo: const Icon(Icons.apple, color: Colors.white, size: 20), onTap: () => _onSocial('애플')),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 소셜 버튼 (Row로 로고+텍스트 배치, 겹침 없음) ──
class _SocialBtn extends StatelessWidget {
  final String label;
  final Color bg, textColor;
  final Color? borderColor;
  final Widget logo;
  final VoidCallback onTap;
  const _SocialBtn({required this.label, required this.bg, required this.textColor, required this.logo, required this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        side: BorderSide(color: borderColor ?? bg, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 20, height: 20, child: logo),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    ),
  );
}

// ── 카카오 로고 ──
class _KakaoLogo extends StatelessWidget {
  const _KakaoLogo();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _KakaoPainter());
}

class _KakaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..color = const Color(0xFF191919);
    // 타원형 말풍선
    canvas.drawOval(Rect.fromLTWH(0, 0, s.width, s.height * 0.82), paint);
    // 꼬리
    final tail = Path()
      ..moveTo(s.width * 0.3, s.height * 0.7)
      ..lineTo(s.width * 0.18, s.height)
      ..lineTo(s.width * 0.48, s.height * 0.78)
      ..close();
    canvas.drawPath(tail, paint);
    // 노란색 K 심볼
    final yp = Paint()..color = const Color(0xFFFEE500)..strokeWidth = s.width * 0.12..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final cx = s.width * 0.5;
    final cy = s.height * 0.38;
    final h = s.height * 0.28;
    canvas.drawLine(Offset(cx - s.width * 0.14, cy - h), Offset(cx - s.width * 0.14, cy + h), yp);
    canvas.drawLine(Offset(cx - s.width * 0.14, cy), Offset(cx + s.width * 0.18, cy - h * 0.9), yp);
    canvas.drawLine(Offset(cx - s.width * 0.04, cy + h * 0.1), Offset(cx + s.width * 0.2, cy + h * 0.9), yp);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── 네이버 로고 ──
class _NaverLogo extends StatelessWidget {
  const _NaverLogo();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _NaverPainter());
}

class _NaverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)..lineTo(s.width * 0.42, 0)
        ..lineTo(s.width * 0.58, s.height * 0.48)..lineTo(s.width * 0.58, 0)
        ..lineTo(s.width, 0)..lineTo(s.width, s.height)
        ..lineTo(s.width * 0.58, s.height)
        ..lineTo(s.width * 0.42, s.height * 0.52)..lineTo(s.width * 0.42, s.height)
        ..lineTo(0, s.height)..close(),
      Paint()..color = Colors.white,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── 구글 로고 ──
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.38, sw = s.width * 0.2;
    void arc(Color c, double start, double sweep) => canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r), start, sweep, false,
      Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt,
    );
    arc(const Color(0xFF4285F4), -0.26, 1.96);
    arc(const Color(0xFF34A853), 1.7, 1.3);
    arc(const Color(0xFFFBBC04), 3.0, 1.0);
    arc(const Color(0xFFEA4335), 4.0, 0.6);
    canvas.drawLine(Offset(cx, cy), Offset(cx + r + sw * 0.5, cy),
      Paint()..color = const Color(0xFF4285F4)..strokeWidth = sw..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_) => false;
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
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(height: 1, color: const Color(0xFFDDE3EE))),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('소셜 로그인', style: TextStyle(fontSize: 12, color: Color(0xFFB0BAC9)))),
    Expanded(child: Container(height: 1, color: const Color(0xFFDDE3EE))),
  ]);
}
