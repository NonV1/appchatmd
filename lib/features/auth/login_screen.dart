// lib/features/auth/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/perf/frame_guard.dart';
import 'widgets/glass_card.dart';
import 'widgets/social_row.dart';
import '../../ui/widgets/net_state_banner.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailNode = FocusNode();
  final _passNode = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // ให้ AuthService ดูแลการเก็บ token ภายใน (หรือคืน token มาอย่างเดียว)
      await AuthService.I.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      // ไปหน้า Home ด้วย go_router
      context.go('/');
    } on AuthException catch (e) {
      // ถ้าคุณมี AuthException ในโปรเจกต์: map code เป็นข้อความ
      _showSnack(_mapAuthException(e));
    } catch (_) {
      // เคสทั่วไป: เน็ต/เซิร์ฟเวอร์ล่ม
      _showSnack('ระบบขัดข้อง หรือไม่มีการเชื่อมต่ออินเทอร์เน็ต');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthException(AuthException e) {
    switch (e.type) {
      case AuthErrorType.unauthorized:
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case AuthErrorType.server:
        return 'เซิร์ฟเวอร์ไม่พร้อมใช้งาน';
      case AuthErrorType.network:
      case AuthErrorType.timeout:
        return 'เครือข่ายมีปัญหา';
      case AuthErrorType.badRequest:
        return e.message;
      case AuthErrorType.unknown:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spacing = AppTheme.spacing;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // BG gradient เบา ๆ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withOpacity(0.30),
                  cs.surfaceContainerHighest.withOpacity(0.30),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // แบนเนอร์สถานะเน็ต/เซิร์ฟเวอร์
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(child: NetStateBanner.auto(compact: true)),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final cardWidth = maxW < 420 ? maxW * 0.86 : 380.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: spacing.xl,
                      right: spacing.xl,
                      bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
                      top: spacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // โลโก้ / ชื่อแอป
                        Text(
                          'ChatMD',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Glass card
                        ValueListenableBuilder<bool>(
                          valueListenable: FrameGuard.I.lowPowerMode,
                          builder: (context, lowPower, _) {
                            return GlassCard(
                              width: cardWidth,
                              padding: EdgeInsets.all(spacing.lg),
                              radius: 20,
                              blurSigma: lowPower ? 0 : 16,
                              elevation: lowPower ? 0.5 : 1.5,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _email,
                                      focusNode: _emailNode,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'you@example.com',
                                      ),
                                      validator: (v) {
                                        final s = v?.trim() ?? '';
                                        if (s.isEmpty) return 'กรอกอีเมล';
                                        if (!s.contains('@') || !s.contains('.')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _passNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _password,
                                      focusNode: _passNode,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                        ),
                                      ),
                                      validator: (v) {
                                        final s = v ?? '';
                                        if (s.isEmpty) return 'กรอกรหัสผ่าน';
                                        if (s.length < 6) return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 16),

                                    SizedBox(
                                      height: 48,
                                      child: FilledButton(
                                        onPressed: _loading ? null : _submit,
                                        child: _loading
                                            ? const SizedBox(
                                                width: 18, height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Login'),
                                      ),
                                    ),

                                    // ไป Register
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: TextButton(
                                        onPressed: _loading ? null : () => context.push('/register'),
                                        child: const Text('Create account'),
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    const Divider(height: 24),

                                    // ปุ่ม Social (mock) – วางล่างการ์ด
                                    const SocialRow(onPressed: null),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        // ปุ่มสลับภาษา (placeholder)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => _showSnack('ภาษาไทย (coming soon)'),
                              child: const Text('ไทย'),
                            ),
                            TextButton(
                              onPressed: () => _showSnack('English (coming soon)'),
                              child: const Text('English'),
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
        ],
      ),
    );
  }
}
