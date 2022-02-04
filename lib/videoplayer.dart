import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'full_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

final Directory _videoDir = Directory('/storage/emulated/0/Download');

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({Key? key}) : super(key: key);

  @override
  VvideoPlayerState createState() => VvideoPlayerState();
}

class VvideoPlayerState extends State<MyVideoPlayer> {
  late PermissionStatus status = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    getPermission().then((value) {
      setState(() {
        status = value;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return customVideoPlayer(status);
  }

  Widget customVideoPlayer(PermissionStatus status) {
    if (!status.isGranted) {
      return Center(
          child: TextButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text("Storage Permission Required")));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
        actions: [
          IconButton(
              onPressed: () async {
                final file = await pickVideoFile();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullScreenPlayer(file: file)));
              },
              icon: const Icon(Icons.video_collection))
        ],
      ),
      body: showVideos(),
    );
  }

  Future<File> pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    // ignore: null_check_always_fails
    if (result == null) return null!;

    return File(result.files.single.path!);
  }

  Widget showVideos() {
    // ignore: unnecessary_string_interpolations
    if (!Directory("${_videoDir.path}").existsSync()) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(
            child: Text(
              'Directory not found',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ],
      );
    } else {
      final videoList = _videoDir
          .listSync(recursive: true)
          .map((item) => item.path)
          .where((item) => item.endsWith('.mp4') /* || item.endsWith('.flv') */)
          .toList(growable: false);
      // ignore: unnecessary_null_comparison
      if (videoList != null) {
        // ignore: prefer_is_empty
        if (videoList.length > 0) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ListView.builder(
              itemCount: videoList.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    var myFile = File(videoList[index]);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenPlayer(
                          file: myFile,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Stack(
                      children: [
                        Center(
                          child: FutureBuilder(
                              future: _getImage(videoList[index]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  if (snapshot.hasData) {
                                    return Center(
                                      child: Hero(
                                        tag: videoList[index],
                                        child: Image.file(
                                          File(snapshot.data.toString()),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                } else {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                              }),
                        ),
                        Positioned(
                            top: 85,
                            left: MediaQuery.of(context).size.width / 2.4,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline_outlined,
                                size: 45,
                                color: Colors.white,
                              ),
                            ))
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return const Center(
            child: Text(
              'Sorry, No Videos Found.',
              style: TextStyle(fontSize: 18.0),
            ),
          );
        }
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    }
  }

  _getImage(videoPathUrl) async {
    //await Future.delayed(const Duration(milliseconds: 50));
    var directory = await getApplicationDocumentsDirectory();
    var path = directory.path;
    path = path + "/";

    String? thumb = await VideoThumbnail.thumbnailFile(
        thumbnailPath: path,
        video: videoPathUrl,
        imageFormat: ImageFormat.PNG,
        maxWidth: MediaQuery.of(context).size.width.toInt(),
        maxHeight: 200);
    return thumb;
  }

  Future<PermissionStatus> getPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status;
  }
}
