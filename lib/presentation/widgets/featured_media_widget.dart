import 'dart:async';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_flutter/image/cld_image_widget_configuration.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/cloudinary_config.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeaturedMediaWidget extends StatefulWidget {
  final List<FeaturedMediaModel> featuredMedia;

  const FeaturedMediaWidget({super.key, required this.featuredMedia});

  @override
  State<FeaturedMediaWidget> createState() => _FeaturedMediaWidgetState();
}

class _FeaturedMediaWidgetState extends State<FeaturedMediaWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  double _currentHeight = 250; // default initial height
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    _settingsBloc = context.read<SettingsBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.featuredMedia.isNotEmpty) {
      _loadFirstImageSize();
    }
  }

  Future<void> _loadFirstImageSize() async {
    final size = widget.featuredMedia.first.aspectRatio;
    if (size != null && mounted) {
      setState(() {
        _currentHeight = _calculateDisplayHeight(size);
      });
    }
  }

  double _calculateDisplayHeight(double aspectRatio) {
    final screenWidth = MediaQuery.of(context).size.width;
    final newHeight = screenWidth / aspectRatio;
    return newHeight.clamp(180, 800);
  }

  Future<void> _updateHeightForIndex(int index) async {
    final size = widget.featuredMedia[index].aspectRatio;
    if (size != null && mounted) {
      setState(() {
        _currentHeight = _calculateDisplayHeight(size);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _currentHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.featuredMedia.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _updateHeightForIndex(index);
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.featuredMedia[index].url;
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CldImageWidget(
                    key: ValueKey(imageUrl),
                    cloudinary: Cloudinary.fromConfiguration(
                      CloudinaryConfig.fromUri(appConfig.get('cloudinary_url')),
                    ),
                    publicId: '${widget.featuredMedia[index].uid}',
                    configuration: CldImageWidgetConfiguration(cache: true),
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    fit: BoxFit.fill,
                    placeholderFadeInDuration: const Duration(
                      milliseconds: 150,
                    ),
                    errorBuilder: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    transformation:
                        Transformation().addTransformation(
                          _settingsBloc.state.imageQuality == 'HD'
                              ? 'q_100'//'q_auto:best'
                              : 'q_auto:good',
                        )..resize(
                          Resize.fill().aspectRatio(
                            widget.featuredMedia[index].aspectRatio,
                          ),
                        ),
                  ),

                  // CachedNetworkImage(
                  //   imageUrl: imageUrl!,
                  //   fit: BoxFit.fill,
                  //   placeholder: (context, url) => const Center(
                  //     child: SizedBox(
                  //       height: 24,
                  //       width: 24,
                  //       child: CircularProgressIndicator(strokeWidth: 2),
                  //     ),
                  //   ),
                  //   errorWidget: (context, url, error) =>
                  //       const Center(child: Text('No Image')),
                  // ),
                ),
              );
            },
          ),

          // 🔘 Page Indicator
          if (widget.featuredMedia.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.featuredMedia.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: _currentIndex == index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
