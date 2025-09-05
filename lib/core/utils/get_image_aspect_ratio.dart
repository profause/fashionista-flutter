import 'dart:async';
import 'dart:ui';

import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';

Future<double?> getImageAspectRatioNative(XFile file) async {
  ImageProperties properties = await FlutterNativeImage.getImageProperties(
    file.path,
  );

  return properties.width! / properties.height!;
}

Future<double?> getImageAspectRatio(XFile file) async {
  final completer = Completer<double>();
  final bytes = await file.readAsBytes();

  decodeImageFromList(bytes, (image) {
    final aspect = image.width / image.height;
    // round to 2 decimal places
    completer.complete(double.parse(aspect.toStringAsFixed(2)));
  });

  return completer.future;
}

