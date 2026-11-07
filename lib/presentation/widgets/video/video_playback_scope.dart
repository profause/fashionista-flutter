import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:fashionista/presentation/widgets/video/video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/// App-wide owner of the feed's playback arbitration.
///
/// Provides the manager, follows the `autoPlayVideos` setting, and pauses every
/// video while the app is in the background.
class VideoPlaybackScope extends StatefulWidget {
  final Widget child;

  const VideoPlaybackScope({super.key, required this.child});

  @override
  State<VideoPlaybackScope> createState() => _VideoPlaybackScopeState();
}

class _VideoPlaybackScopeState extends State<VideoPlaybackScope> {
  final VideoPlaybackManager _manager = VideoPlaybackManager();
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _manager.setEnabled(
      context.read<SettingsBloc>().state.autoPlayVideos ?? true,
    );
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _manager.setAppActive(state == AppLifecycleState.resumed);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `Provider` rejects a Listenable; the manager is one, and cards read it
    // with `context.read` (they subscribe themselves), so notifying dependents
    // here is harmless.
    return ChangeNotifierProvider<VideoPlaybackManager>.value(
      value: _manager,
      // A listener, not a builder: flipping the setting notifies the manager,
      // and notifying during build would mark every listening card dirty.
      child: BlocListener<SettingsBloc, Settings>(
        listenWhen: (previous, current) =>
            previous.autoPlayVideos != current.autoPlayVideos,
        listener: (context, settings) {
          _manager.setEnabled(settings.autoPlayVideos ?? true);
        },
        child: widget.child,
      ),
    );
  }
}
