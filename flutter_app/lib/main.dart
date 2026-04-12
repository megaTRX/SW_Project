import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/med_page.dart';
import 'pages/schedule_page.dart';
import 'pages/log_page.dart';
import 'pages/camera_page.dart';
import 'pages/settings_page.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── 전역 토큰 저장소 ──
class AppState {
  static String? accessToken;
  static String? username;
  static String? nickname;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    print("✅ 환경 변수 로드 성공!");
  } catch (e) {
    print("❌ .env 파일을 찾을 수 없거나 로드에 실패했습니다: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OASIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _isLoading = false;
  String _errorMsg = '';

  void _login() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_idController.text == 'admin' && _pwController.text == '1234') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        setState(() {
          _errorMsg = '아이디 또는 비밀번호가 올바르지 않습니다.';
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF6366F1)],
                    ).createShader(bounds),
                    child: const Icon(Icons.health_and_safety_rounded, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF6366F1)],
                    ).createShader(bounds),
                    child: const Text(
                      'OASIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text('아이디', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'admin',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('비밀번호', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('로그인'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(onTabChange: _onTabChange),
      const MedPage(),
      const SchedulePage(),
      const LogPage(),
      const CameraPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF6366F1)],
          ).createShader(bounds),
          child: const Text('OASIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
            onPressed: () {
              AppState.accessToken = null;
              AppState.username = null;
              AppState.nickname = null;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          )
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: '대시보드'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: '복약'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: '대화'),
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈캠'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '설정'),
        ],
      ),
    );
  }
}