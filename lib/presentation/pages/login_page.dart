import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/pages/forgot_password_page.dart';
import 'package:sport_flutter/presentation/pages/home_page.dart';
import 'package:sport_flutter/presentation/pages/register_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _backendError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    setState(() {
      _backendError = null;
    });

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginEvent(_usernameController.text, _passwordController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
          } else if (state is AuthError) {
            setState(() {
              _backendError = l10n.invalidUsernameOrPassword;
            });
          }
        },
        builder: (context, state) {
          return Stack(
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
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // 禁止滚动
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 110),
                              Center(
                                child: Column(
                                  children: [
                                    // 显式强制为白色，防止某些环境下的默认渲染问题
                                    SvgPicture.asset(
                                      'assets/images/login/app_logo.svg',
                                      height: 70,
                                      fit: BoxFit.contain,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      placeholderBuilder: (context) => const Icon(Icons.warning, color: Colors.amber),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      l10n.loginWelcomeSubtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(l10n.username),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _usernameController,
                                      hintText: l10n.enterUsernameHint,
                                      prefixIconPath: 'assets/images/login/username.svg',
                                      validator: (value) => value!.isEmpty ? l10n.enterUsername : null,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildLabel(l10n.password),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hintText: l10n.enterPasswordHint,
                                      prefixIconPath: 'assets/images/login/password.svg',
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: SvgPicture.asset(
                                          _obscurePassword ? 'assets/images/login/off.svg' : 'assets/images/profile/password.svg',
                                          width: 20,
                                          height: 20,
                                          colorFilter: const ColorFilter.mode(Color(0xFFCCFF00), BlendMode.srcIn),
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (value) => value!.isEmpty ? l10n.enterPassword : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              if (_backendError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Center(
                                    child: Text(
                                      _backendError!,
                                      style: const TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                              _buildLoginButton(l10n, isLoading: state is AuthLoading),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () async {
                                    final result = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: BlocProvider.of<AuthBloc>(context),
                                          child: const ForgotPasswordPage(),
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.codeSent),
                                          backgroundColor: const Color(0xFF6B8E23),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    l10n.forgotPassword,
                                    style: const TextStyle(
                                      color: Color(0xFFCCFF00),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: BlocProvider.of<AuthBloc>(context),
                                          child: const RegisterPage(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: l10n.noAccount,
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: l10n.signUp,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
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

  Widget _buildLoginButton(AppLocalizations l10n, {bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _login,
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
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(
                l10n.login,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
