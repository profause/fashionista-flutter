/// Process-wide guard for the Firebase Auth `userChanges()` race.
///
/// Deleting the Auth user makes `userChanges()` emit `null` before the callable
/// response reaches Flutter. While the flag is set, listeners must not fetch a
/// profile or navigate on their own.
class AccountDeletionState {
  bool _isDeleting = false;

  bool get isDeleting => _isDeleting;

  void begin() {
    _isDeleting = true;
  }

  /// Called when deletion fails so the normal signed-in state can resume.
  void end() {
    _isDeleting = false;
  }

  /// Called when a new sign-in succeeds after a completed deletion.
  void reset() {
    _isDeleting = false;
  }
}
