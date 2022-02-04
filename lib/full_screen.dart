import 'dart:async';
import 'dart:io';
//import 'package:wakelock/wakelock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class FullScreenPlayer extends StatefulWidget {
  FullScreenPlayer({Key? key, required this.file}) : super(key: key);
  File file;
  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayer();
}

bool _isVisible = false;
bool paused = false;
int currentVolume = 50;
bool _isVolumeVisible = false;
bool _volumeIncreased = false;
bool _semtimer = false;
bool _semVolume = false;
bool _semSeek = false;
bool _forward = false;
bool _seekVisible = false;
TapDownDetails? _details;

class _FullScreenPlayer extends State<FullScreenPlayer> {
  VideoPlayerController? controller;
  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.file(widget.file)
      ..addListener(() => setState(() {}))
      ..initialize().then((_) {
        controller!.play();
        controller!.setVolume(currentVolume.toDouble() / 100);
        setState(() {});
      });
    setOrientation();
    _isVisible = false;
    paused = false;
    _isVolumeVisible = false;
    _volumeIncreased = false;
    _semtimer = false;
    _semVolume = false;
    _semSeek = false;
    _forward = false;
    _seekVisible = false;
  }

  @override
  void dispose() {
    controller!.dispose();
    resetOrientation();
    _isVisible = false;
    _isVolumeVisible = false;
    _seekVisible = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            GestureDetector(
              onDoubleTapDown: (details) {
                _details = details;
              },
              onDoubleTap: () {
                // Double tapped right side of screen
                if (_details!.globalPosition.dx >
                    (MediaQuery.of(context).size.width / 2)) {
                  setState(() {
                    Duration _currentPosition = controller!.value.position;
                    Duration _targerPosition =
                        _currentPosition + const Duration(seconds: 5);
                    controller!.seekTo(_targerPosition);
                    _isVisible = true;
                    _isVolumeVisible = false;
                    _forward = true;
                    _seekVisible = true;
                    seekHandler(this);
                    timeHandler(this);
                  });
                } else {
                  setState(() {
                    Duration _currentPosition = controller!.value.position;
                    Duration _targerPosition =
                        _currentPosition - const Duration(seconds: 5);
                    controller!.seekTo(_targerPosition);
                    _isVisible = true;
                    _isVolumeVisible = false;
                    _forward = false;
                    _seekVisible = true;
                    seekHandler(this);
                    timeHandler(this);
                  });
                }
              },
              onTap: () {
                if (!_isVisible) {
                  setState(() {
                    _isVisible = true;
                    _isVolumeVisible = false;
                    timeHandler(this);
                  });
                } else if (_isVisible) {
                  setState(() {
                    _isVisible = false;
                  });
                }
              },
              onVerticalDragUpdate: (details) {
                // Swiping in upwards direction.
                if (details.delta.dy < 0) {
                  setState(() {
                    _isVolumeVisible = true;
                    _isVisible = false;
                    if (currentVolume < 100) {
                      currentVolume += 1;
                      controller!.setVolume(currentVolume.toDouble() / 100);
                    }
                    _volumeIncreased = true;
                    volumeHandler(this);
                  });
                }

                // Swiping in downwards direction.
                if (details.delta.dy > 0) {
                  setState(() {
                    _isVolumeVisible = true;
                    _isVisible = false;
                    if (currentVolume > 0) {
                      currentVolume -= 1;
                      controller!.setVolume(currentVolume.toDouble() / 100);
                    }
                    _volumeIncreased = false;
                    volumeHandler(this);
                  });
                }
              },
              child: controller != null && controller!.value.isInitialized
                  ? customFullScreen(
                      child: AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: VideoPlayer(controller!)),
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: !_isVisible
                    ? const SizedBox()
                    : Card(
                        child: controller!.value.isPlaying
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller!.pause();
                                    paused = true;
                                    _isVisible = true;
                                  });
                                },
                                icon: const Icon(Icons.pause),
                                color: Colors.white,
                              )
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller!.play();
                                    paused = false;
                                    _isVisible = false;
                                  });
                                },
                                icon: const Icon(Icons.play_arrow),
                                color: Colors.white,
                              ),
                      ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: !_isVolumeVisible
                        ? const SizedBox()
                        : _volumeIncreased
                            ? const Card(child: Icon(Icons.volume_up))
                            : controller!.value.volume == 0.0
                                ? const Card(child: Icon(Icons.volume_mute))
                                : const Card(child: Icon(Icons.volume_down)),
                  ),
                  !_isVolumeVisible
                      ? const SizedBox()
                      : TextButton(
                          onPressed: () {
                            setState(() {});
                          },
                          style: TextButton.styleFrom(
                              primary: Colors.lightBlueAccent),
                          child: Text("$currentVolume%"))
                ],
              ),
            ),
            Align(
              alignment:
                  _forward ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: !_seekVisible
                    ? const SizedBox()
                    : _forward
                        ? const Card(child: Icon(Icons.fast_forward))
                        : const Card(child: Icon(Icons.fast_rewind)),
              ),
            ),
            Positioned(
                bottom: 45,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: !_isVisible
                      ? const SizedBox()
                      : Text(getPosition(),
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontStyle: FontStyle.normal,
                              decoration: TextDecoration.none)),
                )),
            Positioned(
              bottom: 55,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: !_isVisible
                    ? const SizedBox()
                    : Row(
                        children: [Expanded(child: videoIndicator)],
                      ),
              ),
            )
          ]),
        ),
      ],
    );
  }

  Widget customFullScreen({
    @required Widget? child,
  }) {
    final size = controller!.value.size;
    final width = size.width;
    final height = size.height;

    return Center(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  Future setOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    //await Wakelock.enable();
  }

  Future resetOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    //await Wakelock.disable();
  }

  Widget get videoIndicator {
    return Container(
        margin: const EdgeInsets.all(8),
        height: 16,
        child: VideoProgressIndicator(controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
                bufferedColor: Color.fromRGBO(255, 255, 255, 0.1),
                playedColor: Color.fromRGBO(0, 0, 255, 0.4))));
  }

  void timeHandler(_FullScreenPlayer _fullScreenPlayer) {
    if (!_semtimer) {
      if (!paused && (_isVolumeVisible || _isVisible)) {
        _semtimer = true;
        Timer(const Duration(seconds: 5), () {
          //asynchronous delay
          if (!paused && _fullScreenPlayer.mounted) {
            //checks if widget is still active and not disposed
            //tells the widget builder to rebuild again because ui has updated
            _isVisible =
                false; //update the variable declare this under your class so its accessible for both your widget build and initState which is located under widget build{}
            _isVolumeVisible = false;

            _fullScreenPlayer.setState(() {});
          }
          _semtimer = false;
          setOrientation();
        });
      }
    }
  }

  void volumeHandler(_FullScreenPlayer _fullScreenPlayer) {
    if (!_semVolume) {
      if (_isVolumeVisible) {
        _semVolume = true;
        Timer(const Duration(seconds: 2), () {
          //asynchronous delay
          if (_fullScreenPlayer.mounted) {
            //checks if widget is still active and not disposed
            //tells the widget builder to rebuild again because ui has updated
            _isVolumeVisible = false;
            _fullScreenPlayer.setState(() {});
          }
          _semVolume = false;
        });
      }
    }
  }

  void seekHandler(_FullScreenPlayer _fullScreenPlayer) {
    if (!_semSeek) {
      if (_seekVisible) {
        _semSeek = true;
        Timer(const Duration(seconds: 2), () {
          //asynchronous delay
          if (_fullScreenPlayer.mounted) {
            //checks if widget is still active and not disposed
            //tells the widget builder to rebuild again because ui has updated
            _seekVisible = false;
            _fullScreenPlayer.setState(() {});
          }
          _semSeek = false;
        });
      }
    }
  }

  String getPosition() {
    final duration = Duration(
        milliseconds: controller!.value.position.inMilliseconds.round());
    return [duration.inHours, duration.inMinutes, duration.inSeconds]
        .map((e) => e.remainder(60).toString().padLeft(2, '0'))
        .join(':');
  }
}
