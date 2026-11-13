import 'dart:io';
import 'dart:math';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_image_aspect_ratio.dart';
import 'package:fashionista/core/utils/hashtag_parser.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/fashion_interests/bloc/fashion_interest_cubit.dart';
import 'package:fashionista/data/models/fashion_interests/bloc/fashion_interest_state.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/trend_audience.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/repository/fashion_interests/fashion_interest_repository.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_usecase.dart';
import 'package:fashionista/presentation/widgets/profile_avatar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:fashionista/data/models/trends/bloc/video_upload_cubit.dart';
import 'package:fashionista/data/models/video/edited_video.dart';
import 'package:fashionista/presentation/screens/trends/video/video_capture_screen.dart';
import 'package:fashionista/presentation/screens/trends/video/widgets/video_upload_progress.dart';
import 'package:fashionista/presentation/screens/trends/trend_composer_rules.dart';
import 'package:fashionista/presentation/screens/trends/widgets/fashion_interest_panel.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_audience_sheet.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

/// Placeholder pool for an empty composer. One is picked per screen instance,
/// never per build, so the hint cannot change under the user's fingers.
const List<String> trendComposerHints = [
  "✨ Share your next fashion moment…",
  "👗 What’s trending in your world?",
  "🧵 Stitch your trend into the feed…",
  "🚀 Kick off the next big fashion vibe…",
  "🖋 Describe your style inspiration…",
  "🔥 Drop your hottest fashion trend…",
];

class AddTrendScreen extends StatefulWidget {
  const AddTrendScreen({super.key});

  @override
  State<AddTrendScreen> createState() => _AddTrendScreenState();
}

