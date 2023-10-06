import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class DioAPI {
  Future<bool> fileUpload(
      {required FilePickerResult loadedFile, required String url}) async {
    // Creating a Dio Object
    final Dio myDio = Dio();

    // Preparing body of the HTTP POST request to send file
    final dioFormData = FormData.fromMap({
      'name': 'dio',
      'date': DateTime.now().toIso8601String(),
      'file': MultipartFile.fromStream(
        () => loadedFile.files.first.readStream!,
        loadedFile.files.first.size,
        filename: loadedFile.files.first.name,
      )
    });

    // Sending request
    final Response dioResponse = await myDio.post(url, data: dioFormData);

    // Dio already decodes JSON bodies. Just printing the 'message' field
    print(dioResponse.data['message']);

    // Check Status
    if (dioResponse.statusCode == 200) {
      // Do something
      return true;
    } else {
      // Do something
      return false;
    }
  }
}
