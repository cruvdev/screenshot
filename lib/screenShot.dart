import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ShowScreenshots extends StatefulWidget {
  const ShowScreenshots({super.key});

  @override
  State<ShowScreenshots> createState() => _ShowScreenshotsState();
}

class _ShowScreenshotsState extends State<ShowScreenshots> {
  List<File> listImagePath = [];
  var _permissionStatus1;
  var _permissionStatus2;

  @override
  void initState() {
    super.initState();
    _listenForPermissionStatus();
  }

  Future<void> _listenForPermissionStatus() async {
    final status1 = await Permission.photos.status;
    final status2 = await Permission.storage.status;
    setState(() {
      _permissionStatus1 = status1;
      _permissionStatus2 = status2;
    });
  }

  Future<void> _requestPermission() async {
    final status1 = await Permission.photos.request();
    final status2 = await Permission.storage.request();

    setState(() {
      _permissionStatus1 = status1;
      _permissionStatus2 = status2;
    });
  }

  Future<void> _loadScreenshots() async {
    try {
      if (_permissionStatus1 != PermissionStatus.granted ||
          _permissionStatus2 != PermissionStatus.granted) {
        await _requestPermission();
      }

      final path = '/storage/emulated/0/DCIM/Screenshots';
      final Directory directory = Directory(path);
      final List<FileSystemEntity> entities = await directory.list().toList();
      final List<File> imageFiles = entities.whereType<File>().toList();

      if (imageFiles.isEmpty) {
        throw Exception('No images found in the first directory.');
      }

      setState(() {
        listImagePath = imageFiles.take(10).toList();
      });
    } catch (e) {
      print('Error accessing the first directory: $e');

      final fallbackPath = '/storage/emulated/0/Pictures/Screenshots';
      final fallbackDirectory = Directory(fallbackPath);
      final List<FileSystemEntity> fallbackEntities =
          await fallbackDirectory.list().toList();
      final List<File> fallbackImageFiles =
          fallbackEntities.whereType<File>().toList();

      if (fallbackImageFiles.isEmpty) {
        throw Exception('No images found in the fallback directory.');
      }

      setState(() {
        listImagePath = fallbackImageFiles.take(10).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Show Screenshots'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _loadScreenshots();
            },
            child: const Text('Load Screenshots'),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns in the grid
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: listImagePath.length,
              itemBuilder: (context, index) {
                final File file = listImagePath[index];
                return Image.file(file, fit: BoxFit.cover);
              },
            ),
          ),
        ],
      ),
    );
  }
}
