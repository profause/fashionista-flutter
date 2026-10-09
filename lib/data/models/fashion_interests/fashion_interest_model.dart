import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fashion_interest_model.g.dart';

/// A single fashion interest document from the `fashion_interests`
/// collection (e.g. `category: "tops"`, `name: "crop top"`).
@JsonSerializable(explicitToJson: true)
class FashionInterestModel extends Equatable {
  /// The interest's category, used to group interests in the UI.
  @JsonKey(name: 'category', defaultValue: '')
  final String category;

  /// The display name of the interest.
  @JsonKey(name: 'name', defaultValue: '')
  final String name;

  /// Number of posts associated with this interest.
  @JsonKey(
    name: 'number_of_posts',
    defaultValue: 0,
    fromJson: _parsePostCount,
  )
  final int numberOfPosts;

  const FashionInterestModel({
    required this.category,
    required this.name,
    this.numberOfPosts = 0,
  });

  factory FashionInterestModel.fromJson(Map<String, dynamic> json) =>
      _$FashionInterestModelFromJson(json);

  /// Builds a model from a raw Firestore document map.
  ///
  /// Tolerates the different key names and value types the
  /// `fashion_interests` documents may use for the post count.
  factory FashionInterestModel.fromFirestore(Map<String, dynamic> data) {
    return FashionInterestModel(
      category: (data['category'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      numberOfPosts: _parsePostCount(
        _firstNonNull(data, const [
          'number_of_posts',
          'numberOfPosts',
          'number_of_post',
          'no_of_posts',
          'posts_count',
        ]),
      ),
    );
  }

  static Object? _firstNonNull(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) return value;
    }
    return null;
  }

  /// Parses a post count from an `int`, `num`, or numeric `String`.
  static int _parsePostCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  Map<String, dynamic> toJson() => _$FashionInterestModelToJson(this);

  factory FashionInterestModel.empty() {
    return const FashionInterestModel(
      category: '',
      name: '',
      numberOfPosts: 0,
    );
  }

  FashionInterestModel copyWith({
    String? category,
    String? name,
    int? numberOfPosts,
  }) {
    return FashionInterestModel(
      category: category ?? this.category,
      name: name ?? this.name,
      numberOfPosts: numberOfPosts ?? this.numberOfPosts,
    );
  }

  @override
  List<Object?> get props => [category, name, numberOfPosts];
}
