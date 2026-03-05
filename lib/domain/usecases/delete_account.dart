import 'package:sport_flutter/domain/repositories/auth_repository.dart';

class DeleteAccount {
  final AuthRepository repository;

  DeleteAccount(this.repository);

  Future<void> call() {
    return repository.deleteAccount();
  }
}
