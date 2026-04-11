import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sport_flutter/domain/entities/user.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/services/oss_upload_service.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _doPickImage(ImageSource.camera);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.selectPicturesFromAlbum.replaceAll(RegExp(r'.*?相册'), '拍照').replaceAll('Select pictures from album', 'Take a Photo'),
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1, indent: 0, endIndent: 0),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _doPickImage(ImageSource.gallery);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.selectPicturesFromAlbum,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _doPickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 全局底层背景图
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
          Column(
            children: [
              // 自定义 AppBar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        l10n.editProfile,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildAvatarSection(),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          l10n.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_usernameController),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          l10n.introduction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_bioController, maxLines: 5),
                      const SizedBox(height: 40),
                      _buildSaveButton(l10n),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    ImageProvider? backgroundImage;
    if (_avatarImage != null) {
      backgroundImage = FileImage(_avatarImage!);
    } else if (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty) {
      backgroundImage = CachedNetworkImageProvider(widget.user.avatarUrl!);
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCCFF00), width: 2.0),
              image: backgroundImage != null
                  ? DecorationImage(
                      image: backgroundImage,
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.white10,
            ),
            child: backgroundImage == null
                ? const Icon(Iconsax.profile_circle, size: 60, color: Colors.white24)
                : null,
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFCCFF00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera, size: 22, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFCCFF00), width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCCFF00),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Text(
          l10n.save,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
