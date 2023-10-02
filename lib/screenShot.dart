import 'package:flutter/material.dart';
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ShowScreenshots extends StatefulWidget {
  const ShowScreenshots({super.key});

  @override
  State<ShowScreenshots> createState() => _ShowScreenshotsState();
}

class _ShowScreenshotsState extends State<ShowScreenshots> {
  List<File> listImagePath = [];
  var _permissionStatus;

  @override
  void initState() {
    super.initState();
    _listenForPermissionStatus();
  }

  Future<void> _listenForPermissionStatus() async {
    final status = await Permission.storage.status;
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.storage.request();
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> _loadScreenshots() async {
    if (_permissionStatus != PermissionStatus.granted) {
      await _requestPermission();
    }

    final path = '/storage/emulated/0/DCIM/Screenshots';
    final Directory directory = Directory(path);
    final List<FileSystemEntity> entities = await directory.list().toList();
    final List<File> imageFiles = entities.whereType<File>().toList();

    if (imageFiles.isEmpty) {
      final fallbackPath = '/storage/emulated/0/Pictures/Screenshots';
      final fallbackDirectory = Directory(fallbackPath);
      final List<FileSystemEntity> fallbackEntities =
          await fallbackDirectory.list().toList();
      final List<File> fallbackImageFiles =
          fallbackEntities.whereType<File>().toList();
      setState(() {
        listImagePath = fallbackImageFiles.take(10).toList();
      });
    } else {
      setState(() {
        listImagePath = imageFiles.take(10).toList();
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
