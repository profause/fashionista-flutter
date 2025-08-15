import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';


abstract class UserEvent {
  const UserEvent();
}

class LoadUser extends UserEvent {
  final User user;
  const LoadUser(this.user);
}

class UpdateUser extends UserEvent {
  final User user;
  const UpdateUser(this.user);
}

class ClearUser extends UserEvent {
  const ClearUser();
}

class UserBloc extends HydratedBloc<UserEvent, User> {
  UserBloc() : super(User.empty()) {
    on<LoadUser>((event, emit) => emit(event.user));
    on<UpdateUser>((event, emit) => emit(event.user));
    on<ClearUser>((event, emit) => emit(User.empty()));
  }

  @override
  User? fromJson(Map<String, dynamic> json) {
    try {
      return User.fromJson(json);
    } catch (_) {
      return User.empty();
    }
  }

  @override
  Map<String, dynamic>? toJson(User state) {
    try {
      return state.toJson();
    } catch (_) {
      return null;
    }
  }
}
