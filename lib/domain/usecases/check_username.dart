import '../repositories/auth_repository.dart';

class CheckUsername {
  final AuthRepository repository;

  CheckUsername(this.repository);

  Future<bool> call(String username) async {
    return await repository.checkUsername(username);
  }
}
