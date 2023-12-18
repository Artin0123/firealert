import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Replace this URL with your actual API endpoint
  String apiUrl = 'http://192.168.0.13/apis/index.php';

  // Replace '123456' with your actual access code
  String accessCode = 'mks2cfe6fw87twdjaijwo';

  // Variable to store the image data
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    // Create the payload
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
        print('Unexpected content type: ${response.headers['content-type']}');
      }
    } else {
      print('HTTP request failed with status: ${response}');
      print('Response body: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Display Example'),
      ),
      body: Center(
        child: imageData != null
            ? Image.memory(
                imageData!,
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
