import 'package:flutter/material.dart';
import 'package:gombar/image_viewer_page.dart';

class GombarApp extends StatelessWidget {
  final String? initialPath;
  const GombarApp({super.key, this.initialPath});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gombar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ImageViewerPage(initialPath: initialPath),
    );
  }
}
