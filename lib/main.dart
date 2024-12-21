import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:scuimagebed/entry/login.dart';
import 'package:scuimagebed/pages/homepage.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
        theme: ThemeData(fontFamily: "抖音美好体"), home: LoginPage());
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController capcodeController = TextEditingController();
  final LoginInstance logininstance = LoginInstance();
  var capcode = null;
  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    readLoginHistory();
    refreshCapcode();
  }

  Future<void> refreshCapcode() async {
    capcode = await logininstance.getCapcode();
    setState(() {});
  }

  readLoginHistory() {
    if (File("./login.json").existsSync()) {
      try {
        var loginhis = jsonDecode(File("./login.json").readAsStringSync());
        usernameController.text = loginhis['username'];
        passwordController.text = loginhis['password'];
      } catch (e) {
        print(e.toString());
        usernameController.text = "";
        passwordController.text = "";
      }
    }
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

  login(String username, String password,String capcode) async {
    var er = "";
    if(username==""){
      er = "学号不能为空!";
    }
    else if(password==""){
      er="密码不能为空!";
    }
    else if(capcode==""){
      er="验证码不能为空!";
    }
    if (username == "" || password == "" || capcode=="") {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('错误',style: TextStyle(color: Colors.red),),
            content: Text(er),
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
      return;
    }
    File("./login.json").writeAsString(jsonEncode({
      "username":username,
      "password":password
    }));
    try{
      var result = await logininstance.get_access_token("1371cbeda563697537f28d99b4744a973uDKtgYqL5B", username, password, capcode);
      var access = await logininstance.access(result['access_token']!);
      if(access["success"]){
         Navigator.of(context).push(MaterialPageRoute(builder: (context)=>HomePage(logininstance: this.logininstance,)));
       }
       else{
         if (access["message"]["error"]=="{\"error\":\"unauthorized\",\"error_description\":\"Full authentication is required to access this resource\"}"){
           notice("错误", "登陆超时，请重新登陆！");
         }
         else{
           notice("错误！", "登陆失败，错误信息\n"+access["message"]);
         }
         refreshCapcode();
       }
    }
    catch(e){
      if (e is DioException) {
        print('Dio error!');
        print('DATA: ${e.response?.data}');
        if(e.response?.data["message"]=="invalid_captcha"){
          notice("错误", '验证码错误');
          refreshCapcode();
          return;
        }
      } else {
        print('Other error: $e');
      }
      notice("错误！", "登陆失败，请检查账号密码，或尝试重新登陆");
      refreshCapcode();
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("四川大学图床"),
        backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      ),
      body: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
                image: AssetImage("assets/image/bg.jpg"),
                fit: BoxFit.fitWidth)),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
                color: const Color.fromARGB(150, 255, 255, 255),
                borderRadius: BorderRadius.circular(20)),
            height: 300,
            width: 280,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "统一登陆认证",
                  style: TextStyle(color: Colors.blue, fontSize: 30),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: "学号"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: "密码"),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: capcodeController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), hintText: "验证码"),
                        ),
                      ),
                      GestureDetector(
                        child: SizedBox(
                          width: 100,
                          height: 30,
                          child: capcode==null?Image.asset("assets/image/bg.jpg"):Image.memory(capcode),
                        ),
                        onTap: (){
                          refreshCapcode();
                        },
                      )
                    ],
                  )
                ),
                TextButton(
                    onPressed: () {
                      // 点击登陆按钮
                      login(usernameController.text, passwordController.text,capcodeController.text);
                    },
                    child: const Text(
                      "登陆",
                      style: TextStyle(fontSize: 20),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
