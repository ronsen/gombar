import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:gombar/gombar_app.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Check if a file path was passed as an argument
  String? initialPath;
  if (args.isNotEmpty) {
    initialPath = args[0];
  }

  runApp(GombarApp(initialPath: initialPath));
}
