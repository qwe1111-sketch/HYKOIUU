import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sport_flutter/domain/entities/user.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/services/oss_upload_service.dart';
import 'package:sport_flutter/l10n/app_localizations.dart'; // Import localizations
import 'package:iconsax/iconsax.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  File? _avatarImage;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      final l10n = AppLocalizations.of(context)!;
      // 如果数据库里的 bio 是空的，或者等于那个默认的中文句子，我们就显示本地化的默认值
      if (_bioController.text.isEmpty || _bioController.text == '这个人很懒，什么都没有留下。') {
        _bioController.text = l10n.defaultBio;
      }
      _isFirstLoad = false;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final authBloc = context.read<AuthBloc>();
    final l10n = AppLocalizations.of(context)!;
    String? avatarUrl = widget.user.avatarUrl;

    if (_avatarImage != null) {
      final ossService = context.read<OssUploadService>();
      try {
        final uploadedUrl = await ossService.uploadFile(_avatarImage!, uploadPath: 'videos/avatars');
        avatarUrl = uploadedUrl;
      } catch (e) {
        if (mounted) {
          // Localized avatar upload failure message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.appTitle} ${l10n.error}: $e')));
        }
        return;
      }
    }

    authBloc.add(UpdateProfileEvent(
      username: _usernameController.text,
      bio: _bioController.text,
      avatarUrl: avatarUrl,
    ));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Access localizations

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile), // Localized title
        actions: [
          IconButton(
            icon: const Icon(Iconsax.save_2),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 32),
            _buildTextField(_usernameController, l10n.username), // Localized username label
            const SizedBox(height: 16),
            _buildTextField(_bioController, l10n.introduction, maxLines: 3), // Localized bio label
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    ImageProvider? backgroundImage;
    if (_avatarImage != null) {
      backgroundImage = FileImage(_avatarImage!);
    } else if (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(widget.user.avatarUrl!);
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: backgroundImage,
            child: backgroundImage == null ? const Icon(Iconsax.profile_circle, size: 50) : null,
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              onTap: _pickImage,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Iconsax.edit, size: 20, color: Colors.blueAccent),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
