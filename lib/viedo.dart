import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutt/sensor_data.dart';

class DetailPage extends StatefulWidget {
  final SensorData sensorData_detail;
  const DetailPage({Key? key, required this.sensorData_detail})
      : super(key: key);

  @override
  State<DetailPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<DetailPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(
      'https://yzulab1.waziwazi.top/stream?token=123456',
    );

    _initializeVideoPlayerFuture = _controller.initialize();

    _controller.setLooping(true);

    // Add listener to update state and rebuild UI when playing
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細資料'), // 更改成影片頁面的標題
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3, //改變影片展示大小
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      double videoWidth = constraints.maxWidth;
                      double videoHeight = videoWidth * (3 / 4);
                      return SizedBox(
                        width: videoWidth,
                        height: videoHeight,
                        child: VideoPlayer(_controller),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.blue,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
