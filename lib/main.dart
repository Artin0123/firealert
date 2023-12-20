import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String jsonData = ''; // 用於顯示 JSON 資料的文字
  String updatetime = '';
  String isAlert = ''; // 新增一個用於存儲 isAlert 的變量
  String events = '';
  String levels = '';
  String locations = '';
  String timestamps = '';
  String airqualitys = '';
  String temperatures = '';
  int _counter = 0;
  String apiUrl = 'http://192.168.0.13/apis/index.php';
  String accessCode = '';
  Uint8List? imageData;
  Future<Map<String, dynamic>> fetchData() async {
    final url = Uri.http('140.138.150.29:38080', 'service/alertAPI/'); // 將你的網址替換成實際的 URL
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // 如果服務器返回一個 OK 響應，則解析 JSON。
        Map<String, dynamic> jsonData = jsonDecode(response.body);

        // 使用鍵來訪問對應的值
        updatetime = jsonData['0_update_stamp'];
        isAlert = jsonData['alert'].toString();
        List<dynamic> details = jsonData['details'];
        for (var detail in details) {
          events = detail['event'];
          levels = detail['level'].toString();
          locations = detail['location'];
          timestamps = detail['time_stamp'];
          Map<String, dynamic> sensors = detail['sensors'];
          airqualitys = sensors['air_quality'].toStringAsFixed(2);
          temperatures = sensors['temperature'].toStringAsFixed(2);

          //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

          List<dynamic> captureImage = detail['capture_media'];
          String captureMediaJson = captureImage[0];
          getImage(captureMediaJson);
          //String request = "http://192.168.0.13/apis/index.php";
          //String buffer = "access_code=$captureMediaJson";
          //Uri image_url = Uri.parse(request);
        }
        return jsonData; // 返回解析後的 JSON 數據
      } else {
        // 如果服務器返回一個不是 OK 的響應，則拋出一個異常。
        throw Exception('Key "0_update_stamp" not found in the JSON data');
      }
    } catch (e) {
      throw Exception('Error during HTTP request: $e');
    }
  }

  Future<void> getImage(String buffer) async {
    accessCode = buffer;
    Map<String, String> payload = {'access_code': accessCode};

    // Encode the payload to x-www-form-urlencoded format
    //String encodedPayload = Uri.encodeQueryComponent(payload.toString());

    // Make the HTTP POST request
    http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: payload,
    );

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // Check if the content type is 'image/jpeg'
      if (response.headers['content-type'] == 'image/jpeg') {
        // Decode the response body as Uint8List (bytes)
        setState(() {
          imageData = response.bodyBytes;
        });
      } else {
        debugPrint('Unexpected content type: ${response.headers['content-type']}');
      }
    } else {
      debugPrint('HTTP request failed with status: $response');
      debugPrint('Response body: ${response.body}');
    }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              height: 16,
            ),
            ElevatedButton(
              onPressed: () async {
                await fetchData();
                setState(() {}); // 更新狀態
              },
              child: const Text('取得資料'),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text('上次警報更新時間: $updatetime\n是否有警報: $isAlert', textAlign: TextAlign.left),
              // Text(''),
              // Text('事件種類: $events'),
              // Text('事件等級: $levels'),
              // Text('感測器位置: $locations'),
              // Text('事件時間: $timestamps'),
              // Text('氣體數值: $airqualitys'),
              // Text('溫度: $temperatures'),
            ),
            Container(
              constraints: BoxConstraints(
                minHeight: 40, //minimum height
                minWidth: 160, // minimum width

                maxHeight: MediaQuery.of(context).size.height,
                //maximum height set to 100% of vertical height

                maxWidth: MediaQuery.of(context).size.width,
                //maximum width set to 100% of width
              ),
              child: ElevatedButton(
                onPressed: _incrementCounter,
                child: const Text("normal"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // 当按钮按下时，跳转到新页面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondPage()),
                );
              },
              child: const Text('打開新頁面'),
            ),
            Container(
              child: imageData != null
                  ? Image.memory(
                      imageData!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                  : const CircularProgressIndicator(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Text('这是第二个页面'),
      ),
    );
  }
}
