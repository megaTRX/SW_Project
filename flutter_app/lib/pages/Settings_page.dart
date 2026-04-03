import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/mock_data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _alertEnabled = true;
  bool _emergencyAlert = true;
  bool _medAlert = true;
  bool _inactiveAlert = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('관리자', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('admin@oasis.kr', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('노인 케어 챗봇 관리자', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 챗봇 설정
          _SectionTitle(title: '챗봇 설정'),
          _SettingsGroup(children: [
            _NavTile(
              icon: Icons.record_voice_over_rounded,
              iconColor: const Color(0xFF6366F1),
              title: '챗봇 호출어',
              subtitle: '오아시스야',
              onTap: () => _showEditDialog(context, '챗봇 호출어', '오아시스야'),
            ),
            _Divider(),
            _NavTile(
              icon: Icons.speed_rounded,
              iconColor: const Color(0xFF0EA5E9),
              title: '음성 속도',
              subtitle: '보통',
              onTap: () => _showSpeedDialog(context),
            ),
            _Divider(),
            _NavTile(
              icon: Icons.volume_up_rounded,
              iconColor: const Color(0xFF10B981),
              title: '음성 볼륨',
              subtitle: '80%',
              onTap: () {},
            ),
            _Divider(),
            _NavTile(
              icon: Icons.smart_toy_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: 'AI 모델',
              subtitle: 'Gemini',
              onTap: () => _showAIDialog(context),
            ),
          ]),

          const SizedBox(height: 24),

          // 알림 설정
          _SectionTitle(title: '알림 설정'),
          _SettingsGroup(children: [
            _SwitchTile(
              icon: Icons.notifications_rounded,
              iconColor: const Color(0xFF6366F1),
              title: '전체 알림',
              subtitle: '모든 알림을 켜거나 끕니다',
              value: _alertEnabled,
              onChanged: (v) => setState(() => _alertEnabled = v),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.emergency_rounded,
              iconColor: const Color(0xFFEF4444),
              title: '긴급 알림',
              subtitle: '긴급 호출 발생 시 즉시 알림',
              value: _emergencyAlert,
              onChanged: (v) => setState(() => _emergencyAlert = v),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.medication_rounded,
              iconColor: const Color(0xFF10B981),
              title: '복약 알림',
              subtitle: '복약 시간 미완료 시 알림',
              value: _medAlert,
              onChanged: (v) => setState(() => _medAlert = v),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.accessibility_new_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: '비활동 감지 알림',
              subtitle: '장시간 움직임 없을 시 알림',
              value: _inactiveAlert,
              onChanged: (v) => setState(() => _inactiveAlert = v),
            ),
          ]),

          const SizedBox(height: 24),

          // 장치 연결
          _SectionTitle(title: '장치 연결'),
          _SettingsGroup(children: [
            _NavTile(
              icon: Icons.speaker_rounded,
              iconColor: const Color(0xFF6366F1),
              title: '연결된 장치',
              subtitle: 'Raspberry Pi · 테스트 모드',
              onTap: () {},
            ),
            _Divider(),
            _StatusTile(icon: Icons.mic_rounded, iconColor: const Color(0xFF10B981), title: '마이크', value: mockStatus["mic"] as String),
            _Divider(),
            _StatusTile(icon: Icons.volume_up_rounded, iconColor: const Color(0xFF10B981), title: '스피커', value: mockStatus["speaker"] as String),
            _Divider(),
            _StatusTile(icon: Icons.wifi_rounded, iconColor: const Color(0xFF10B981), title: '네트워크', value: mockStatus["network"] as String),
          ]),

          const SizedBox(height: 24),

          // 계정
          _SectionTitle(title: '계정'),
          _SettingsGroup(children: [
            _NavTile(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF6366F1),
              title: '관리자 정보',
              subtitle: 'admin',
              onTap: () => _showProfileDialog(context),
            ),
            _Divider(),
            _NavTile(
              icon: Icons.lock_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: '비밀번호 변경',
              subtitle: '',
              onTap: () => _showPasswordDialog(context),
            ),
          ]),

          const SizedBox(height: 24),

          // 소셜 로그인
          _SectionTitle(title: '소셜 로그인'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '간편 로그인 연동',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '소셜 계정으로 빠르게 로그인하세요',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SocialButton(
                        color: const Color(0xFFFEE500),
                        label: '카카오',
                        icon: Icons.chat_bubble_rounded,
                        iconColor: const Color(0xFF3C1E1E),
                        onTap: () => _showSocialLoginDialog(context, '카카오'),
                      ),
                      _SocialButton(
                        color: const Color(0xFF03C75A),
                        label: '네이버',
                        customText: 'N',
                        iconColor: Colors.white,
                        onTap: () => _showSocialLoginDialog(context, '네이버'),
                      ),
                      _SocialButton(
                        color: Colors.white,
                        label: 'Apple',
                        icon: Icons.apple_rounded,
                        iconColor: Colors.black,
                        border: true,
                        onTap: () => _showSocialLoginDialog(context, 'Apple'),
                      ),
                      _SocialButton(
                        color: Colors.white,
                        label: 'Google',
                        googleIcon: true,
                        iconColor: Colors.transparent,
                        border: true,
                        onTap: () => _showSocialLoginDialog(context, 'Google'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 앱 정보
          _SectionTitle(title: '앱 정보'),
          _SettingsGroup(children: [
            _NavTile(
              icon: Icons.info_rounded,
              iconColor: const Color(0xFF4FC3F7),
              title: '버전 정보',
              subtitle: 'v1.0.0',
              onTap: () {},
            ),
            _Divider(),
            _NavTile(
              icon: Icons.description_rounded,
              iconColor: const Color(0xFF94A3B8),
              title: '개인정보 처리방침',
              subtitle: '',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // 로그아웃
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('로그아웃', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSocialLoginDialog(BuildContext context, String provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$provider 로그인', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text('$provider 계정으로 로그인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('로그인', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Color(0xFF94A3B8)))),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('저장', style: TextStyle(color: Color(0xFF6366F1)))),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('음성 속도', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['느리게', '보통', '빠르게'].map((s) => ListTile(
            title: Text(s),
            trailing: s == '보통' ? const Icon(Icons.check_rounded, color: Color(0xFF6366F1)) : null,
            onTap: () => Navigator.pop(context),
          )).toList(),
        ),
      ),
    );
  }

  void _showAIDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('AI 모델 선택', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Gemini', 'ChatGPT', 'Local LLM'].map((s) => ListTile(
            title: Text(s),
            trailing: s == 'Gemini' ? const Icon(Icons.check_rounded, color: Color(0xFF6366F1)) : null,
            onTap: () => Navigator.pop(context),
          )).toList(),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('관리자 정보', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: '아이디', value: 'admin'),
            SizedBox(height: 8),
            _InfoRow(label: '이메일', value: 'admin@oasis.kr'),
            SizedBox(height: 8),
            _InfoRow(label: '권한', value: '관리자'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('확인', style: TextStyle(color: Color(0xFF6366F1)))),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true,
                decoration: InputDecoration(labelText: '현재 비밀번호', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(obscureText: true,
                decoration: InputDecoration(labelText: '새 비밀번호', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(obscureText: true,
                decoration: InputDecoration(labelText: '새 비밀번호 확인', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Color(0xFF94A3B8)))),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('변경', style: TextStyle(color: Color(0xFF6366F1)))),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Color(0xFF94A3B8)))),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('로그아웃', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
  }
}