class _AddTrendScreenState extends State<AddTrendScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late ValueNotifier<String> imageQuality = ValueNotifier('SD');
  final FocusNode _descriptionFocusNode = FocusNode();
  late SettingsBloc _settingsBloc;
  late final FashionInterestCubit _interestCubit;

  /// Chosen once per composer, see [trendComposerHints].
  late final String _hint;

  int _currentLength = 0;
  final int _maxLength = 100; // keep in sync with input field
  static const int _maxMedia = 4; // matches the picker limit

  final ImagePicker picker = ImagePicker();
  final VideoUploadCubit _uploadCubit = VideoUploadCubit();

  /// Local clip chosen in the camera/editor flow; replaces the image carousel.
  EditedVideo? _editedVideo;

  /// Who can see the post; public unless the author picks otherwise.
  TrendAudience _audience = TrendAudience.public;

  /// The interest catalogue is tucked behind the toolbar to keep the composer
  /// quiet.
  bool _showInterests = false;

  /// Hashtag the caret is editing, if any. Drives the same panel as the
  /// toolbar button, filtered by what the user typed after `#`.
  ActiveHashtag? _activeHashtag;

  List<XFile> pickedImages = [];
  List<double> uploadProgress = [];
  List<XFile> previewImages = [];
  bool isUploading = false;

  /// A trend must carry at least one photo or one video.
  bool get _hasMedia => _editedVideo != null || pickedImages.isNotEmpty;

  bool get _hasDescription =>
      _descriptionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _settingsBloc = context.read<SettingsBloc>();
    _descriptionController = TextEditingController();
    _interestCubit = FashionInterestCubit(
      repository: sl<FashionInterestRepository>(),
    )..load();
    _hint = trendComposerHints[Random().nextInt(trendComposerHints.length)];
    _descriptionController.addListener(_handleDescriptionChanged);

    imageQuality.value = _settingsBloc.state.imageQuality ?? 'SD';
  }

  /// Keeps the length counter and the `#` interest panel in sync with the text
  /// and caret.
  void _handleDescriptionChanged() {
    final active = activeHashtag(
      _descriptionController.text,
      _descriptionController.selection,
    );

    _interestCubit.filter(active?.query ?? '');

    if (!mounted) return;
    setState(() {
      _currentLength = _descriptionController.text.length;
      _activeHashtag = active;
    });
  }

  @override
  void dispose() {
    _interestCubit.close();
    _uploadCubit.close();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    previewImages.clear();
    pickedImages.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: _buildTopBar(context, textTheme),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComposer(context, textTheme),
                      if (_showInterests || _activeHashtag != null) ...[
                        const SizedBox(height: 12),
                        BlocBuilder<FashionInterestCubit, FashionInterestState>(
                          bloc: _interestCubit,
                          builder: (context, state) {
                            return FashionInterestPanel(
                              interests: state.visible,
                              isLoading: state.isLoading,
                              error: state.error,
                              query: state.query,
                              onRetry: () =>
                                  _interestCubit.load(forceRefresh: true),
                              onInterestTap: _insertInterest,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(context, textTheme),
          ],
        ),
      ),
    );
  }

  /// Composer bar: close on the left, the post action on the right.
  AppBar _buildTopBar(BuildContext context, TextTheme textTheme) {
    final canPost = TrendComposerRules.canPublish(
      description: _descriptionController.text,
      hasMedia: _hasMedia,
      isUploading: isUploading,
    );

    return AppBar(
      backgroundColor: context.canvasBackground,
      foregroundColor: context.onCanvasText,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: IconButton(
        onPressed: isUploading ? null : () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, size: 26),
        tooltip: 'Cancel',
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: FilledButton(
            onPressed: canPost ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: context.accent,
              disabledBackgroundColor: context.accent.withValues(alpha: .35),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Post'),
          ),
        ),
      ],
    );
  }

  /// Avatar + audience chip, then the post body and whatever media is attached.
  Widget _buildComposer(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ProfileAvatar(radius: 20),
            const SizedBox(width: 12),
            _buildAudienceChip(context),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          autofocus: true,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          minLines: 2,
          maxLines: 10,
          maxLength: _maxLength,
          keyboardType: TextInputType.multiline,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w400,
            color: context.onCanvasText,
          ),
          validator: (value) {
            if ((value ?? '').isEmpty) return 'Please enter a description';
            return null;
          },
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            isCollapsed: true,
            filled: false,
            contentPadding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
            border: InputBorder.none,
            hintText: _hint,
            hintStyle: textTheme.headlineSmall?.copyWith(
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w400,
              color: context.placeholderText,
            ),
          ),
        ),
        if (_currentLength > 0 || previewImages.isNotEmpty)
          _buildCounter(context, textTheme),
        if (_hasDescription && !_hasMedia) ...[
          const SizedBox(height: 8),
          _buildMediaRequiredHint(context, textTheme),
        ],
        if (_editedVideo != null || previewImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMediaStrip(context, textTheme),
        ],
      ],
    );
  }

  Widget _buildAudienceChip(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isUploading ? null : _pickAudience,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.accent, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _audience.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.accent,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 18, color: context.accent),
            ],
          ),
        ),
      ),
    );
  }

  /// Character count and media count, only once the user has something to say.
  Widget _buildCounter(BuildContext context, TextTheme textTheme) {
    final overLimit = _currentLength >= _maxLength;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (previewImages.isNotEmpty)
            Text(
              '${previewImages.length}/$_maxMedia photos',
              style: textTheme.labelSmall?.copyWith(
                color: context.secondaryLabel,
              ),
            ),
          const Spacer(),
          Text(
            '$_currentLength/$_maxLength',
            style: textTheme.labelSmall?.copyWith(
              color: overLimit ? context.accent : context.secondaryLabel,
              fontWeight: overLimit ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Explains why the Post action is still disabled once the user starts
  /// writing but has not attached a photo or a video yet.
  Widget _buildMediaRequiredHint(BuildContext context, TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.image_outlined, size: 16, color: context.mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Add at least one photo or video to post',
            style: textTheme.labelSmall?.copyWith(
              color: context.mutedText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaStrip(BuildContext context, TextTheme textTheme) {
    if (_editedVideo != null) {
      return _videoTile(_editedVideo!);
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: previewImages.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == previewImages.length) {
            return _addMediaTile(context, textTheme);
          }
          return _lookbookTile(context, textTheme, index);
        },
      ),
    );
  }

  /// Fixed bottom bar: who sees the post, then the attach actions.
  Widget _buildBottomBar(BuildContext context, TextTheme textTheme) {
    final isDraft = _audience == TrendAudience.draft;

    // A post is either one video or up to four photos. Once a clip is attached
    // the image pickers are pointless: `_saveTrend` publishes the video and the
    // photos would be dropped without a word.
    final hasVideo = _editedVideo != null;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            InkWell(
              onTap: isUploading ? null : _pickAudience,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Icon(
                      isDraft ? Icons.lock_outline : Icons.public,
                      size: 16,
                      color: context.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDraft
                          ? 'Only you can see this post'
                          : 'Everyone can see this trend',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _toolbarButton(
                    context,
                    icon: Icons.image_outlined,
                    tooltip: hasVideo
                        ? 'Remove the video to add photos'
                        : 'Add photos',
                    onTap: isUploading || hasVideo
                        ? null
                        : () => pickImages(context),
                  ),
                  _toolbarButton(
                    context,
                    icon: Icons.photo_camera_outlined,
                    tooltip: hasVideo
                        ? 'Remove the video to take a photo'
                        : 'Take a photo',
                    onTap: isUploading || hasVideo
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                  _toolbarButton(
                    context,
                    icon: Icons.videocam_outlined,
                    tooltip: 'Record a video',
                    onTap: isUploading ? null : _pickVideo,
                  ),
                  _toolbarButton(
                    context,
                    icon: Icons.tag,
                    tooltip: 'Browse interests',
                    isActive: _showInterests || _activeHashtag != null,
                    onTap: isUploading
                        ? null
                        : () =>
                              setState(() => _showInterests = !_showInterests),
                  ),
                  const Spacer(),
                  _buildQualityToggle(context, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    // An explicit `color` would keep a disabled button looking tappable.
    final color = onTap == null
        ? context.secondaryLabel.withValues(alpha: .38)
        : (isActive ? context.accent : context.secondaryLabel);

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      color: color,
      disabledColor: color,
      splashRadius: 22,
    );
  }

  /// Image quality is a posting setting, so it lives next to the attach actions.
  Widget _buildQualityToggle(BuildContext context, TextTheme textTheme) {
    return ValueListenableBuilder<String>(
      valueListenable: imageQuality,
      builder: (context, quality, _) {
        return Material(
          color: context.iconSubstrate,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => imageQuality.value = quality == 'SD' ? 'HD' : 'SD',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                quality,
                style: textTheme.labelSmall?.copyWith(
                  color: context.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Turns a tapped interest into a hashtag in the description.
  ///
  /// Replaces the `#token` being edited, or inserts at the caret. A trailing
  /// space is appended so the panel does not reopen on the new hashtag.
  void _insertInterest(FashionInterestModel interest) {
    final hashtag = hashtagFor(interest.name);
    if (hashtag.isEmpty) return;

    final insertion = insertHashtag(
      text: _descriptionController.text,
      selection: _descriptionController.selection,
      hashtag: hashtag,
      active: _activeHashtag,
    );

    if (insertion.text.length > _maxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough room for that tag')),
      );
      return;
    }

    _descriptionController.value = TextEditingValue(
      text: insertion.text,
      selection: insertion.selection,
    );

    if (!mounted) return;
    setState(() {
      _showInterests = false;
      _activeHashtag = null;
    });
    _descriptionFocusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // A trend is a look: the feed card renders media, and a post without any
    // would fall back to its "no image" placeholder.
    if (!_hasMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo or video to post')),
      );
      return;
    }

    await _saveTrend();
  }

  Widget _videoTile(EditedVideo video) {
    return _ComposerVideoPreview(
      video: video,
      onRemove: isUploading ? null : () => setState(() => _editedVideo = null),
    );
  }

  Widget _lookbookTile(BuildContext context, TextTheme textTheme, int index) {
    final image = previewImages[index];
    return SizedBox(
      width: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(image.path), fit: BoxFit.cover),
            // Scrim keeps the label legible over any photo.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: .70),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Look ${index + 1}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _removePreviewImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .25),
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addMediaTile(BuildContext context, TextTheme textTheme) {
    return SizedBox(
      width: 140,
      child: Material(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isUploading ? null : () => pickImages(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.softBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.iconSubstrate,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: context.accent, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add Media',
                  style: textTheme.labelSmall?.copyWith(
                    color: context.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAudience() async {
    final picked = await showTrendAudienceSheet(context, current: _audience);
    if (picked == null || !mounted) return;

    setState(() => _audience = picked);
  }

  /// Keeps the reel the user sees in sync with the list that gets uploaded.
  void _removePreviewImage(int index) {
    setState(() {
      if (index < previewImages.length) previewImages.removeAt(index);
      if (index < pickedImages.length) pickedImages.removeAt(index);
      if (index < uploadProgress.length) uploadProgress.removeAt(index);
    });
  }

  Future<void> pickImages(BuildContext context) async {
    if (_editedVideo != null) return;

    final images = await picker.pickMultiImage(
      imageQuality: 70,
      limit: 4,
      requestFullMetadata: true,
    );
    if (images.isEmpty) return;

    setState(() {
      pickedImages = images;
      for (var i = 0; i < images.length; i++) {
        previewImages.add(images[i]);
      }
      //images.forEach((i)=>previewImages.add(i));
      uploadProgress = List.filled(images.length, 0.0);
    });

    if (context.mounted) {
      //uploadImages(context);
      //setPreviewImages();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_editedVideo != null) return;

    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          previewImages.add(pickedFile);
          pickedImages.add(pickedFile);
        });
      }
    } catch (e, st) {
      debugPrint('Error picking image: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _pickVideo() async {
    // The recorder opens the editor as soon as a take ends, so this returns the
    // edited clip (or null when the flow was dismissed).
    final edited = await VideoCaptureScreen.open(context);
    if (edited == null || !mounted) return;

    setState(() {
      _editedVideo = edited;
      // A post is either images or one video; mixing them is rejected here.
      pickedImages = [];
      previewImages = [];
    });
  }

  Future<void> _publishVideo({
    required String trendId,
    required EditedVideo video,
  }) async {
    final user = context.read<UserBloc>().state;
    final createdBy =
        user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;

    final author = AuthorModel.empty().copyWith(
      uid: createdBy,
      name: user.fullName,
      avatar: user.profileImage,
    );

    Future<void> publish({
      required String trendId,
      required FeaturedMediaModel media,
    }) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final trend = TrendFeedModel.empty().copyWith(
        uid: trendId,
        createdBy: createdBy,
        description: _descriptionController.text.trim(),
        tags: extractHashtags(_descriptionController.text).join(','),
        createdAt: now,
        updatedAt: now,
        author: author,
        featuredMedia: [media],
        audience: _audience.value,
      );

      final result = await sl<AddTrendUsecase>().call(trend);
      await result.fold((failure) async => throw Exception('$failure'), (
        _,
      ) async {
        if (mounted) {
          context.read<TrendBloc>().add(AddTrend(trend));
        }
      });
    }

    final upload = _uploadCubit.start(
      trendId: trendId,
      videoPath: video.path,
      hasAudio: video.hasAudio,
      publish: publish,
    );

    final published = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider<VideoUploadCubit>.value(
        value: _uploadCubit,
        child: const VideoUploadProgress(),
      ),
    );

    await upload;
    if (!mounted) return;

    if (published == true) {
      // The composer has nothing left to do once the post is live.
      context.pop();
    }
  }

  Future<void> _saveTrend() async {
    try {
      UserBloc userBloc = context.read<UserBloc>();
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      //_buttonLoadingStateCubit.setLoading(true);
      final description = _descriptionController.text.trim();
      final tags = extractHashtags(_descriptionController.text).join(',');
      final trendId = Uuid().v4();

      // A video post is a single media entry; images are a carousel.
      final video = _editedVideo;
      if (video != null) {
        await _publishVideo(trendId: trendId, video: video);
        return;
      }

      // Show progress dialog
      showLoadingDialog(context);
      final uploadResult = await uploadImagesToCloudinary(context, trendId);

      // A failed upload must abort the publish. The previous code returned from
      // inside the fold closure only, so a failed upload still created a post
      // with an empty `featured_media` list (T21).
      final uploaded = uploadResult.fold<List<FeaturedMediaModel>?>((failure) {
        if (mounted) dismissLoadingDialog(context);
        if (!mounted) return null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure)));
        return null;
      }, (media) => media);
      if (uploaded == null) return;
      final featuredImages = uploaded;

      final author = AuthorModel.empty().copyWith(
        uid: createdBy,
        name: user.fullName,
        avatar: user.profileImage,
      );

      final trend = TrendFeedModel.empty().copyWith(
        uid: trendId,
        createdBy: createdBy,
        description: description,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        author: author,
        tags: tags,
        featuredMedia: featuredImages,
        audience: _audience.value,
      );

      final result = await sl<AddTrendUsecase>().call(trend);

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            //Navigator.of(context).pop();
            dismissLoadingDialog(context);
          }
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          if (mounted) {
            context.read<TrendBloc>().add(AddTrend(trend));
          }
          // _buttonLoadingStateCubit.setLoading(false);
          setState(() {
            isUploading = false;
          });
          if (!mounted) return;
          dismissLoadingDialog(context);
          context.pop();
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      //_buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>>
  uploadImagesToCloudinary(BuildContext context, String trendId) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');
    setState(() => isUploading = true);
    CloudinaryConfig config = CloudinaryConfig.fromUri(
      appConfig.get('cloudinary_url'),
    );
    final trendMediaFolder = appConfig.get('cloudinary_trend_media_folder');
    final baseFolder = appConfig.get('cloudinary_base_folder');

    final cloudinary = Cloudinary.fromConfiguration(config);
    final aspects = <double?>[];
    final uploadTasks =
        <Future<FeaturedMediaModel>>[]; // explicitly Future<String>

    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];
      final uploadFile = File(image.path);

      // Get aspect ratio
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);

      final fileName = "${trendId}_$i.jpg";
      final publicId = "${trendId}_$i";

      final transformation = Transformation()
          .resize(Resize.auto().width(480).aspectRatio(aspect))
          .addTransformation(imageQuality.value == 'SD' ? 'q_60' : 'q_100');
      // Define upload task returning a non-null String
      final uploadTask = (() async {
        final uploadResult = await cloudinary.uploader().upload(
          uploadFile,
          params: UploadParams(
            filename: fileName,
            publicId: publicId,
            useFilename: true,
            folder: '$baseFolder/$trendMediaFolder',
            uploadPreset: 'ml_default',
            type: 'image/jpeg',
            transformation: transformation,
          ),
        );

        if (uploadResult == null) {
          debugPrint("Upload failed — no response from Cloudinary");
          throw Exception("Upload failed — no response from Cloudinary");
        }
        if (uploadResult.error != null) {
          debugPrint("Upload failed: ${uploadResult.error!.message}");
          throw Exception(uploadResult.error!.message);
        }

        final url = uploadResult.data?.secureUrl;
        if (url == null) {
          debugPrint("Upload failed — no URL returned");
          throw Exception("Upload failed — no URL returned");
        }

        String thumbnailUrl =
            (cloudinary.image('$baseFolder/$trendMediaFolder/$fileName')
                  ..transformation(
                    Transformation().addTransformation('q_auto:good')
                      ..resize(Resize.auto().width(360).aspectRatio(aspect)),
                  ))
                .toString();
        final featuredMedia = FeaturedMediaModel().copyWith(
          url: url,
          type: "image",
          aspectRatio: aspect,
          thumbnailUrl: thumbnailUrl,
          uid: '$baseFolder/$trendMediaFolder/$publicId',
        );
        return featuredMedia; // ✅ Non-null String
      })();

      uploadTasks.add(uploadTask);
    }

    try {
      // Wait for all uploads to finish
      final featuredMedia = await Future.wait(uploadTasks); // List<String>
      final mergedList = featuredMedia;

      setState(() {
        isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Images uploaded successfully!")),
        );
      }

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  Future<dartz.Either<String, List<FeaturedMediaModel>>> uploadImages(
    BuildContext context,
    String trendId,
  ) async {
    if (pickedImages.isEmpty) return dartz.Left('image list is empty');

    setState(() => isUploading = true);

    final storage = FirebaseStorage.instance;
    final uploadTasks = <Future<String>>[];
    final aspects = <double?>[];

    // Step 1: Collect aspect ratios + prepare upload tasks
    for (int i = 0; i < pickedImages.length; i++) {
      final image = pickedImages[i];

      // get aspect ratio
      final aspect = await getImageAspectRatio(image);
      aspects.add(aspect);

      // prepare upload
      uploadTasks.add(() async {
        final fileName = "${trendId}_$i.jpg";
        final ref = storage.ref().child("trend_media/$fileName");

        final uploadTask = ref.putFile(
          File(image.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=15768000',
          ),
        );
        await uploadTask;
        return await ref.getDownloadURL();
      }());
    }

    try {
      // Step 2: Upload all + get URLs
      final urls = await Future.wait(uploadTasks);

      // Step 3: Merge into FeaturedMediaModel list
      final mergedList = List.generate(
        urls.length,
        (i) => FeaturedMediaModel(
          url: urls[i],
          type: "image", // could be "video" if needed
          aspectRatio: aspects[i],
        ),
      );

      setState(() {
        isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Images uploaded successfully!")),
        );
      }

      return dartz.Right(mergedList);
    } catch (e) {
      setState(() => isUploading = false);
      return dartz.Left(e.toString());
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// Preview of the clip attached to the post, played from the local file.
///
/// Same shape as the image tiles: 180 tall, rounded, tap to play or pause. It
/// starts paused on the first frame so the composer does not play audio on its
/// own.
class _ComposerVideoPreview extends StatefulWidget {
  final EditedVideo video;
  final VoidCallback? onRemove;

  const _ComposerVideoPreview({required this.video, this.onRemove});

  @override
  State<_ComposerVideoPreview> createState() => _ComposerVideoPreviewState();
}

class _ComposerVideoPreviewState extends State<_ComposerVideoPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final file = File(widget.video.path);
    if (!await file.exists()) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      setState(() => _controller = controller);
    } catch (error) {
      debugPrint('Clip preview failed: $error');
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() => _playing = controller.value.isPlaying);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Prefer what the decoder reports; the editor's metadata is the fallback
  /// while the controller is still initializing.
  double _aspectRatio(VideoPlayerController? controller) {
    final reported = controller?.value.isInitialized == true
        ? controller!.value.aspectRatio
        : null;
    final ratio = reported ?? widget.video.aspectRatio;
    if (ratio.isNaN || ratio <= 0) return 9 / 16;
    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = _controller;
    final ratio = _aspectRatio(controller);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;

        // Full width at the clip's own ratio, capped so a vertical clip cannot
        // push the rest of the composer off screen. Past the cap the frame is
        // centred with black bars: never cropped, never stretched.
        final height = (width / ratio).clamp(120.0, screen.height * .55);
        // Never let a clamp stretch the frame: the box keeps the clip's ratio.
        final videoHeight = min(height, width / ratio);
        final videoWidth = videoHeight * ratio;

        return SizedBox(
          height: height,
          width: videoWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      width: videoWidth,
                      height: videoHeight,
                      child: controller != null
                          ? VideoPlayer(controller)
                          : _buildPlaceholder(),
                    ),
                  ),

                  // Tap anywhere on the clip to play or pause it.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: controller == null ? null : _toggle,
                      child: const SizedBox.shrink(),
                    ),
                  ),

                  if (controller != null && !_playing)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .45),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.video.duration.inSeconds}s · ${widget.video.sizeLabel}',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: widget.onRemove,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .25),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    if (!_failed) {
      return const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off, color: Colors.white54),
          SizedBox(height: 6),
          Text(
            'This clip could not be previewed',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
