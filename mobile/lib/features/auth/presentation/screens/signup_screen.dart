import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/exceptions/auth_failure.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_validators.dart';
import '../widgets/daiary_logo.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    setState(() => _errorMessage = null);
    final emailError = AuthValidators.email(_emailCtrl.text);
    final passwordError = AuthValidators.password(_passwordCtrl.text);
    if (emailError != null || passwordError != null) {
      setState(() => _errorMessage = emailError ?? passwordError);
      return;
    }
    setState(() => _submitting = true);
    try {
      final loggedIn = await ref.read(authProvider.notifier).signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      if (!loggedIn) {
        // メール確認が必要な環境ではセッションが発行されない。
        // ログイン画面へ誘導する（/home 遷移は router が auth 状態で防ぐ）。
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('確認メールを送信しました。メール内のリンクを開いてからログインしてください'),
          ),
        );
        context.go('/login');
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DaiaryColors.cream, Color(0xFFEBE3D8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DaiaryLogo(),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _emailCtrl,
                    hintText: 'メールアドレス',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _passwordCtrl,
                    hintText: 'パスワード（6 文字以上）',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: const Color(0xFFC0BBB5),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: DaiaryColors.errorRed, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _onSignup,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('新規登録'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'すでにアカウントをお持ちの方は ',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF9A9590)),
                          ),
                          TextSpan(
                            text: 'ログイン',
                            style: TextStyle(
                              fontSize: 11,
                              color: DaiaryColors.brandGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
