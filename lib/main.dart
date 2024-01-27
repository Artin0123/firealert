import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppDataProvider(),
      child: MaterialApp(
        title: 'Flutter Demo',
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

  // void _incrementCounter() {
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _counter++;
  //   });
  // }
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  void initState() {
    super.initState();

    // 初始化本地通知插件
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> sendNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '設備異常通知',
      '溫度感器異常!',
      platformChannelSpecifics,
      payload: 'item x',
    );
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
  StreamController<bool> notification = StreamController<bool>();
  StreamController<String> param2Controller = StreamController<String>();

  bool selection = true;
  void updateParam1(bool newValue) {
    selection = newValue;
    notification.sink.add(selection);
    selection = con_notify;
    notifyListeners();
  }

  void dispose() {
    notification.close();
    param2Controller.close();
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

class _Pageone extends State<PageOne> {
  //getImage(captureMediaJson);
  // Future<Map<String, dynamic>> update() {
  //   Future<Map<String, dynamic>> buffer;
  //   buffer = fetchData();
  //   //getImage(captureMediaJson);
  //   return buffer;
  // }
  final TextEditingController _controller = TextEditingController();
  final _channel = WebSocketChannel.connect(
    Uri.parse('wss://echo.websocket.events'),
  );

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
                            child: const Text('通報119'),
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
              Form(
                child: TextFormField(
                  controller: _controller,
                  decoration:
                      const InputDecoration(labelText: 'Send a message'),
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder(
                stream: _channel.stream,
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? '${snapshot.data}' : '');
                },
              ),
              ElevatedButton(
                onPressed: _sendMessage,
                child: const Icon(Icons.send),
              ),
              // Container(
              //   alignment: Alignment.centerLeft,
              //   child: Text('上次警報更新時間: $updatetime\n是否有警報: $isAlert', textAlign: TextAlign.left),
              //   Text('事件種類: $events'),
              //   Text('事件等級: $levels'),
              //   Text('感測器位置: $locations'),
              //   Text('事件時間: $timestamps'),
              //   Text('氣體數值: $airqualitys'),
              //   Text('溫度: $temperatures'),
              // ),

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

              // StreamBuilder<bool>(
              //   stream: context.read<AppDataProvider>().notification.stream,
              //   builder: (context, snapshot) {
              //     try {
              //       bool? notified = snapshot.data;

              //       return Text(
              //         'Notification: ${notified ?? false}',
              //         style: TextStyle(fontSize: 18),
              //       );
              //     } catch (e, stackTrace) {
              //       print('Caught an exception: $e');
              //       print('Stack trace: $stackTrace');

              //       // Return a default or error UI if needed
              //       return Text('Error occurred');
              //     }
              //   },
              // ),
            ]),
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
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

class _Pagetwo extends State<PageTwo> {
  List<String> items = [];
  TextEditingController searchController = TextEditingController();
  var buffer = new Map();

  void updateList() async {
    // Fetch data and update the list
    //Map<String, dynamic> newData = await fetchData();

    setState(() {
      //items = newData;
      items.add(airqualitys);
      items.add(temperatures);
      buffer[123] = airqualitys;
      buffer[456] = temperatures;
    });
  }

  void filterItems(String query) {
    // Filter items based on the search query
    setState(() {
      items = items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    buffer[123] = airqualitys; //先預設值
    buffer[456] = temperatures;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          //controller: searchController,
          onTap: () async {
            // Show search bar and get user input
            final query = await showSearch(
              context: context,
              delegate: SearchBarDelegate(buffer),
            );
            if (query != null) {
              filterItems(query);
            }
            // Handle search query
          },
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: ListView.builder(
          itemCount: buffer.length,
          itemBuilder: (context, index) {
            int key = buffer.keys.elementAt(index);
            String sensorTitle = '';
            String exper = '';
            if (index % 2 == 0) {
              sensorTitle = '溫度感測器';
              exper = '溫度';
            } else {
              sensorTitle = '空氣感測器';
              exper = '濕度';
            }
            return Card(
              elevation: 6,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$sensorTitle',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '感測器 id: $key\n$exper: ${buffer[key]}\n有無異常:',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}

class SearchBarDelegate extends SearchDelegate {
  var dic = new Map();
  List<String> result = [];
  SearchBarDelegate(this.dic);
  Widget buildLeading(BuildContext context) {
    //输入框之前的部件
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  List<Widget> buildActions(BuildContext context) {
    //輸入時的物件
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

  Widget buildResults(BuildContext context) {
    //顯示搜索結果

    List<String> buffer = [];
    if (!result.isEmpty) {
      buffer.add(result[0]);
      buffer.add(result[1]);
      result.clear();
    } else {
      buffer.add('0');
      buffer.add('0');
    }

    return ListTile(
      title: Text('id :${buffer[0]}:\n${buffer[1]}'),
      onTap: () {
        // 处理结果的点击事件
        // 这里你可以进行页面跳转或其他操作
        //close(context, buffer);
      },
    );
  }

  Widget buildSuggestions(BuildContext context) {
    //搜索建議
    return ListView(
      children: dic.entries.map((MapEntry<dynamic, dynamic> entry) {
        String key = entry.key.toString();
        String value = entry.value.toString();

        return ListTile(
          title: Text('id $key: $value'),
          onTap: () {
            // 按下選中的項目
            query = key + ' ' + value; // 將選中項目放進query
            result.add(key);
            result.add(value);
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
  const Duration pollInterval = const Duration(seconds: 3);
  Timer periodicTimer = Timer.periodic(pollInterval, (Timer t) {
    // 发送数据请求到服务器
    fetchData();
  });
}

class _Pagethree extends State<PageThree> {
  Widget build(BuildContext context) {
    var appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
    return Scaffold(
        body: Column(
      children: [
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
          title: Text(
            "設備通知",
            //style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          subtitle: Text("設備通知是否開啟"),
          trailing: StreamBuilder<bool>(
            stream: appDataProvider.notification.stream,
            builder: (context, snapshot) {
              try {
                bool? notified = snapshot.data;

                return Switch(
                  value: notified ?? true,
                  onChanged: (value) {
                    appDataProvider.notification.sink.add(value);
                    // setState(() {
                    //   con_notify = value;
                    // });
                  },
                );
              } catch (e, stackTrace) {
                print('Caught an exception: $e');
                print('Stack trace: $stackTrace');
                return Text('Error occurred');
              }
            },
          ),
        ),
        ListTile(
            onTap: () {
              setState(() {
                // This is called when the user toggles the switch.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NextPage()),
                );
              });
            },
            leading: const Icon(Icons.person),
            title: Text('登入'))
      ],
    ));
  }
}

class NextPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登入'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  labelText: "使用者名稱 ",
                  //hintText: "使用者名稱",
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: Icon(Icons.remove_red_eye),
                  labelText: "密碼 ",
                  //hintText: "最好6個字",
                ),
              ),
            ),
            SizedBox(
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
                child: Text("登入", style: TextStyle(fontSize: 20)),
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
        child: Text('$locations'),
      ),
    );
  }
}
