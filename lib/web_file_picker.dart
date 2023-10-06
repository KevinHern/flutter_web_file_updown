import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'dart:html' as html;

import 'api/dio_http_call.dart';

class WebFilePickerScreen extends StatefulWidget {
  @override
  WebFilePickerState createState() => WebFilePickerState();
}

class WebFilePickerState extends State<WebFilePickerScreen> {
  TextEditingController filenameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Testing File Upload"),
        leading: Icon(Icons.home),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.15,
            vertical: MediaQuery.of(context).size.width * 0.15,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: Text("Select File"),
                onPressed: () async {
                  // Select file from File System. Limit the files to only
                  // allowed extensions
                  final FilePickerResult? picked =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'csv', 'xlsx'],
                    withReadStream: true,
                  );

                  //Making sure an actual file has been selected
                  if (picked != null) {
                    final String url = "http://127.0.0.1:15000/ufile";
                    final DioAPI api = DioAPI();

                    final bool? requestStatus = await showDialog<bool>(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => SizedBox(
                        width: 400,
                        child: FutureProgressDialog(
                          api.fileUpload(loadedFile: picked, url: url),
                          message: Text('Uploading file...'),
                        ),
                      ),
                    );

                    String message = "";
                    DialogType dialogType = DialogType.info;
                    if (requestStatus!) {
                      message = "File upload was successful";
                    } else {
                      message = "An error occurred while uploading the file";
                      dialogType = DialogType.error;
                    }

                    AwesomeDialog(
                      context: context,
                      dialogType: dialogType,
                      width: 400,
                      dismissOnTouchOutside: true,
                      dismissOnBackKeyPress: true,
                      animType: AnimType.bottomSlide,
                      title: 'WARNING',
                      desc: message,
                      showCloseIcon: true,
                      btnOkOnPress: () {},
                    ).show();
                  }
                },
              ),
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.20,
                    vertical: 20),
                child: TextFormField(
                  controller: filenameController,
                ),
              ),
              ElevatedButton(
                child: Text("Get File"),
                onPressed: () async {
                  // Send POST request to get a file
                  http.Response response = await http.post(
                    Uri.parse(
                      "http://127.0.0.1:15000/gfile",
                    ),
                    body: {
                      "filename": filenameController.text,
                    },
                  );

                  // Check Status
                  if (response.statusCode == 200) {
                    // Parse body
                    Map<String, dynamic> recvJson =
                        JsonDecoder().convert(response.body);

                    // Extract values
                    var message = recvJson['message'];
                    var filebase64 = recvJson['file64'];
                    var extension = recvJson['extension'];
                    print(message);
                    print(filebase64);
                    print(extension);

                    // Convert base 64 to Array of int8 (aka, string to byte conversion)
                    Uint8List bytes = base64.decode(filebase64);

                    // Flutter web shenanigans to manipulate files and download it
                    final blob = html.Blob([bytes]);
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    final anchor =
                        html.document.createElement('a') as html.AnchorElement
                          ..href = url
                          ..style.display = 'none'
                          ..download = 'dummy.' + extension;
                    html.document.body!.children.add(anchor);

                    // Download
                    anchor.click();

                    // Cleanup
                    html.document.body!.children.remove(anchor);
                    html.Url.revokeObjectUrl(url);

                    // Do something else
                    setState(() {});
                  } else {
                    // Reportar error
                    // Do something
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
