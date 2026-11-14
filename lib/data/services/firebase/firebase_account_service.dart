import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/account/account_deletion_result.dart';

abstract class FirebaseAccountService {
  Future<Either<String, AccountDeletionResult>> deleteMyAccount({
    required String confirmation,
  });
}

class FirebaseAccountServiceImpl implements FirebaseAccountService {
  static const String deleteCallable = 'deleteMyAccount';

  @override
  Future<Either<String, AccountDeletionResult>> deleteMyAccount({
    required String confirmation,
  }) async {
    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable(
            deleteCallable,
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 540),
            ),
          )
          .call<Map<String, dynamic>>({'confirmation': confirmation});

      return Right(AccountDeletionResult.fromMap(response.data));
    } on FirebaseFunctionsException catch (error) {
      return Left(_messageFor(error));
    } catch (error) {
      return Left(
        'We could not delete your account. Check your connection and try '
        'again. If the problem continues, contact support.',
      );
    }
  }

  static String _messageFor(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Your session has expired. Sign in again to delete your '
            'account.';
      case 'invalid-argument':
        return error.message ?? 'Type DELETE to confirm account deletion.';
      case 'failed-precondition':
        return error.message ?? 'Your account deletion is already in progress.';
      case 'resource-exhausted':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'deadline-exceeded':
        return 'Deletion is taking longer than expected. Try again; it will '
            'resume where it left off.';
      case 'unavailable':
        return 'You appear to be offline. Check your connection and try again.';
      default:
        return 'We could not finish deleting your account. Please try again. '
            'If the problem continues, contact support.';
    }
  }
}
