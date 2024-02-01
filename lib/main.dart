import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => WebSocketService(),
        ),
        // 添加更多的 providers，每个对应一个不同的 WebSocket 连接
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppDataProvider(),
      child: MaterialApp(
        title: '火燒報哩災',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
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
  int currentIndex = 0;

  // 定义底部导航栏中的每个页面
  final List<Widget> pages = [
    const PageOne(),
    const PageTwo(),
    const PageThree(),
  ];

  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();

    // 初始化本地通知插件
    // var initializationSettingsAndroid =
    //     const AndroidInitializationSettings('app_icon');
    // var initializationSettingsIOS = const DarwinInitializationSettings();
    // var initializationSettings = InitializationSettings(
    //     android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    // flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
        backgroundColor: const Color.fromARGB(255, 90, 155, 213),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('火災事件列表',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '事件',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '設備',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class AppDataProvider extends ChangeNotifier {
  //共用記憶體
  final StreamController<bool> _updateNotificationController =
      StreamController<bool>();

  bool _selection = true;
  bool get selection => _selection;

  Stream<bool> get updateNotificationStream =>
      _updateNotificationController.stream;

  void setNotification(bool newValue) {
    _selection = newValue;
    con_notify = newValue;
    // 如果你想往 Stream 中添加新的值，使用 add 方法
    _updateNotificationController.add(_selection);
    notifyListeners();
  }

  void sendNotification() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    // await flutterLocalNotificationsPlugin.show(
    //   0,
    //   '設備異常通知',
    //   '溫度感器異常!',
    //   platformChannelSpecifics,
    //   payload: 'item x',
    // );
  }

  @override
  void dispose() {
    _updateNotificationController.close();
    super.dispose();
  }
}

class PageOne extends StatefulWidget {
  const PageOne({super.key});
  @override
  State<PageOne> createState() => _Pageone();
}

String jsonData = ''; // 用於顯示 JSON 資料的文字
String updatetime = '';
String isAlert = ''; // 新增一個用於存儲 isAlert 的變量
String events = '';
String levels = '';
String locations = '';
String timestamps = '';
String airqualitys = '45.2356';
String temperatures = '78.2356';
String normal = 'yes';
// int _counter = 0;
String apiUrl = 'http://140.138.150.29:38083/apis/index.php';
String accessCode = '';
Uint8List? imageData;
bool _selected = false;
bool con_notify = true;
String captureMediaJson = '';
Future<Map<String, dynamic>> fetchData() async {
  final url = Uri.http('140.138.150.29:38080',
      'service/alertAPI/'); // 將你的網址替換成實際的 URL http://140.138.150.29:38080/service/alertAPI/
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
        captureMediaJson = captureImage[0];

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
    // 如果發生錯誤，則拋出一個異常。
    throw Exception(e.toString());
  }
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class WebSocketService with ChangeNotifier {
  late IOWebSocketChannel _channel;
  String _connectionStatus = 'Disconnected';
  late StreamController<String> _messageController;

  WebSocketService() {
    _messageController = StreamController<String>.broadcast();
    _connectToWebSocket();
  }
  Stream<String> get messageStream => _messageController.stream;
  void _connectToWebSocket() {
    _channel = IOWebSocketChannel.connect('ws://59.102.142.103:9988');
    _channel.stream.listen(
      (message) {
        var data = json.decode(message.toString());
        if (data['status'] == 'success') {
          _connectionStatus = 'Connected';
          print('Connection established successfully');
          print(message);
        } else {
          _connectionStatus = 'Disconnected';
          print(message);
        }
        _messageController.add(message);
        notifyListeners();
      },
      onDone: () {
        _connectionStatus = 'Disconnected';
        notifyListeners();
      },
      onError: (error) {
        _connectionStatus = 'Disconnected';
        notifyListeners();
      },
    );
  }

  String get connectionStatus => _connectionStatus;

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageController.close();
    super.dispose();
  }
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class _Pageone extends State<PageOne> {
  //inal channel = IOWebSocketChannel.connect('ws://59.102.142.103:9988');

  void initState() {
    super.initState();
    //_streamController = StreamController<String>();
    //var data;
    // Flutter收到连接成功后，期望先收到状态消息

    // 监听来自服务器的消息
    // channel.stream.listen((message) {
    //   _streamController.add(message);
    // });
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
          //有問題
          imageData = response.bodyBytes;
        });
      } else {
        debugPrint(
            'Unexpected content type: ${response.headers['content-type']}');
      }
    } else {
      debugPrint('HTTP request failed with status: $response');
      debugPrint('Response body: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    var _streamController =
        Provider.of<WebSocketService>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color.fromARGB(240, 255, 255, 245),
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      body: SingleChildScrollView(
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
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Text(
              //   '$_counter',
              //   style: Theme.of(context).textTheme.headlineMedium,
              // ),
              Card(
                  elevation: 6,
                  margin: const EdgeInsets.all(16),
                  color: const Color.fromARGB(255, 253, 208, 223),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(
                      color: Color.fromARGB(248, 237, 127, 167),
                      width: 2.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('火災',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Text(
                              '位置: $locations\n時間: $timestamps\n上次警報更新時間: $updatetime\n是否有警報: $isAlert\n事件種類: $events\n事件等級: $levels\n氣體數值: $airqualitys\n溫度: $temperatures',
                              textAlign: TextAlign.left),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // 当按钮按下时，跳转到新页面
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SecondPage()),
                              );
                            },
                            child: const Text('查看詳情'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              launchPhone('119');
                            },
                            style: ElevatedButton.styleFrom(
                              primary:
                                  Colors.red, // Set the background color to red
                            ),
                            child: const Text(
                              '通報119',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  )),
              ElevatedButton(
                onPressed: () async {
                  if (_selected == false) {
                    await fetchData();
                    getImage(captureMediaJson);
                    setState(() {}); // 更新狀態
                  }
                },
                child: const Text('取得資料'),
              ),

              const SizedBox(height: 24),
              StreamBuilder<String>(
                stream:
                    _streamController.messageStream, // 使用 WebSocketService 的消息流
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('WebSocket 1 Message: ${snapshot.data}');
                  } else {
                    return Text('No WebSocket 1 Message');
                  }
                },
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
              ),
              Consumer<AppDataProvider>(
                builder: (context, appDataProvider, child) {
                  bool? counter1 = appDataProvider.selection;
                  return Text(
                    '通知: ${counter1 ?? 0}',
                    style: const TextStyle(fontSize: 24),
                  );
                },
              ),
            ]),
      ),
    );
  }
}

