class AuthState {
  final bool isAuthenticated;
  final String mobileNumber;
  final String? uid;
  final String username;

  AuthState({
    required this.username,
    required this.isAuthenticated,
    required this.mobileNumber,
    required this.uid,
  
  });
}
