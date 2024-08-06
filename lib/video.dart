import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutt/sensor_data.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class DetailPage extends StatefulWidget {
  final SensorData sensorData_detail;
  const DetailPage({Key? key, required this.sensorData_detail})
      : super(key: key);
  @override
  State<DetailPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<DetailPage> {
  //late VideoPlayerController _controller;
  //late Future<void> _initializeVideoPlayerFuture;
  late SensorData _sensorData = SensorData.defaults();
  //late Timer _timer;

  bool _isDownloading = false;
  String _progress = '';
  String _filePath = '';
  VideoPlayerController? _controller;
  Timer? _downloadTimer;

  @override
  void initState() {
    // super.initState();
    // _sensorData.modify(widget.sensorData_detail);
    // _controller = VideoPlayerController.networkUrl(Uri.parse(
    //   'https://yzulab1.waziwazi.top/getlastVideo?terminal_id=0001&iot_id=101',
    // ));

    // _initializeVideoPlayerFuture = _controller.initialize().then((_) {
    //   // Ensure the first frame is shown after the video is initialized,
    //   // even before the play button has been pressed.
    //   Duration videoDuration = _controller.value.duration;
    //   int videoLengthInSeconds = videoDuration.inSeconds;
    //   print(videoLengthInSeconds);
    //   print("hello");
    //   setState(() {});
    // });

    // _controller.setLooping(true);
    // _timer = Timer.periodic(Duration(seconds: 14), (Timer timer) async {
    //   if (_controller.value.isPlaying) {
    //     await _controller.pause();
    //   }
    //   _controller = VideoPlayerController.networkUrl(Uri.parse(
    //     'https://yzulab1.waziwazi.top/getlastVideo?terminal_id=0001&iot_id=101',
    //   ));

    //   _initializeVideoPlayerFuture = _controller.initialize().then((_) {
    //     // Ensure the first frame is shown after the video is initialized,
    //     // even before the play button has been pressed.
    //     setState(() {});
    //   });
    //   _controller.setLooping(true);
    //   if (_controller.value.isPlaying) {
    //     _controller.pause();
    //   }
    //   _controller.setLooping(false);
    // });
    // // Add listener to update state and rebuild UI when playing
    // _controller.addListener(() {
    //   setState(() {});
    // });

    super.initState();
    // Start a timer to download the video every 14 seconds
    _downloadTimer = Timer.periodic(Duration(seconds: 14), (timer) {
      _downloadVideo(
          // 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'
          //'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4');
          'https://yzulab1.waziwazi.top/getlastVideo?terminal_id=0001&iot_id=101');
    });
  }

  Future<void> _downloadVideo(String url) async {
    if (_isDownloading) return; // Skip if already downloading

    setState(() {
      _isDownloading = true;
      _progress = '0%';
    });

    try {
      // Get application document directory
      final dir = await getApplicationDocumentsDirectory();

      // Set file path (overwriting existing file)
      final filePath = '${dir.path}/myVideo.mp4';

      // Download video
      var dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = '${(received / total * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      // Dispose of the previous controller if it exists
      _controller?.dispose();

      setState(() {
        _filePath = filePath;
        _progress = '下载完成';
      });

      // Initialize video player controller
      _controller = VideoPlayerController.file(File(_filePath))
        ..initialize().then((_) {
          setState(() {}); // Refresh UI when initialized
        });
    } catch (e) {
      setState(() {
        _progress = '下载失败: $e';
        print('下载失败: $e');
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  void dispose() {
    _downloadTimer?.cancel(); // Cancel timer
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('詳細資料'), // 更改成影片頁面的標題
        ),
        body: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(10), // 添加間距
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: Colors.blueGrey[700] ?? Colors.blue,
                      width: 2), // 添加邊框
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(top: 5), // 添加間距
                    child: Text(
                      _sensorData.events,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 5), // 添加間距
                      Text(
                        '位置: ${_sensorData.locations}\n'
                        '時間: ${_sensorData.updatetime}\n'
                        '事件等級: ${_sensorData.levels}\n'
                        '• 設備編號: ${_sensorData.iot_id}\n'
                        '• 煙霧參數: ${_sensorData.airQuality} (正常值: 10)\n'
                        '• 溫度參數: ${_sensorData.temperature}°C\n',
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // FutureBuilder(
            //   future: _initializeVideoPlayerFuture,
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.done) {
            //       return Column(
            //         children: [
            //           AspectRatio(
            //             aspectRatio: 4 / 3, //改變影片展示大小
            //             child: LayoutBuilder(
            //               builder: (BuildContext context,
            //                   BoxConstraints constraints) {
            //                 double videoWidth = constraints.maxWidth;
            //                 double videoHeight = videoWidth * (3 / 4);
            //                 return SizedBox(
            //                   width: videoWidth,
            //                   height: videoHeight,
            //                   child: VideoPlayer(_controller),
            //                 );
            //               },
            //             ),
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: VideoProgressIndicator(
            //               _controller,
            //               allowScrubbing: true,
            //               colors: const VideoProgressColors(
            //                 playedColor: Colors.blue,
            //                 bufferedColor: Colors.grey,
            //                 backgroundColor: Colors.black,
            //               ),
            //             ),
            //           ),
            //         ],
            //       );
            //     } else {
            //       return Center(
            //         child: CircularProgressIndicator(
            //           color: Colors.blue[400],
            //         ),
            //       );
            //     }
            //   },
            // ),
            // FloatingActionButton(
            //   backgroundColor: Colors.blue[400],
            //   onPressed: () {
            //     setState(() {
            //       if (_controller.value.isPlaying) {
            //         _controller.pause();
            //       } else {
            //         _controller.play();
            //       }
            //     });
            //   },
            //   child: Icon(
            //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            //   ),
            // ),
            _isDownloading ? CircularProgressIndicator() : Container(),
            _controller != null && _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: 4 / 3, // Fixed aspect ratio 4:3
                    child: VideoPlayer(_controller!),
                  )
                : Container(),
            // Display control buttons if the controller is initialized
            _controller != null && _controller!.value.isInitialized
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            _controller!.value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.replay),
                        onPressed: () {
                          setState(() {
                            _controller!.seekTo(Duration.zero);
                          });
                        },
                      ),
                    ],
                  )
                : Container(),
          ],
        ));
  }
}
