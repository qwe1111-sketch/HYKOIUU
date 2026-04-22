import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/services/translation_service.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextAlign? textAlign;

  const TranslatedText({
    super.key, 
    required this.text, 
    required this.style,
    this.maxLines,
    this.textAlign,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  bool _didTranslate = false;

  @override
  void initState() {
    super.initState();
    // Initially, display the original text.
    _translatedText = widget.text;
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _didTranslate = false;
      _translatedText = widget.text;
      // Trigger translation if the text changed
      _didTranslate = true;
      _translateText();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-translate if the locale changed
    _didTranslate = true;
    _translateText();
  }

  Future<void> _translateText() async {
    // No need to translate if the widget is no longer in the tree.
    if (!mounted) return;

    final languageCode = Localizations.localeOf(context).languageCode;
    
    // Check if the source text contains any Chinese characters.
    // If it's already Chinese and the target is also Chinese, don't translate.
    bool containsChinese(String text) {
      return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
    }

    if (languageCode == 'zh' && containsChinese(widget.text)) {
        setState(() {
            _translatedText = widget.text;
        });
        return;
    }

    try {
      final translationService = context.read<TranslationService>();
      final result = await translationService.translate(widget.text, languageCode);
      if (mounted) {
        setState(() {
          _translatedText = result;
        });
      }
    } catch (e) {
      if (mounted) {
          setState(() {
              _translatedText = widget.text;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.textAlign,
    );
  }
}