void launchPhone(String Phonenumber) async {
  String url = 'tel:$Phonenumber';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class PageTwo extends StatefulWidget {
  const PageTwo({super.key});
  @override
  State<PageTwo> createState() => _Pagetwo();
}

class SensorData {
  String airQuality;
  String temperature;
  String id;
  String normals;
  SensorData(this.airQuality, this.temperature, this.id, this.normals);
}

class _Pagetwo extends State<PageTwo> {
  List<SensorData> items = [];
  TextEditingController searchController = TextEditingController();
  var buffer = {};

  // void updateList() async {
  //   // Fetch data and update the list
  //   // Map<String, dynamic> newData = await fetchData();

  //   setState(() {
  //     // items = newData;
  //     // items.add(SensorData(airqualitys, temperatures, '123', normal));
  //     // items.add(SensorData(airqualitys, temperatures, '456', 'no'));
  //     // buffer['123'] = SensorData(airqualitys, temperatures, '123', normal);
  //     // buffer['456'] = SensorData(airqualitys, temperatures, '456', 'no');
  //   });
  // }

  void filterItems(String query) {
    // Filter items based on the search query
    setState(() {
      items = items
          .where((item) =>
              item.airQuality.toLowerCase().contains(query.toLowerCase()) ||
              item.temperature.toLowerCase().contains(query.toLowerCase()) ||
              item.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    buffer['123'] =
        SensorData(airqualitys, temperatures, '123', 'yes'); // 先預設值，預設key
    buffer['456'] = SensorData(airqualitys, temperatures, '456', 'no');
    Color num1;
    Color num2 = Color.fromARGB(248, 237, 127, 167);
    List<Color> cardColors = [
      Color.fromARGB(255, 253, 208, 223),
      Color.fromARGB(248, 237, 127, 167),
      Colors.white,
      Color.fromARGB(255, 90, 155, 213)
    ];
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onTap: () async {
            final query = await showSearch(
              context: context,
              delegate: SearchBarDelegate(buffer),
            );
            if (query != null) {
              filterItems(query);
            }
          },
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: buffer.length,
        itemBuilder: (context, index) {
          String key = buffer.keys.elementAt(index);
          SensorData sensorData = buffer[key];
          String sensorTitle = '';
          if (sensorData.normals == 'yes') {
            sensorTitle = '感測異常';
            num1 = cardColors[0];
            num2 = cardColors[1];
          } else {
            sensorTitle = '正常';
            num1 = cardColors[2];
            num2 = cardColors[3];
          }

          return Card(
            elevation: 6,
            margin: const EdgeInsets.all(16),
            color: num1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: num2,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensorTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '感測器 id: ${sensorData.id}\n溫度參數: ${sensorData.temperature}\n煙霧參數${sensorData.airQuality}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchBarDelegate extends SearchDelegate {
  var dic = {};
  List<SensorData> result = [];
  SearchBarDelegate(this.dic);
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      )
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    List<SensorData> buffer = [];
    if (result.isNotEmpty) {
      buffer.add(result[0]);
      result.clear();
    }

    Color num1;
    Color num2;
    if (buffer.isNotEmpty) {
      return ListView.builder(
        itemCount: buffer.length,
        itemBuilder: (context, index) {
          //String key = buffer.keys.elementAt(index);
          SensorData sensorData = buffer[0];
          String sensorTitle = '';
          if (sensorData.normals == 'yes') {
            sensorTitle = '感測異常';
            num1 = Color.fromARGB(255, 253, 208, 223);
            num2 = Color.fromARGB(248, 237, 127, 167);
          } else {
            sensorTitle = '正常';
            num1 = Colors.white;
            num2 = Color.fromARGB(255, 90, 155, 213);
          }

          return Card(
            elevation: 6,
            margin: const EdgeInsets.all(16),
            color: num1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: num2,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensorTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '感測器 id: ${sensorData.id}\n溫度參數: ${sensorData.temperature}\n煙霧參數${sensorData.airQuality}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return Text('No search results');
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    //for(var brand in search)
    List<dynamic> matchingSensorData = [];
    if (query.isNotEmpty) {
      // Convert query to lowercase for case-insensitive matching
      String lowerCaseQuery = query.toLowerCase();

      matchingSensorData = dic.entries
          .where((entry) {
            String key = entry.key.toString().toLowerCase();
            SensorData value = entry.value;

            // Check if the key or any property of SensorData contains the query
            return key.contains(lowerCaseQuery) ||
                value.temperature.toLowerCase().contains(lowerCaseQuery) ||
                value.airQuality.toLowerCase().contains(lowerCaseQuery) ||
                value.id.toLowerCase().contains(lowerCaseQuery);
          })
          .map((entry) => entry.value)
          .toList();
    }
    // return ListView(
    //   children: dic.entries.map((MapEntry<dynamic, dynamic> entry) {
    //     String key = entry.key.toString();
    //     SensorData value = entry.value;

    //     return ListTile(
    //       title: Text('id $key: ${value.temperature}'),
    //       onTap: () {
    //         query = '$key ${value.temperature}';
    //         result.add(value);
    //         showResults(context);
    //       },
    //     );
    //   }).toList(),
    // );
    return ListView(
      children: matchingSensorData.map((sensorData) {
        String key = dic.entries
                .firstWhere(
                  (entry) => entry.value == sensorData,
                  orElse: () => MapEntry(null, null),
                )
                ?.key
                ?.toString() ??
            '';

        return ListTile(
          title: Text('id $key: ${sensorData.temperature}'),
          onTap: () {
            query = '$key ${sensorData.temperature}';
            result.add(sensorData);
            showResults(context);
          },
        );
      }).toList(),
    );
  }
}

class PageThree extends StatefulWidget {
  const PageThree({super.key});
  @override
  State<PageThree> createState() => _Pagethree();
}

void startDataPolling() {
  const Duration pollInterval = Duration(seconds: 3);
  Timer periodicTimer = Timer.periodic(pollInterval, (Timer t) {
    // 发送数据请求到服务器
    fetchData();
  });
}

class _Pagethree extends State<PageThree> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        ListTile(
            onTap: () {
              setState(() {
                // This is called when the user toggles the switch.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NextPage()),
                );
              });
            },
            leading: const Icon(Icons.person),
            title: const Text('登入')),
        ListTile(
          selected: _selected,
          onTap: () {
            setState(() {
              // This is called when the user toggles the switch.
              _selected = !_selected; //true 自動更新
              //自動更新
            });
          },
          // This sets text color and icon color to red when list tile is disabled and
          // green when list tile is selected, otherwise sets it to black.
          iconColor:
              MaterialStateColor.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.green;
            }
            return Colors.black;
          }),
          leading: const Icon(Icons.person),
          title: const Text('Headline'),
          subtitle: Text('Enabled: , Selected: $_selected'),
          trailing: Switch(
            onChanged: (bool? value) {
              // This is called when the user toggles the switch.
              setState(() {
                _selected = value!;
                startDataPolling();
              });
            },
            value: _selected,
          ),
        ),
        ListTile(
            leading: const Icon(Icons.access_alarm),
            title: const Text(
              "設備通知",
              //style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: const Text("設備通知是否開啟"),
            trailing: Consumer<AppDataProvider>(
              builder: (context, appDataProvider, child) {
                return Switch(
                  value: Provider.of<AppDataProvider>(context)._selection,
                  onChanged: (bool value) {
                    Provider.of<AppDataProvider>(context, listen: false)
                        .setNotification(value);
                    print('Noti: $value');
                    print(
                        'Noti Provider: ${Provider.of<AppDataProvider>(context, listen: false)._selection}');
                  },
                );
              },
            )),
      ],
    ));
  }
}

class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登入'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  labelText: "使用者名稱 ",
                  //hintText: "使用者名稱",
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: Icon(Icons.remove_red_eye),
                  labelText: "密碼 ",
                  //hintText: "最好6個字",
                ),
              ),
            ),
            const SizedBox(
              height: 52.0,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 1000.0,
              height: 70.0,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(
                          255, 164, 199, 228)), // Change to your desired color
                ),
                child: const Text("登入", style: TextStyle(fontSize: 20)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// class _NextPage extends State<NextPage>{

// }
class SecondPage extends StatefulWidget {
  const SecondPage({super.key});
  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 90, 155, 213),
        title: const Text('詳細資訊',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(locations),
      ),
    );
  }
}
