import 'package:hydrated_bloc/hydrated_bloc.dart';

class GetstartedStatsCubit extends HydratedCubit<Map<String, int>> {
  GetstartedStatsCubit()
      : super({'likes': 0, 'followings': 0, 'interests': 0});

  Map<String, int> get stats => state;

  void setStats(int likes, int followings, int interests) {
    emit({'likes': likes, 'followings': followings, 'interests': interests});
  }

  void updateLikes(int value) {
    emit({...state, 'likes': value});
  }

  void updateFollowings(int value) {
    emit({...state, 'followings': value});
  }

  void updateInterests(int value) {
    emit({...state, 'interests': value});
  }

  @override
  Map<String, dynamic> toJson(Map<String, int> map) => map;

  @override
  Map<String, int>? fromJson(Map<String, dynamic> json) {
    return {
      'likes': json['likes'] ?? 0,
      'followings': json['followings'] ?? 0,
      'interests': json['interests'] ?? 0,
    };
  }
}
