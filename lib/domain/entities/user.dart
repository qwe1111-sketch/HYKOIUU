import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl; // This will now ALWAYS be a full URL provided by the backend.
  final String? bio;
  final bool usedInvitationCode; // 注册时或补填时使用了有效邀请码

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.usedInvitationCode = false,
  });

  @override
  List<Object?> get props => [id, username, email, avatarUrl, bio, usedInvitationCode];
}
