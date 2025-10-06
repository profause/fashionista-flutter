import 'package:hydrated_bloc/hydrated_bloc.dart';

class GetstartedStatsCubit extends HydratedCubit<Map<String, int>> {
  GetstartedStatsCubit() : super({});

  Map<String, int> get stats => super.state;

  void setStatsState(int likes, int followings, int interests) {
    emit({'likes': likes, 'followings': followings, 'interests': interests});
  }

  @override
  Map<String, dynamic> toJson(Map<String, int> map) {
    return {
      'likes': map['likes'],
      'followings': map['followings'],
      'interests': map['interests'],
    };
  }

  @override
  Map<String, int>? fromJson(Map<String, dynamic> json) {
    return {
      'likes': json['likes'] ?? 0,
      'followings': json['followings'] ?? 0,
      'interests': json['interests'] ?? 0,
    };
  }
}
