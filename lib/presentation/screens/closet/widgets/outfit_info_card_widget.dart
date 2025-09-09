import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class OutfitInfoCardWidget extends StatefulWidget {
  final OutfitModel outfitModel;
  final VoidCallback? onPress;
  const OutfitInfoCardWidget({
    super.key,
    required this.outfitModel,
    this.onPress,
  });

  @override
  State<OutfitInfoCardWidget> createState() => _OutfitInfoCardWidgetState();
}

class _OutfitInfoCardWidgetState extends State<OutfitInfoCardWidget>
    with SingleTickerProviderStateMixin {
  late bool isFavourite;
  late AnimationController _controller;


  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    setState(() {
      isFavourite = widget.outfitModel.isFavourite ?? false;
      //debugPrint('isFavourite: $isFavourite');
      if (!mounted) return;
      _controller.forward(from: 0);
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }


  Future<void> addOrRemoveFromFavourite(String outfitId) async {
    try {
      final result = await sl<FirebaseClosetService>()
          .addOrRemoveFavouriteOutfit(outfitId);
      result.fold(
        (l) => debugPrint("Error adding or removing favourite outfit: $l"),
        (r) {
          setState(() {
            isFavourite = r;
          });
        },
      );
    } on FirebaseException catch (e) {
      debugPrint(
        "Error adding or removing favourite closet item: ${e.message}",
      );
      //return Left(e.message);
    }
  }
}
