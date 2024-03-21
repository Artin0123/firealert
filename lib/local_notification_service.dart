// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:rxdart/subjects.dart';

// class LocalNotificationService {
//   LocalNotificationService();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();

//   Future<void> intialize() async {
//     const AndroidInitializationSettings androidInitializationSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     IOSInitializationSettings iosInitializationSettings =
//         IOSInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification: onDidReceiveLocalNotification,
//     );

//     final InitializationSettings settings = InitializationSettings(
//       android: androidInitializationSettings,
//       iOS: iosInitializationSettings,
//     );

//     await flutterLocalNotificationsPlugin.initialize(
//       settings,
//       onSelectNotification: onSelectNotification,
//     );
//   }

//   Future<NotificationDetails> _notificationDetails() async {
//     const AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails('channel_id', 'channel_name',
//             channelDescription: 'description',
//             importance: Importance.max,
//             priority: Priority.max,
//             playSound: true);

//     const IOSNotificationDetails iosNotificationDetails =
//         IOSNotificationDetails();

//     return const NotificationDetails(
//       android: androidNotificationDetails,
//       iOS: iosNotificationDetails,
//     );
//   }

//   Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//   }) async {
//     final details = await _notificationDetails();
//     //intialize();
//     title = 'hello';
//     body = 'hello world';
//     await flutterLocalNotificationsPlugin.show(id, title, body, details);
//   }

//   void onDidReceiveLocalNotification(
//       int id, String? title, String? body, String? payload) {
//     print('id $id');
//   }

//   void onSelectNotification(String? payload) {
//     print('payload $payload');
//     if (payload != null && payload.isNotEmpty) {
//       onNotificationClick.add(payload);
//     }
//   }
// }
