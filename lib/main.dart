import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:provider/provider.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutt/local_notification_service.dart';
import 'package:flutt/websocket_service.dart';
import 'package:flutt/sensor_data.dart';
import 'package:flutt/viedo.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => WebSocketService(),
        ),
        // 添加更多的 providers，每个对应一个不同的 WebSocket 连接
      ],
      child: const MyApp(),
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
        home: const MyHomePage(),
      ),
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

  @override
  void dispose() {
    _updateNotificationController.close();
    super.dispose();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // static const TextStyle optionStyle =
  //     TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  // 定义底部导航栏中的每个页面
  final List<Widget> pages = [
    const PageEvent(),
    const PageWarn(),
    const PageUtil(),
  ];
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  // @override
  // void initState() {
  //   super.initState();

  // 初始化本地通知插件
  // var initializationSettingsAndroid =
  //     const AndroidInitializationSettings('app_icon');
  // var initializationSettingsIOS = const DarwinInitializationSettings();
  // var initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  // flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // }
  int currentIndex = 0;
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
          backgroundColor: Colors.blue[300],
          title: Text('火災事件列表',
              style: TextStyle(
                  color: Colors.grey[200], fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.history),
            iconSize: 35,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PageHistory()),
              );
            },
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.settings),
                iconSize: 35,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PageSetting()),
                  );
                }),
          ],
        ),
        body: pages[currentIndex],
        bottomNavigationBar: ConvexAppBar(
          // selectedItemColor: Color.fromARGB(255, 51, 66, 80),
          // unselectedItemColor: Colors.grey,
          // showUnselectedLabels: true,
          // currentIndex: currentIndex,
          style: TabStyle.react,
          // cornerRadius: 20,
          backgroundColor: Colors.blue[300],
          color: Colors.grey[200],
          activeColor: Colors.blue[900],
          onTap: (int index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: [
            TabItem(
              icon: Icons.home,
              title: '事件',
            ),
            TabItem(
              icon: Icons.warning,
              title: '通報',
            ),
            TabItem(
              icon: Icons.smart_toy,
              title: '設備',
            ),
          ],
        ));
  }
}

class PageEvent extends StatefulWidget {
  const PageEvent({super.key});
  @override
  State<PageEvent> createState() => _PageEvent();
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
String apiUrl = 'http://140.138.150.29:38083/apis/index.php';
String accessCode = '';
Uint8List? imageData;
bool _selected = false;
bool con_notify = true;
String captureMediaJson = '';
String event_id = '';
String iot_id = '';
String big_location = '';
List<SensorData> sensordata = [];
// Future<Map<String, dynamic>> fetchData() async {
//   final url = Uri.http('140.138.150.29:38080', 'service/alertAPI/'); // 將你的網址替換成實際的 URL http://140.138.150.29:38080/service/alertAPI/
//   try {
//     final response = await http.get(url);
//     if (response.statusCode == 200) {
//       // 如果服務器返回一個 OK 響應，則解析 JSON。
//       Map<String, dynamic> jsonData = jsonDecode(response.body);

//       // 使用鍵來訪問對應的值
//       updatetime = jsonData['0_update_stamp'];
//       isAlert = jsonData['alert'].toString();
//       List<dynamic> details = jsonData['details'];
//       for (var detail in details) {
//         events = detail['event'];
//         levels = detail['level'].toString();
//         locations = detail['location'];
//         timestamps = detail['time_stamp'];
//         Map<String, dynamic> sensors = detail['sensors'];
//         airqualitys = sensors['air_quality'].toStringAsFixed(2);
//         temperatures = sensors['temperature'].toStringAsFixed(2);

//         //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//         List<dynamic> captureImage = detail['capture_media'];
//         captureMediaJson = captureImage[0];

//         //String request = "http://192.168.0.13/apis/index.php";
//         //String buffer = "access_code=$captureMediaJson";
//         //Uri image_url = Uri.parse(request);
//       }
//       return jsonData; // 返回解析後的 JSON 數據
//     } else {
//       // 如果服務器返回一個不是 OK 的響應，則拋出一個異常。
//       throw Exception('Key "0_update_stamp" not found in the JSON data');
//     }
//   } catch (e) {
//     // 如果發生錯誤，則拋出一個異常。
//     throw Exception(e.toString());
//   }
// }

class _PageEvent extends State<PageEvent> {
  //final channel = IOWebSocketChannel.connect('ws://firealert.waziwazi.top:8880?token=1234');
  late final WebSocketService _streamControllerJson;