// ===== 소셜 로그인 버튼 =====
class _SocialButton extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;
  final String? customText;
  final Color iconColor;
  final bool border;
  final bool googleIcon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.color,
    required this.label,
    this.icon,
    this.customText,
    required this.iconColor,
    this.border = false,
    this.googleIcon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: border ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5) : null,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: googleIcon
                  ? _GoogleIcon()
                  : customText != null
                      ? Text(customText!, style: TextStyle(color: iconColor, fontSize: 22, fontWeight: FontWeight.w900))
                      : Icon(icon, color: iconColor, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24, height: 24,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // 파란색 조각
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    // 빨간색 조각
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    // 노란색 조각
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    // 초록색 조각
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;

    // 빨간색 (위쪽)
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -2.2, 1.6, true, redPaint);
    // 파란색 (오른쪽)
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -0.6, 1.6, true, bluePaint);
    // 초록색 (아래쪽)
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        1.0, 1.2, true, greenPaint);
    // 노란색 (왼쪽)
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        2.2, 1.0, true, yellowPaint);

    // 흰색 중앙 원
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, whitePaint);

    // 파란색 오른쪽 바
    final barPaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.15, r * 0.9, r * 0.3), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56, color: Color(0xFFE2E8F0));
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ])),
          CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: const Color(0xFF6366F1)),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
        ]),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value;
  const _StatusTile({required this.icon, required this.iconColor, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final ok = value == "정상" || value == "연결됨";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ok ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label: ', style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
    ]);
  }
}