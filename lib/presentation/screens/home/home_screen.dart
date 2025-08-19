import 'package:fashionista/presentation/screens/home/widgets/header.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        toolbarHeight: 0,
        // systemOverlayStyle: SystemUiOverlayStyle(
        //   statusBarColor: colorScheme.surface,
        //   statusBarIconBrightness: Brightness.dark,
        //   //systemNavigationBarColor: Colors.white,
        //   systemNavigationBarIconBrightness: Brightness.dark,
        // ),
        title: Text(
          'Home',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Header(), const SizedBox(height: 8)],
          ),
        ),
      ),
    );
  }
}
