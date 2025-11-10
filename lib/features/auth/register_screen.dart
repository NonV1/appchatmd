// lib/features/auth/register_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/router/app_router.dart';
import '../../theme/app_theme.dart';
import 'widgets/glass_card.dart';
import 'widgets/social_row.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _netStatus; // "no_internet" | "server_down" | null

  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    // เฝ้าสถานะเน็ตแบบ realtime
    _connSub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final hasNet = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
      setState(() => _netStatus = hasNet ? null : "no_internet");
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _name.dispose();
    _email.dispose();
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // เช็คเน็ตก่อน
    if (_netStatus == "no_internet") {
      _showSnack('ไม่มีการเชื่อมต่ออินเทอร์เน็ต', isError: true);
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final result = await AuthService.instance.register(
        displayName: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass1.text,
      );
      if (!mounted) return;
      if (result.ok) {
        _showSnack('สมัครสำเร็จ • กำลังเข้าสู่ระบบ', isError: false);
        context.goNamed(AppRoute.home);
      } else {
        _showSnack(
          result.message ?? 'เซิร์ฟเวอร์ขัดข้อง ลองใหม่อีกครั้ง',
          isError: true,
        );
      }
    } catch (e) {
      // mapping ง่ายๆ: ถ้าเป็น network/client error ให้ทรีตเป็น server down
      final msg = e.toString();
      if (msg.contains('Connection refused') ||
          msg.contains('SocketException') ||
          msg.contains('Timeout')) {
        _netStatus = "server_down";
        _showSnack('เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง', isError: true);
      } else {
        _showSnack(msg.replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.tokensOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // ใช้ SingleChildScrollView + ConstrainedBox ป้องกัน overflow
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 36),
                child: Column(
                  children: [
                    // Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ยินดีต้อนรับ • สมัครสมาชิกเพื่อเริ่มใช้งาน',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // แบนเนอร์สถานะเน็ต/เซิร์ฟเวอร์
                    if (_netStatus == "no_internet" || _netStatus == "server_down")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Glass.panel(
                          t: t,
                          elevated: true,
                          useBlur: false,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _netStatus == "no_internet"
                                    ? Icons.wifi_off_rounded
                                    : Icons.cloud_off_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _netStatus == "no_internet"
                                      ? 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต'
                                      : 'เซิร์ฟเวอร์ขัดข้อง • กรุณาลองใหม่ภายหลัง',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // GLASS FORM
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text('ชื่อผู้ใช้',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'เช่น Natthawat',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'กรุณากรอกชื่อผู้ใช้';
                                }
                                if (v.trim().length < 2) {
                                  return 'สั้นเกินไป';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email
                            Text('อีเมล',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'name@example.com',
                              ),
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'กรุณากรอกอีเมล';
                                final ok = RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(s);
                                return ok ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            Text('รหัสผ่าน',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pass1,
                              obscureText: _obscure1,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'อย่างน้อย 8 ตัวอักษร',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure1
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure1 = !_obscure1),
                                ),
                              ),
                              validator: (v) {
                                final s = v ?? '';
                                if (s.length < 8) {
                                  return 'ต้องมีอย่างน้อย 8 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Confirm password
                            Text('ยืนยันรหัสผ่าน',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pass2,
                              obscureText: _obscure2,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'พิมพ์รหัสผ่านอีกครั้ง',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure2
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure2 = !_obscure2),
                                ),
                              ),
                              validator: (v) {
                                if (v != _pass1.text) {
                                  return 'รหัสผ่านไม่ตรงกัน';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Submit
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text('สมัครสมาชิก'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Social (ล่างสุด)
                    const SocialRow(),

                    const SizedBox(height: 16),

                    // ไปหน้า Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'มีบัญชีอยู่แล้ว?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.goNamed(AppRoute.login),
                          child: const Text('เข้าสู่ระบบ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
