import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/pages/privacy_policy_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  final _usernameFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isAgreementChecked = false;
  bool _isCodeSent = false;
  Timer? _timer;
  int _countdown = 60;

  // 用户名校验状态
  bool _isCheckingUsername = false;
  bool? _usernameExists;
  final Map<String, bool> _usernameCache = {};

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onUsernameFocusChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _usernameFocusNode.removeListener(_onUsernameFocusChanged);
    _usernameFocusNode.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _invitationCodeController.dispose();
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
        setState(() => _isCodeSent = false);
      }
    });
  }

  void _register() {
    if (_formKey.currentState!.validate() && _isAgreementChecked) {
      if (_usernameExists == true) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.usernameAlreadyExists),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      context.read<AuthBloc>().add(
        RegisterEvent(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _codeController.text,
          _invitationCodeController.text.trim(),
        ),
      );
    }
  }

  void _sendVerificationCode() {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isNotEmpty &&
        _emailController.text.contains('@')) {
      _startCountdown();
      context.read<AuthBloc>().add(SendCodeEvent(_emailController.text));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterValidEmail)));
    }
  }

  void _onUsernameFocusChanged() {
    // 只在失焦时校验
    if (_usernameFocusNode.hasFocus) return;

    final value = _usernameController.text;
    if (value.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _usernameExists = null;
      });
      return;
    }

    // 格式不合法，不发请求
    if (value.length < 2 ||
        value.length > 20 ||
        !RegExp(r'^[\w\u4e00-\u9fa5]+$').hasMatch(value)) {
      setState(() {
        _isCheckingUsername = false;
        _usernameExists = null;
      });
      return;
    }

    // 命中缓存，直接返回结果，不发请求
    if (_usernameCache.containsKey(value)) {
      setState(() {
        _isCheckingUsername = false;
        _usernameExists = _usernameCache[value];
      });
      return;
    }

    _checkUsername(value);
  }

  void _checkUsername(String value) async {
    setState(() {
      _isCheckingUsername = true;
      _usernameExists = null;
    });
    try {
      final exists = await context.read<AuthBloc>().checkUsernameUseCase.call(
        value,
      );
      if (!mounted) return;
      _usernameCache[value] = exists;
      setState(() {
        _isCheckingUsername = false;
        _usernameExists = exists;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        _usernameExists = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.registrationSuccessful),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          if (state.errorType == 'SendCodeError') {
            _timer?.cancel();
            setState(() => _isCodeSent = false);
          }
          String message;
          switch (state.message) {
            case 'pleaseRequestVerificationCodeFirst':
              message = l10n.pleaseRequestVerificationCodeFirst;
              break;
            case 'incorrectInvitationCode':
              message = l10n.incorrectInvitationCode;
              break;
            case 'usernameAlreadyExists':
              message = l10n.usernameAlreadyExists;
              break;
            case 'emailAlreadyExists':
              message = l10n.emailAlreadyExists;
              break;
            case 'invalidUsernameOrPassword':
              message = l10n.invalidUsernameOrPassword;
              break;
            case 'usernameAndEmailMismatch':
              message = l10n.usernameAndEmailMismatch;
              break;
            case 'invalidVerificationCode':
              message = l10n.invalidVerificationCode;
              break;
            default:
              message = state.message;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        } else if (state is AuthCodeSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.codeSent),
              backgroundColor: const Color(0xFF6B8E23),
            ),
          );
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
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          l10n.register,
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
                            const SizedBox(height: 40),
                            _buildLabel(l10n.username),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _usernameController,
                              hintText: l10n.enterUsernameHint,
                              prefixIconPath:
                                  'assets/images/login/username.svg',
                              focusNode: _usernameFocusNode,
                              suffixIcon: _buildUsernameStatusIcon(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.enterUsername;
                                }
                                if (value.length < 2 || value.length > 20) {
                                  return l10n.usernameLengthError;
                                }
                                if (!RegExp(
                                  r'^[\w\u4e00-\u9fa5]+$',
                                ).hasMatch(value)) {
                                  return l10n.usernameInvalidChars;
                                }
                                if (_usernameExists == true) {
                                  return l10n.usernameAlreadyExists;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.email),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _emailController,
                              hintText: l10n.enterEmailHint,
                              prefixIconPath: 'assets/images/login/email.svg',
                              validator: (value) =>
                                  (value == null || !value.contains('@'))
                                  ? l10n.enterValidEmail
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.password),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: l10n.enterPasswordHint,
                              prefixIconPath:
                                  'assets/images/login/password.svg',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: SvgPicture.asset(
                                  _obscurePassword
                                      ? 'assets/images/login/off.svg'
                                      : 'assets/images/profile/password.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFCCFF00),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.passwordTooShort;
                                }
                                if (value.length < 6 || value.length > 20) {
                                  return l10n.passwordLengthError;
                                }
                                if (!RegExp(r'^[\w!@#$%^&*()\-+=.]+$').hasMatch(value)) {
                                  return l10n.passwordInvalidChars;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.verificationCode),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _codeController,
                              hintText: l10n.enterCodeHint,
                              prefixIconPath:
                                  'assets/images/login/verificationcode.svg',
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: UnconstrainedBox(
                                  child: SizedBox(
                                    height: 36,
                                    child: ElevatedButton(
                                      onPressed: _isCodeSent
                                          ? null
                                          : _sendVerificationCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFCCFF00,
                                        ),
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFFCCFF00,
                                        ).withOpacity(0.5),
                                      ),
                                      child: Text(
                                        _isCodeSent
                                            ? '$_countdown s'
                                            : l10n.sendVerificationCode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? l10n.enterVerificationCode
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            _buildLabel(l10n.invitationCode),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _invitationCodeController,
                              hintText: l10n.enterInvitationCodeHint,
                              prefixIconPath:
                                  'assets/images/login/invitationcode.svg',
                              validator: (value) {
                                // 邀请码可选：不填直接跳过，填了后端会校验
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: Colors.white70,
                                  ),
                                  child: Checkbox(
                                    value: _isAgreementChecked,
                                    activeColor: const Color(0xFFCCFF00),
                                    checkColor: Colors.black,
                                    onChanged: (bool? value) => setState(
                                      () =>
                                          _isAgreementChecked = value ?? false,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(text: l10n.agreement),
                                        TextSpan(
                                          text: l10n.privacyPolicy,
                                          style: const TextStyle(
                                            color: Color(0xFFCCFF00),
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const PrivacyPolicyPage(),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            _buildButton(
                              text: l10n.register,
                              onPressed: _register,
                              isLoading:
                                  context.watch<AuthBloc>().state
                                      is AuthLoading,
                              enabled: _isAgreementChecked,
                            ),
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
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            prefixIconPath,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Colors.white70,
              BlendMode.srcIn,
            ),
          ),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
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

  Widget _buildUsernameStatusIcon() {
    if (_isCheckingUsername) {
      return Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Color(0xFFCCFF00),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_usernameExists == true) {
      return Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: const Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 20,
        ),
      );
    }
    if (_usernameExists == false && _usernameController.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: const Icon(
          Icons.check_circle,
          color: Color(0xFF6B8E23),
          size: 20,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isLoading || !enabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B8E23),
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF6B8E23).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
