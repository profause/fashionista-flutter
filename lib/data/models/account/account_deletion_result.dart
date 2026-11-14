import 'package:equatable/equatable.dart';

/// Result returned by the `deleteMyAccount` callable.
class AccountDeletionResult extends Equatable {
  final String status;
  final bool alreadyCompleted;
  final int completedSteps;

  const AccountDeletionResult({
    this.status = 'completed',
    this.alreadyCompleted = false,
    this.completedSteps = 0,
  });

  factory AccountDeletionResult.fromMap(Map<String, dynamic> map) {
    return AccountDeletionResult(
      status: map['status'] as String? ?? 'completed',
      alreadyCompleted: map['alreadyCompleted'] == true,
      completedSteps: (map['completedSteps'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [status, alreadyCompleted, completedSteps];
}
