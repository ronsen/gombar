import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageViewerPage extends StatefulWidget {
  final String? initialPath;
  const ImageViewerPage({super.key, this.initialPath});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  List<File> _images = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isFullScreen = false;
  late PageController _pageController;

  final List<String> _supportedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Load initial path if provided
    if (widget.initialPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromPath(widget.initialPath!);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFullScreen() async {
    bool isFullScreen = await windowManager.isFullScreen();
    if (isFullScreen) {
      await windowManager.setFullScreen(false);
      setState(() => _isFullScreen = false);
    } else {
      await windowManager.setFullScreen(true);
      setState(() => _isFullScreen = true);
    }
  }

  Future<void> _updateTitle() async {
    final title = _images.isEmpty
        ? 'Gombar'
        : p.basename(_images[_currentIndex].path);
    await windowManager.setTitle(title);
  }

  Future<void> _loadFromPath(String selectedFilePath) async {
    setState(() => _isLoading = true);
    try {
      final file = File(selectedFilePath);
      if (!await file.exists()) return;

      final directory = Directory(p.dirname(selectedFilePath));
      final List<FileSystemEntity> entities = await directory.list().toList();

      List<File> imageFiles = entities
          .whereType<File>()
          .where(
            (f) => _supportedExtensions.contains(
              p.extension(f.path).toLowerCase(),
            ),
          )
          .toList();

      imageFiles.sort(
        (a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()),
      );

      final selectedIndex = imageFiles.indexWhere(
        (f) => f.path == selectedFilePath,
      );

      setState(() {
        _images = imageFiles;
        _currentIndex = selectedIndex != -1 ? selectedIndex : 0;
      });

      _updateTitle();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading directory: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final extensions = _supportedExtensions
        .map((e) => e.replaceAll('.', ''))
        .toList();
    final allExtensions = [
      ...extensions,
      ...extensions.map((e) => e.toUpperCase()),
    ];

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allExtensions,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      _loadFromPath(result.files.single.path!);
    }
  }

  void _nextImage() {
    if (_images.isNotEmpty) {
      if (_currentIndex < _images.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousImage() {
    if (_images.isNotEmpty) {
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          _images.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final isControlPressed =
                HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;

            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nextImage();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _previousImage();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.f11) {
              _toggleFullScreen();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyO &&
                isControlPressed) {
              _pickImages();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (_isFullScreen) {
                _toggleFullScreen();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _images.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImages,
                      child: const Text('Open an Image (Ctrl+O)'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://github.com/ronsen/gombar'),
                      ),
                      child: const Text(
                        'Website',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                      _updateTitle();
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        key: ValueKey(_images[index].path),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.file(
                          _images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                        ),
                      );
                    },
                  ),

                  if (!_isFullScreen) ...[
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            iconSize: 48,
                            icon: const Icon(Icons.chevron_left),
                            color: Colors.white70,
                            onPressed: _previousImage,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            iconSize: 48,
                            icon: const Icon(Icons.chevron_right),
                            color: Colors.white70,
                            onPressed: _nextImage,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${_images.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
