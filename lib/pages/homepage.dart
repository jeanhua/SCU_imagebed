import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scuimagebed/entry/postimage.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.logininstance});
  final logininstance;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  List images = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readImages();
  }

  notice(String title,String content){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title,),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(context).pop();// 关闭对话框
              },
            ),
          ],
        );
      },
    );
  }

  void readImages() {
    if (File("./image.json").existsSync()) {
      images = jsonDecode(File("./image.json").readAsStringSync());
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      children: <Widget>[
        // 背景图片
        Image.asset(
          'assets/image/bg.jpg',
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          fit: BoxFit.fill,
        ),
        // 背景模糊层
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ),
        // 前景内容
        SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          //decoration: const BoxDecoration(color: Colors.white,image: DecorationImage(image:AssetImage("assets/image/bg.jpg"))),
          child: Column(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width,
                color: const Color.fromARGB(150, 255, 255, 255),
                child: Row(
                  children: [
                    const Text(
                      "主页",
                      style: TextStyle(color: Colors.teal, fontSize: 30,fontStyle: FontStyle.italic,decoration: TextDecoration.none),
                    ),
                    Expanded(child: Container()),
                    IconButton(
                        onPressed: () async {
                          //添加图片
                          const XTypeGroup jpgsTypeGroup = XTypeGroup(
                            label: 'JPEGs',
                            extensions: <String>['jpg', 'jpeg'],
                          );
                          const XTypeGroup pngTypeGroup = XTypeGroup(
                            label: 'PNGs',
                            extensions: <String>['png'],
                          );
                          final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[
                            jpgsTypeGroup,
                            pngTypeGroup,
                          ]);
                          if(files.isEmpty)return;
                          var result = "";
                          for(var f in files){
                            var resp = await postImage(File(f.path).readAsBytesSync(), "${DateTime.timestamp()}.${f.name.split(".").last}", super.widget.logininstance.dio);
                            if(!resp["success"]){
                              result+="${f.path}:上传失败，${resp['data']}\n";
                            }
                            else{
                              result+="${f.path}:上传成功\n";
                              images.add(resp["data"]);
                            }
                          }
                          notice("结果", result);
                          File("./image.json").writeAsString(jsonEncode(images));
                        },
                        icon: const Icon(Icons.add_a_photo))
                  ],
                ),
              ),
              const Divider(
                color: Colors.blue,
              ),
              Expanded(
                  child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(150, 255, 255, 255),
                                borderRadius: BorderRadius.circular(10)),
                            child: Image.network(
                              images[index],
                              width: 100,
                            ),
                          ),
                        );
                      }))
            ],
          ),
        ),
      ],
    );
  }
}
