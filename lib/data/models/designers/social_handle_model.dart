import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_handle_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SocialHandle extends Equatable {
  final String name;
  final String url;
  final String provider;

  const SocialHandle({
    required this.name,
    required this.url,
    required this.provider,
  });

  factory SocialHandle.fromJson(Map<String, dynamic> json) =>
      _$SocialHandleFromJson(json);

  Map<String, dynamic> toJson() => _$SocialHandleToJson(this);

  factory SocialHandle.empty() {
    return const SocialHandle(name: '', url: '', provider: '');
  }

  static List<SocialHandle> defaults() {
    return [
      SocialHandle(name: '', url: '', provider: 'Facebook'),
      SocialHandle(name: '', url: '', provider: 'Instagram'),
      SocialHandle(name: '', url: '', provider: 'X'),
    ];
  }

  @override
  List<Object?> get props => [name, url, provider];
}
