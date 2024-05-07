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
import 'package:flutt/video.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final service = FlutterBackgroundService();
final notifications = FlutterLocalNotificationsPlugin();

void onStart(ServiceInstance service) async {
  final notifications = FlutterLocalNotificationsPlugin();
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    await notifications.show(
      0,
      'Flutter Background',
      'This is a notification from background service',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channelId',
          'channelName',
          importance: Importance.max,
        ),
      ),
    );
  });
}

String username = ""; //使用者名稱與密碼
String password = "";
Map<String, dynamic> tokenbuffer = Map<String, dynamic>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地通知
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await notifications.initialize(initializationSettings);
  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart,
  //     autoStart: true,
  //     isForegroundMode: true,
  //   ),
  //   iosConfiguration: IosConfiguration(),
  // );

  //使用者定期驗證

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => WebSocketService(tokenbuffer),
        ),
        // 添加更多的 providers，每个对应一个不同的 WebSocket 连接
      ],
      child: const MyApp(),
    ),
  );
  startTimer();
}

void startTimer() {
  int timestamp = 1714472686;
  DateTime then =
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
          .toUtc();
  DateTime now = DateTime.now().toUtc();
  Duration delay = then.difference(now);
  Timer(delay, () {
    // 在时间到达 1714472686 UTC+8 时执行的代码写在这里
    if (username != "" && password != "") {
      print(username + " " + password);
      _sendDataToServer(password, username);
    } else {
      print("No username and password!!!");
    }
  });
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
    const PageHistory(),
    const PageWarn(),
    const PageUtil(),
    const PageSetting(),
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
    return Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: ConvexAppBar(
          // selectedItemColor: Color.fromARGB(255, 51, 66, 80),
          // unselectedItemColor: Colors.grey,
          // showUnselectedLabels: true,
          // currentIndex: currentIndex,
          style: TabStyle.react,
          // cornerRadius: 20,
          backgroundColor: Colors.lightBlue[300],
          elevation: 3,
          color: Colors.grey[100],
          activeColor: Colors.blue[700],
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
              icon: Icons.history,
              title: '歷史',
            ),
            TabItem(
              icon: Icons.warning,
              title: '通報',
            ),
            TabItem(
              icon: Icons.smart_toy,
              title: '設備',
            ),
            TabItem(
              icon: Icons.settings,
              title: '設定',
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
List<SensorData> record = [];
late final WebSocketService _streamControllerJson;
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

  ButtonStyle _buttonStyle(Color buttonColor) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(buttonColor),
    );
  }

  Color _buttonColor = Colors.red;
  int button_signal = 0;
  void _toggleButtonColor() {
    setState(() {
      _buttonColor = button_signal == 0 ? Colors.blue : Colors.red;
      // Update text color to contrast with button color
      //_textColor = _buttonColor == Colors.blue ? Colors.white : Colors.black;
    });
  }

  @override
  Widget build(BuildContext context) {
    // var _streamController =
    //     Provider.of<WebSocketService>(context, listen: false);
    // var _streamController_json = Provider.of<WebSocketService>(context, listen: false);
    SensorData sensorData = SensorData.defaults();
    bool detailButtonPressed = false;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          backgroundColor: Colors.lightBlue[300],
          title: Text('火災事件列表',
              style: TextStyle(
                  color: Colors.grey[50],
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3.0),
            child: Container(
              color: Colors.lightBlue,
              height: 3.0,
            ),
          )),
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
                sensorData = SensorData(
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
                sensorData.fixcolorRed();
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
                record.add(sensorData);
                // button_signal = 1;
                // print(button_signal);
                // sensordata.sort(SensorData.compareByLevel);
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
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            // button_signal = 0;
                                            // setState(() {
                                            //   detailButtonPressed = true;
                                            //   //_buttonColor = Colors.blue;
                                            //  // _toggleButtonColor();

                                            // });
                                            itemData.fixcolorblue();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailPage(
                                                        sensorData_detail:
                                                            itemData),
                                              ),
                                            );
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                        Color>(
                                                    itemData.buttoncolor()),
                                          ),
                                          child: _buttonColor == Colors.red
                                              ? Text(
                                                  '新影片',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                )
                                              : Text(
                                                  '查看詳情',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                        ),
                                        SizedBox(width: 10),
                                        (!detailButtonPressed &&
                                                datas.containsKey('details'))
                                            ? Text('有影片')
                                            : SizedBox.shrink(),
                                      ],
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
                                        builder: (context) => DetailPage(
                                            sensorData_detail: itemData)),
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
          : ListView.separated(
              itemCount: buffer.length,
              separatorBuilder: (context, index) {
                return Divider(); //這裡是每個item之間的分隔線
              },
              itemBuilder: (context, index) {
                String key = buffer.keys.elementAt(index);
                SensorData sensorData = buffer[key];
                String sensorTitle = '';

                if (sensorData.levels == '-1') {
                  //之後再改
                  sensorTitle = '設備異常';
                } else {
                  sensorTitle = '正常';
                }

                return Container(
                  margin: const EdgeInsets.all(16),
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
                          '溫度參數: ${sensorData.temperature}\n煙霧參數: ${sensorData.airQuality}\n地點 :${locations}\n感測器 id: ${sensorData.id}',
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

bool _isLoggedIn = false;

//設定頁面
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
          backgroundColor: Colors.lightBlue[300],
          title: Text('設定',
              style: TextStyle(
                  color: Colors.grey[50],
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3.0),
            child: Container(
              color: Colors.lightBlue,
              height: 3.0,
            ),
          ),
        ),
        body: Column(
          children: [
            ListTile(
              onTap: () {
                if (_isLoggedIn) {
                  // 如果登入 就登出
                  _handleLogout();
                } else {
                  // 未登入，就進入登入畫面
                  _handleLogin();
                }
              },
              leading: Icon(
                  _isLoggedIn ? Icons.logout : Icons.login), // 根据登录状态显示不同的图标
              title: Text(_isLoggedIn ? username : '登入'), // 根据登录状态显示不同的文本
              subtitle: Text(_isLoggedIn ? '登出' : ''),
            ),
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

  void _handleLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NextPage()),
    ).then((_) {
      // 登录成功后更新状态为已登录
      setState(() {
        _isLoggedIn = true;
      });
    });
  }

  void _handleLogout() {
    // 登出逻辑...
    // 登出成功后更新状态为未登录
    setState(() {
      _isLoggedIn = false;
      username = "";
      password = "";
      tokenbuffer = Map<String, dynamic>();
    });
  }
}