  @override
  void initState() {
    super.initState();
    try {
      _streamControllerJson =
          Provider.of<WebSocketService>(context, listen: false);
    } catch (e) {
      print('Error initializing WebSocketService: $e');
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
    // var _streamController =
    //     Provider.of<WebSocketService>(context, listen: false);
    // var _streamController_json = Provider.of<WebSocketService>(context, listen: false);

    return Scaffold(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _streamControllerJson.messageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Data is available, extract and display it
            Map<String, dynamic> datas = snapshot.data!;
            if (datas.containsKey('details')) {
              dynamic data = datas['details'];
              if (data.isNotEmpty) {
                // Data is present in datas['data']
                // Do something with the data
                locations = data['location'];
                levels = data['level'].toString();
                temperatures = data['temperature'].toString();
                timestamps = data['o_time_stamp'].toString();
                airqualitys = data['smoke'].toString();
                events = data['event'].toString();
                event_id = data['event_id'].toString();
                big_location = data['group_name'];
                String iot_id = data['iot_id'].toString();
                SensorData sensorData = SensorData(
                    airqualitys,
                    temperatures,
                    event_id,
                    iot_id,
                    big_location + ' ' + locations,
                    events,
                    isAlert,
                    levels,
                    timestamps);
                int spi = 0;
                for (var i = 0; i < sensordata.length; i++) {
                  if (sensordata[i].iot_id == iot_id) {
                    sensordata[i].modify(sensorData);
                    spi = 1;
                    break;
                  }
                }
                if (spi == 0) {
                  sensordata.add(sensorData);
                }
              }
            }
            return SingleChildScrollView(
              child: sensordata.isEmpty
                  ? Container(
                      width: 400, // 设置固定宽度
                      height: 100, // 设置固定高度
                      child: Card(
                        elevation: 6,
                        margin: EdgeInsets.all(16),
                        color: Colors.white, // 设置白色背景
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // 设置圆角
                          side: BorderSide(
                              color: Colors.black, width: 2.0), // 设置黑色边框
                        ),
                        child: Center(
                          child: Text(
                            '無事件資料',
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap:
                          true, // Ensures that the ListView.builder takes up only the necessary space
                      itemCount: sensordata.length,
                      itemBuilder: (context, index) {
                        SensorData itemData = sensordata[index];
                        //加入顏色變化
                        //判斷event類別
                        return Card(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  itemData.events,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                subtitle: Text(
                                  '位置: ${itemData.locations}\n'
                                  '時間: ${itemData.updatetime}\n'
                                  '事件id: ${itemData.id}\n'
                                  '事件等級: ${itemData.levels}\n'
                                  '氣體數值: ${itemData.airQuality}\n'
                                  '溫度: ${itemData.temperature}',
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailPage()),
                                        );
                                      },
                                      child: const Text('查看詳情'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          } else if (snapshot.hasError) {
            // Error occurred while fetching data
            return Center(
              child: Text('WebSocket Error: ${snapshot.error}'),
            );
          } else {
            // Data is not available yet
            if (sensordata.isEmpty) {
              //return (Text('無事件資料'));
              return Container(
                width: 400, // 设置固定宽度
                height: 100, // 设置固定高度
                child: Card(
                  elevation: 6,
                  margin: EdgeInsets.all(16),
                  color: Colors.white, // 设置白色背景
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // 设置圆角
                    side: BorderSide(color: Colors.black, width: 2.0), // 设置黑色边框
                  ),
                  child: Center(
                    child: Text(
                      '無事件資料',
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              );
            } else {
              return ListView.builder(
                shrinkWrap:
                    true, // Ensures that the ListView.builder takes up only the necessary space
                itemCount: sensordata.length,
                itemBuilder: (context, index) {
                  SensorData itemData = sensordata[index];
                  //加入顏色變化
                  //判斷event類別
                  return Card(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            itemData.events,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          subtitle: Text(
                            '位置: ${itemData.locations}\n'
                            '時間: ${itemData.updatetime}\n'
                            '事件id: ${itemData.id}\n'
                            '事件等級: ${itemData.levels}\n'
                            '氣體數值: ${itemData.airQuality}\n'
                            '溫度: ${itemData.temperature}',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DetailPage()),
                                  );
                                },
                                child: const Text('查看詳情'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            // Or any other loading indicator
          }
        },
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

void startDataPolling() {
  const Duration pollInterval = Duration(seconds: 3);
  Timer periodicTimer = Timer.periodic(pollInterval, (Timer t) {
    // 发送数据请求到服务器
    // fetchData();
  });
}

class PageUtil extends StatefulWidget {
  const PageUtil({super.key});
  @override
  State<PageUtil> createState() => _PageUtil();
}

class _PageUtil extends State<PageUtil> {
  List<SensorData> items = [];
  TextEditingController searchController = TextEditingController();
  var buffer = {};

  void filterItems(String query) {
    // Filter items based on the search query
    setState(() {
      items = sensordata
          .where((sensordata) =>
              sensordata.airQuality
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              sensordata.temperature
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              sensordata.id.toLowerCase().contains(query.toLowerCase()) ||
              sensordata.iot_id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    for (var i = 0; i < sensordata.length; i++) {
      var item = sensordata[i];
      // 将 SensorData 对象的属性添加到 buffer 中
      buffer[item.iot_id] = SensorData(
          item.airQuality,
          item.temperature,
          item.id,
          item.iot_id,
          item.locations,
          item.events,
          'yes',
          levels,
          item.updatetime);
    }

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
      body: buffer.isEmpty
          ? Center(
              child: Text('無資料'),
            )
          : ListView.builder(
              itemCount: buffer.length,
              itemBuilder: (context, index) {
                String key = buffer.keys.elementAt(index);
                SensorData sensorData = buffer[key];
                String sensorTitle = '';
                if (sensorData.levels == '-1') {
                  //之後再改
                  sensorTitle = '設備異常';
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
                          '溫度參數: ${sensorData.temperature}\n煙霧參數${sensorData.airQuality}\n地點:${locations}\n感測器 id: ${sensorData.id}',
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
          if (sensorData.iot_id == 'yes') {
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
                    '溫度參數: ${sensorData.temperature}\n煙霧參數${sensorData.airQuality}\n地點:${sensorData.locations}\n感測器 id: ${sensorData.id}',
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

class PageSetting extends StatefulWidget {
  const PageSetting({super.key});
  @override
  State<PageSetting> createState() => _PageSetting();
}

class _PageSetting extends State<PageSetting> {
  // @override
  // late final LocalNotificationService service;

  // void initState() {
  //   service = LocalNotificationService();
  //   service.intialize();
  //   super.initState();
  // }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[300],
          title: const Text('詳細資訊',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
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

                        // service.showNotification(
                        //     id: 0, title: 'Notification Title', body: 'Some body');
                      },
                    );
                  },
                )),
          ],
        ));
  }
}

class PageHistory extends StatefulWidget {
  const PageHistory({super.key});
  @override
  State<PageHistory> createState() => _PageHistory();
}

class _PageHistory extends State<PageHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
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

class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登入'),
      ),
      body: Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    labelText: "使用者名稱 ",
                    //hintText: "使用者名稱",
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
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
                width: double.infinity, // Use full available width
                height: 70.0,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 164, 199,
                            228)), // Change to your desired color
                  ),
                  child: const Text("登入", style: TextStyle(fontSize: 20)),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageWarn extends StatefulWidget {
  const PageWarn({super.key});
  @override
  State<PageWarn> createState() => _PageWarn();
}

class _PageWarn extends State<PageWarn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            launchPhone('119');
          },
          child: const Text(
            '通報119',
          ),
        ),
      ),
    );
  }
}
