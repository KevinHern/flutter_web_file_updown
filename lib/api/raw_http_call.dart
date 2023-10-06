import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class RawHttpAPI {
  Future<bool> uploadFile(
      {required FilePickerResult loadedFile, required String url}) async {
    // Preparing HTTP POST request to send the file
    // Creating http package multipart request object
    final request = http.MultipartRequest(
      "POST", // Type of method
      Uri.parse("http://127.0.0.1:15000/ufile"), // URL
    );

    // Adding selected file
    request.files.add(
      new http.MultipartFile(
        "file",
        loadedFile.files.first.readStream!,
        loadedFile.files.first.size,
        filename: loadedFile.files.first.name,
      ),
    );

    // Sending request
    http.StreamedResponse response = await request.send();

    // Parse raw response
    http.Response parsedResponse = await http.Response.fromStream(response);

    // Check Status
    if (parsedResponse.statusCode == 200) {
      // Parse body
      Map<String, dynamic> recvJson =
          JsonDecoder().convert(parsedResponse.body);

      // Extract values
      var message = recvJson['message'];
      print(message);

      return true;
    } else {
      // Do something

      return false;
    }
  }
}
