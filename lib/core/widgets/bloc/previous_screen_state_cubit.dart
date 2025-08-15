import 'package:hydrated_bloc/hydrated_bloc.dart';

class PreviousScreenStateCubit extends HydratedCubit<String> {
  PreviousScreenStateCubit() : super('');

void setPreviousScreen(String prevScreen) =>
      emit(prevScreen);

  String get previousScreen => state;

    @override
  String? fromJson(Map<String, dynamic> json) {
    return json['prev_screen'] as String;
  }

  @override
  Map<String, dynamic>? toJson(String state) {
    return {'prev_screen': state};
  }
}