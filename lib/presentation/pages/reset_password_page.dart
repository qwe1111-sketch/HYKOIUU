import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/pages/login_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _timer;
  int _countdown = 60;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  void _sendVerificationCode() {
    if (_emailFieldKey.currentState?.validate() == true) {
      _startCountdown();
      context.read<AuthBloc>().add(SendPasswordResetCodeEvent(_emailController.text));
    }
  }

  void _resetPassword() {
    if (_formKey.currentState?.validate() == true) {
      context.read<AuthBloc>().add(ResetPasswordEvent(
            _emailController.text,
            _codeController.text,
            _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthCodeSent) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.codeSent)));
        } else if (state is AuthUnauthenticated && ModalRoute.of(context)?.isCurrent == true) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.passwordResetSuccessLogin)));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        } else if (state is AuthError) {
          if (_timer?.isActive ?? false) {
            _timer!.cancel();
            setState(() {});
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. 顶部背景图
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 350,
              child: Image.asset(
                'assets/images/profile/top.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            // 2. 黑色渐变遮罩
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 350,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // 3. 内容层
            SafeArea(
              child: Column(
                children: [
                  // 自定义 AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/community/back.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          l10n.resetPassword,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              l10n.resetYourPassword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.resetPasswordInstruction,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildLabel(l10n.email),
                            const SizedBox(height: 12),
                            _buildTextField(
                              key: _emailFieldKey,
                              controller: _emailController,
                              hintText: l10n.enterEmailHint,
                              prefixIconPath: 'assets/images/login/email.svg',
                              validator: (value) {
                                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                if (value == null || !emailRegex.hasMatch(value)) {
                                  return l10n.enterValidEmail;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.verificationCode),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _codeController,
                                    hintText: l10n.enterCodeHint,
                                    prefixIconPath: 'assets/images/login/verificationcode.svg',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.enterVerificationCode;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 60,
                                  width: 110,
                                  child: ElevatedButton(
                                    onPressed: (_timer?.isActive ?? false) ? null : _sendVerificationCode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCCFF00),
                                      foregroundColor: Colors.black,
                                      disabledBackgroundColor: const Color(0xFFCCFF00).withOpacity(0.3),
                                      disabledForegroundColor: Colors.black.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      (_timer?.isActive ?? false) ? '${_countdown}s' : l10n.sendVerificationCode,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.password),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: l10n.enterNewPassword,
                              prefixIconPath: 'assets/images/login/password.svg',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: SvgPicture.asset(
                                  _obscurePassword
                                      ? 'assets/images/login/off.svg'
                                      : 'assets/images/login/password.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(Color(0xFFCCFF00), BlendMode.srcIn),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return l10n.passwordTooShort;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.confirmNewPassword),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              hintText: l10n.enterConfirmPassword,
                              prefixIconPath: 'assets/images/login/password.svg',
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: SvgPicture.asset(
                                  _obscureConfirmPassword
                                      ? 'assets/images/login/off.svg'
                                      : 'assets/images/login/password.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(Color(0xFFCCFF00), BlendMode.srcIn),
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return l10n.passwordsDoNotMatch;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 48),
                            _buildSubmitButton(l10n),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
    );
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String hintText,
    required String prefixIconPath,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            prefixIconPath,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
          ),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFCCFF00), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is ResettingPasswordInProgress || (state is AuthLoading && state.loadingType == null);
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCCFF00),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFFCCFF00).withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : Text(l10n.confirmReset, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