//歷史介面
class PageHistory extends StatefulWidget {
  const PageHistory({Key? key}) : super(key: key);

  @override
  State<PageHistory> createState() => _PageHistory();
}

class _PageHistory extends State<PageHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        title: Text(
          '歷史紀錄',
          style: TextStyle(
              color: Colors.grey[50],
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(
            color: Colors.lightBlue,
            height: 3.0,
          ),
        ),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => Divider(color: Colors.black),
        itemCount:
            record.length, // replace 'record' with your actual record array
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(
              '${record[index].events}\n地點: ${record[index].locations}',
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              '更新時間: ${record[index].updatetime}',
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}

//登入頁面
class NextPage extends StatelessWidget {
  const NextPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController _usernameController = TextEditingController();
    TextEditingController _passwordController = TextEditingController();

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
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  labelText: "使用者名稱 ",
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: Icon(Icons.remove_red_eye),
                  labelText: "密碼 ",
                ),
              ),
            ),
            const SizedBox(height: 52.0),
            SizedBox(
              width: double.infinity,
              height: 70.0,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 164, 199, 228),
                  ),
                ),
                child: const Text(
                  "登入",
                  style: TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  username = _usernameController.text;
                  password = _passwordController.text;
                  _sendDataToServer(username, password).then((responseCode) {
                    if (responseCode == 200) {
                      //成功回到原始介面
                      Navigator.pop(context);
                    } else if (responseCode == 401) {
                      //登入驗證失敗
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('登入失敗，請檢查用戶名與密碼'),
                        ),
                      );
                    }
                  }).catchError((error) {
                    print('登入時發生錯誤：$error');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('登入失敗，請稍後再試'),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//獲取使用者驗證資訊
Future<int> _sendDataToServer(String username, String password) async {
  final response = await http.post(
    Uri.parse('http://192.168.0.13:3000/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'username': username,
      'password': password,
    }),
  );

  // Check response
  if (response.statusCode == 200) {
    // Request successful
    print('Successful send!!!');
    Map<String, dynamic> responseData = jsonDecode(response.body);
    tokenbuffer = responseData;
    // Access data from response
    print('Response data: $responseData');
    return response.statusCode;
  } else {
    // Request failed
    print(response.statusCode);
    return response.statusCode;
  }
}

class PageWarn extends StatefulWidget {
  const PageWarn({super.key});
  @override
  State<PageWarn> createState() => _PageWarn();
}

class _PageWarn extends State<PageWarn> {
  // @override
  // void initState() {
  //   super.initState();
  //   notifications.initialize(
  //     const InitializationSettings(
  //       android: AndroidInitializationSettings('app_icon'),
  //     ),
  //     onSelectNotification: (payload) async {
  //       // 處理通知點擊事件
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.lightBlue[300],
          title: Text('緊急通報',
              style: TextStyle(
                  color: Colors.grey[50],
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3.0),
            child: Container(
              color: Colors.lightBlue,
              height: 3.0,
            ),
          )),
      body: Container(
        width: double.infinity,
        height: 100,
        child: TextButton(
          onPressed: () {
            launchPhone('119');
          },
          child: const Text(
            '通報119',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
