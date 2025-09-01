import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/assets/app_images.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/home/designer_home_page.dart';
import 'package:fashionista/presentation/screens/home/user_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    UserBloc userBloc = context.read<UserBloc>();
    final user = userBloc.state;
    return user.accountType == 'Designer' ? DesignerHomePage() : UserHomePage();
  }
}
