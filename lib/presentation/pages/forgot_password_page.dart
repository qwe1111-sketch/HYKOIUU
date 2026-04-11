import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCodeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _timer;
  int _countdown = 60;

  @override
  void dispose() {
    _timer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (!mounted) return;
    setState(() {
      _isCodeSent = true;
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        setState(() {}); // Rebuild to enable the resend button.
      }
    });
  }

  void _sendForgotPasswordCode() {
    if (_formKey.currentState?.validate() == true) {
      context.read<AuthBloc>().add(ForgotPasswordSendCodeEvent(
            _usernameController.text,
            _emailController.text,
          ));
    }
  }

  void _resetForgottenPassword() {
    if (_formKey.currentState?.validate() == true) {
      context.read<AuthBloc>().add(ForgotPasswordResetEvent(
            _usernameController.text,
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
        if (state is ForgotPasswordCodeSent) {
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.codeSent)));
        } else if (state is ForgotPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.passwordResetSuccessLogin), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        } else if (state is AuthError) {
          if (state.errorType == 'ForgotPasswordSendCodeError') {
            _timer?.cancel();
            setState(() => _isCodeSent = false);
          }
          final message =
              state.message == 'usernameAndEmailMismatch' ? l10n.usernameAndEmailMismatch : state.message;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ));
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
                'assets/images/community/top.png',
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
                            if (!_isCodeSent) ...[
                              _buildLabel(l10n.username),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _usernameController,
                                hintText: l10n.enterUsernameHint,
                                prefixIconPath: 'assets/images/login/username.svg',
                                validator: (value) => value!.isEmpty ? l10n.enterUsername : null,
                              ),
                              const SizedBox(height: 24),
                              _buildLabel(l10n.email),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _emailController,
                                hintText: l10n.enterEmailHint,
                                prefixIconPath: 'assets/images/login/email.svg',
                                validator: (value) =>
                                    (value == null || !value.contains('@')) ? l10n.enterValidEmail : null,
                              ),
                              const SizedBox(height: 48),
                              _buildButton(
                                text: l10n.sendVerificationCode,
                                onPressed: _sendForgotPasswordCode,
                                isLoading: context.watch<AuthBloc>().state is AuthLoading &&
                                    (context.watch<AuthBloc>().state as AuthLoading).loadingType ==
                                        'ForgotPasswordSendCode',
                              ),
                            ] else ...[
                              _buildLabel(l10n.verificationCode),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _codeController,
                                hintText: l10n.enterCodeHint,
                                prefixIconPath: 'assets/images/login/verificationcode.svg',
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _countdown > 0 ? '$_countdown s' : '',
                                        style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                validator: (value) => value!.isEmpty ? l10n.enterVerificationCode : null,
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
                                        : 'assets/images/profile/password.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(Color(0xFFCCFF00), BlendMode.srcIn),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (value) =>
                                    (value == null || value.length < 6) ? l10n.passwordTooShort : null,
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
                                        : 'assets/images/profile/password.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(Color(0xFFCCFF00), BlendMode.srcIn),
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                validator: (value) => value != _passwordController.text ? l10n.passwordsDoNotMatch : null,
                              ),
                              const SizedBox(height: 48),
                              _buildButton(
                                text: l10n.confirmReset,
                                onPressed: _resetForgottenPassword,
                                isLoading: context.watch<AuthBloc>().state is AuthLoading &&
                                    (context.watch<AuthBloc>().state as AuthLoading).loadingType ==
                                        'ForgotPasswordReset',
                              ),
                            ],
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String prefixIconPath,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
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

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B8E23),
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF6B8E23).withOpacity(0.6),
          disabledForegroundColor: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(
                text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
