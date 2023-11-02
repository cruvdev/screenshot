import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:media_gallery2/media_gallery2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class ShowScreenshots extends StatefulWidget {
  const ShowScreenshots({super.key});

  @override
  State<ShowScreenshots> createState() => _ShowScreenshotsState();
}

class _ShowScreenshotsState extends State<ShowScreenshots> {
  List<File> listImagePath = [];
  List<Media> allMedias = [];
  late final List collection1;
  late Directory externalStorageDirs;
  var _permissionStatus1;
  var _permissionStatus2;
  // List<Files> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    collectio();
    _listenForPermissionStatus();
  }

  Future<void> collectio() async {
    collection1 = await MediaGallery.listMediaCollections(
      mediaTypes: [MediaType.image, MediaType.video],
    );
  }

  Future<void> fetchAndSortMedia() async {
    try {
      // Replace 'collection' with the actual MediaCollection you want to use
      MediaCollection collection = collection1.first;

      final MediaPage imagePage = await collection.getMedias(
        mediaType: MediaType.image,
        take: 10,
      );
      final MediaPage videoPage = await collection.getMedias(
        mediaType: MediaType.video,
        take: 10,
      );

      final List<Media> images = [
        ...imagePage.items,
        // ...videoPage.items,
      ]..sort((x, y) => y.creationDate.compareTo(x.creationDate));

      setState(() {
        allMedias = images;
      });

      // Now you have a sorted list of media items in 'allMedias'
      for (var media in allMedias) {
        print('Media Name: ${media.id}');
        print('Media Type: ${media.mediaType}');
        print('Creation Date: ${media.creationDate}');
        // You can access other properties of 'media' as needed
      }
    } catch (e) {
      print('Error fetching and sorting media: $e');
    }
  }

  Future<void> pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true, // Allow picking multiple images
      );

      if (result != null) {
        List<File> pickedFiles =
            result.paths.map((path) => File(path!)).toList();

        // Handle the picked image files (e.g., display, upload, or process them)
        for (File file in pickedFiles) {
          print("Picked image: ${file.path}");
        }
      } else {
        // User canceled the file picking
        print("User canceled the file picking.");
      }
    } catch (e) {
      // Handle any exceptions that occur during file picking
      print("Error picking images: $e");
    }
  }

  Future<void> givePath() async {
    // Directory? downloadsDirectory = await DownloadsPath.downloadsDirectory();
    String? downloadsDirectoryPath =
        (await DownloadsPath.downloadsDirectory())?.path;
    print(downloadsDirectoryPath);
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

      final path = Platform.isAndroid
          ? '/storage/emulated/0/Pictures/Screenshots'
          : Platform.isIOS
              ? ''
              : null;

      if (path == null) {
        throw Exception('Unsupported platform');
      }

      final Directory directory = Directory(path);

      final List<FileSystemEntity> entities = await directory.list().toList();
      final List<File> imageFiles = entities.whereType<File>().toList();

      if (imageFiles.isEmpty) {
        throw Exception('No images found in the directory.');
      }

      setState(() {
        listImagePath = imageFiles.take(10).toList();
      });
    } catch (e) {
      print('Error accessing the directory: $e');
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
              if (Platform.isAndroid) {
                _loadScreenshots();
              } else {
                fetchAndSortMedia();
                givePath();
              }
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
              itemCount:
                  Platform.isAndroid ? listImagePath.length : allMedias.length,
              itemBuilder: (context, index) {
                if (Platform.isIOS) {
                  final media = allMedias[index];
                  return FadeInImage(
                    fit: BoxFit.cover,
                    placeholder: MemoryImage(kTransparentImageBytes),
                    image: MediaImageProvider(
                      media: media,
                    ),
                  );
                } else {
                  final File file = listImagePath[index];
                  return Image.file(file, fit: BoxFit.cover);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
