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
  late SensorData _sensorData = SensorData.defaults();

  @override
  void initState() {
    super.initState();
    _sensorData.modify(widget.sensorData_detail);
    _controller = VideoPlayerController.network(
      'https://yzulab1.waziwazi.top/getlastVideo?terminal_id=0001&iot_id=101',
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
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3, //改變影片展示大小
                        child: LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
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
                          colors: const VideoProgressColors(
                            playedColor: Colors.blue,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue[400],
                    ),
                  );
                }
              },
            ),
            FloatingActionButton(
              backgroundColor: Colors.blue[400],
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
          ],
        ));
  }
}
