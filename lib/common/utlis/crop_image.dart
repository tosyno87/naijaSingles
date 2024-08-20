import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:crop_image/crop_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CropMedia extends StatefulWidget {
  final String title;
  final File file;
  final String checktype;

  const CropMedia(
      {Key? key,
      required this.title,
      required this.file,
      required this.checktype})
      : super(key: key);

  @override
  CropMediaState createState() => CropMediaState();
}

class CropMediaState extends State<CropMedia> {
  CropController controller = CropController();
  bool isFinished = true;
  @override
  void initState() {
    //controller.dispose();
    super.initState();
    controller = CropController(aspectRatio: 1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Edit Photo'.tr().toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          isFinished
              ? IconButton(
                  icon: const Icon(Icons.done),
                  onPressed: () {
                    setState(() {
                      isFinished = false;
                    });
                    _finished().then((value) {
                      setState(() {
                        isFinished = true;
                      });
                    });
                  },
                )
              : const Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, 18, 10, 18), // Adjust padding as needed
                  child: SizedBox(
                    width: 20.0, // Adjust width to control size
                    height: 20.0, // Adjust height to control size
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0, // Adjust strokeWidth as needed
                    ),
                  ),
                ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: CropImage(
            controller: controller,
            image: Image.file(widget.file),
            minimumImageSize: 150,
          ),
        ),
      ),
    );
  }

  Future<void> _finished() async {
    final image = await controller.croppedBitmap();
    final data = await image.toByteData(format: ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    // final dir = await getApplicationDocumentsDirectory();
    // final path = dir.path;
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    Random random = Random();
    int randomNumber = random.nextInt(1000);
    var filePath = '$tempPath/$randomNumber.png';
    File file = await File(filePath).writeAsBytes(bytes);

    // ignore: use_build_context_synchronously
    Navigator.pop(context, file);
  }
}
