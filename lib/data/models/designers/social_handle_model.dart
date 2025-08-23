import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_handle_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SocialHandle extends Equatable {
  final String handle;
  final String url;
  final String provider;

  const SocialHandle({
    required this.handle,
    required this.url,
    required this.provider,
  });

  factory SocialHandle.fromJson(Map<String, dynamic> json) =>
      _$SocialHandleFromJson(json);

  Map<String, dynamic> toJson() => _$SocialHandleToJson(this);

  factory SocialHandle.empty() {
    return const SocialHandle(handle: '', url: '', provider: '');
  }

  static List<SocialHandle> defaults() {
    return [
      SocialHandle(handle: '', url: '', provider: 'Facebook'),
      SocialHandle(handle: '', url: '', provider: 'Instagram'),
      SocialHandle(handle: '', url: '', provider: 'X'),
      SocialHandle(handle: '', url: '', provider: 'TikTok'),
    ];
  }

  SocialHandle copyWith({
    String? handle,
    String? url,
    String? provider,
  }) {
    return SocialHandle(
      handle: handle ?? this.handle,
      url: url ?? this.url,
      provider: provider ?? this.provider,
    );
  }

  @override
  List<Object?> get props => [handle, url, provider];
}
