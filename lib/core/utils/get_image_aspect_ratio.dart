import 'dart:async';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';



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

