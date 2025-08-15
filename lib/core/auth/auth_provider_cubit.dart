import 'package:fashionista/core/auth/models/auth_state.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class AuthProviderCubit extends HydratedCubit<AuthState> {
  AuthProviderCubit()
    : super(AuthState(username: "", mobileNumber: "", uid: "", isAuthenticated: false));

  AuthState get authState => super.state;

  void setAuthState(String username, String mobileNumber, String uid, bool isAuthenticated) {
    final AuthState authState = AuthState(
      username: username,
      mobileNumber: mobileNumber,
      uid: uid,
      isAuthenticated: isAuthenticated,
    );
    emit(authState);
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    return AuthState(
      username: json['username'] as String,
      mobileNumber: json['mobileNumber'] as String,
      uid: json['uid'] as String,
      isAuthenticated: json['isAuthenticated'] as bool,
    );
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    return {
      'username': state.username,
      'mobileNumber': state.mobileNumber,
      'uid': state.uid,
      'isAuthenticated': state.isAuthenticated,
    };
  }
}
