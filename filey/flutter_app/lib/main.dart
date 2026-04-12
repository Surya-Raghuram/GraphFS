import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/filey_project.dart';
import 'theme/filey_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FileyProject(),
      child: const FileyApp(),
    ),
  );
}

class FileyApp extends StatelessWidget {
  const FileyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filey',
      debugShowCheckedModeBanner: false,
      theme: FileyTheme.dark,
      home: const HomeScreen(),
    );
  }
}
