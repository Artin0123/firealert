import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutt/sensor_data.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutt/local.dart';
import 'package:flutter_localization/flutter_localization.dart';

final FlutterLocalization localization = FlutterLocalization.instance;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class DetailPage extends StatefulWidget {
  final SensorData sensorData_detail;
  const DetailPage({Key? key, required this.sensorData_detail}) : super(key: key);
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
    super.initState();
    _sensorData.modify(widget.sensorData_detail);
    _startDownloadAndTimer();
    // localization.init(
    //   mapLocales: [
    //     MapLocale('en', AppLocale.EN),
    //     MapLocale('zh_TW', AppLocale.ZH_TW),
    //   ],
    //   initLanguageCode: 'zh_TW',
    // );
    // localization.onTranslatedLanguage = _onTranslatedLanguage;
  }

  void _startDownloadAndTimer() async {
    // Start immediate download
    await _downloadVideo('https://yzulab1.waziwazi.top/getlastVideo?terminal_id=0001&iot_id=101');

    // Start periodic download every 14 seconds
    _downloadTimer = Timer.periodic(Duration(seconds: 14), (timer) {
      _downloadVideo('https://yzulab1.waziwazi.top/getlastVideo?terminal_id=0001&iot_id=101');
    });
  }

  Future<void> _downloadVideo(String url) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = '0%';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/myVideo.mp4';

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

      _controller?.dispose();

      setState(() {
        _filePath = filePath;
        _progress = '下载完成';
      });

      _controller = VideoPlayerController.file(File(_filePath))
        ..initialize().then((_) {
          setState(() {});
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

  // void _onTranslatedLanguage(Locale? locale) {
  // setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.blue[400],
            title: Text(AppLocale.titles[7].getString(context), style: TextStyle(color: Colors.grey[50], fontSize: 28, fontWeight: FontWeight.bold)),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3.0),
              child: Container(
                color: Colors.blue[700],
                height: 3.0,
              ),
            )),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(10), // 添加間距
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.blueGrey[700] ?? Colors.blue, width: 2), // 添加邊框
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(top: 5), // 添加間距
                    child: Text(
                      _sensorData.events,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 5), // 添加間距
                      Text(
                        AppLocale.args[2].getString(context) +
                            _sensorData.locations +
                            '\n' +
                            AppLocale.args[18].getString(context) +
                            _sensorData.updatetime +
                            '\n' +
                            AppLocale.args[19].getString(context) +
                            _sensorData.levels +
                            '\n' +
                            AppLocale.args[3].getString(context) +
                            _sensorData.iot_id +
                            '\n' +
                            AppLocale.args[1].getString(context) +
                            _sensorData.airQuality.toString() +
                            ' (' +
                            AppLocale.info[3].getString(context) +
                            ': 10)\n' +
                            AppLocale.args[0].getString(context) +
                            _sensorData.temperature.toString() +
                            '°C',
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
                        icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
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
        )));
  }
}
