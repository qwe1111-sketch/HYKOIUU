import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/data/repositories/auth_repository_impl.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';

/// 邀请码输入对话框：提交成功后返回 true，取消/关闭返回 false。
class InvitationCodeDialog extends StatefulWidget {
  final AppLocalizations l10n;
  const InvitationCodeDialog({super.key, required this.l10n});

  @override
  State<InvitationCodeDialog> createState() => _InvitationCodeDialogState();
}

class _InvitationCodeDialogState extends State<InvitationCodeDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _mapError(String raw) {
    final l10n = widget.l10n;
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('socketfailed') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('nodename nor servname') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('timeout') ||
        lower.contains('timed out')) {
      return l10n.networkError;
    }
    if (raw == 'incorrectInvitationCode') return l10n.incorrectInvitationCode;
    if (raw == 'invitationCodeRequired') return l10n.invitationCodeRequired;
    return raw;
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = widget.l10n.invitationCodeRequired);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await context.read<AuthRepositoryImpl>().applyInvitationCode(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = _mapError(raw);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.invitationCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !_isLoading,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: l10n.invitationCodeInputHint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1C1C1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              content: Text(
                                l10n.invitationCodeTooltip,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    l10n.gotIt,
                                    style: const TextStyle(
                                      color: Color(0xFFCCFF00),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFFCCFF00),
                    size: 20,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFCCFF00).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFCCFF00)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white12),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        l10n.submit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
