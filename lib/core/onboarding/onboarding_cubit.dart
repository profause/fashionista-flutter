import 'package:hydrated_bloc/hydrated_bloc.dart';

class OnboardingCubit extends HydratedCubit<bool> {
  OnboardingCubit() : super(false);

  void hasSeenOnboarding(bool hasSeenOnboarding) =>
      emit(hasSeenOnboarding);

  bool get hasCompletedOnboarding => state;

  @override
  bool? fromJson(Map<String, dynamic> json) {
    return json['has_seen_onboarding'] as bool;
  }

  @override
  Map<String, dynamic>? toJson(bool state) {
    return {'has_seen_onboarding': state};
  }
}
