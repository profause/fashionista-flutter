import 'package:hydrated_bloc/hydrated_bloc.dart';

class ButtonLoadingStateCubit extends HydratedCubit<bool> {
  ButtonLoadingStateCubit() : super(false);

  void setLoading(bool isLoading) =>
      emit(isLoading);

  bool get isLoading => state;

  @override
  bool? fromJson(Map<String, dynamic> json) {
    return json['is_loading'] as bool;
  }

  @override
  Map<String, dynamic>? toJson(bool state) {
    return {'is_loading': state};
  }
}
