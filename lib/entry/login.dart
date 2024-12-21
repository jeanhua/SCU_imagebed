import 'dart:convert';
import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dart_sm/dart_sm.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

String bytesToHex(Uint8List bytes) {
  var result = StringBuffer();
  for (var byte in bytes) {
    var part = byte.toRadixString(16);
    part = part.padLeft(2, '0');
    result.write(part);
  }
  return result.toString();
}

String hexToBase64(String hexStr) {
  // 检查十六进制字符串长度是否为偶数
  if (hexStr.length % 2 != 0) {
    throw const FormatException('Invalid hexadecimal string');
  }
  Uint8List bytes = Uint8List(hexStr.length ~/ 2);
  for (var i = 0; i < hexStr.length; i += 2) {
    var hexByte = hexStr.substring(i, i + 2);
    bytes[i ~/ 2] = int.parse(hexByte, radix: 16);
  }
  return base64Encode(bytes);
}

String sm2_base64_encrypt(String content, String publicKey) {
  var keybytes = base64Decode(publicKey);
  String cipherText =
      SM2.encrypt(content, bytesToHex(keybytes), cipherMode: C1C2C3);
  String encrypted_text = hexToBase64("04$cipherText");
  return encrypted_text;
}

class LoginInstance {
  late String capcode;
  final Dio dio = Dio();
  final cookiejar = CookieJar();

  Future<Uint8List> getCapcode() async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch).toString();
    final response = await dio.get(
      "https://id.scu.edu.cn/api/public/bff/v1.2/one_time_login/captcha?_enterprise_id=scdx&timestamp=$timestamp",
    );
    final result = response.data;
    capcode = result['data']['code'];
    final captcha = result['data']['captcha'];
    return base64Decode(captcha);
  }

  Future<Map<String, String>> get_access_token(String client_id,
      String username, String password, String captext) async {
    final sm2Response = await dio
        .post("https://id.scu.edu.cn/api/public/bff/v1.2/sm2_key", data: {});
    final sm2Result = sm2Response.data;
    final sm2Pubkey = sm2Result['data']['publicKey'];
    final codeSm2 = sm2Result['data']['code'];
    final passwordEncrypt = sm2_base64_encrypt(password, sm2Pubkey);
    final payload = jsonEncode({
      "client_id": client_id,
      "grant_type": "password",
      "scope": "read",
      "username": username,
      "password": passwordEncrypt,
      "_enterprise_id": "scdx",
      "sm2_code": codeSm2,
      "cap_code": capcode,
      "cap_text": captext,
    });

    final headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Content-Type': 'application/json;charset=UTF-8',
      'Origin': 'https://id.scu.edu.cn',
      'Pragma': 'no-cache',
      'Referer': 'https://id.scu.edu.cn/frontend/login',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
      'sec-ch-ua':
          '"Microsoft Edge";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
    };

    final tokenResponse = await dio.post(
      "https://id.scu.edu.cn/api/public/bff/v1.2/rest_token",
      options: Options(headers: headers),
      data: payload,
    );

    final tokenResult = tokenResponse.data;
    if (!tokenResult['success']) {
      throw tokenResponse.data;
    }
    final accessToken = tokenResult['data']['access_token'];
    final refreshToken = tokenResult['data']['refresh_token'];
    return {'access_token': accessToken, 'refresh_token': refreshToken};
  }

  access(String access_token) async {
    try{
      dio.interceptors.add(CookieManager(cookiejar));
      var payload = {"access_token": access_token};
      await dio.post(
          "https://id.scu.edu.cn/api/bff/v1.2/commons/session/save",
          data: jsonEncode(payload));
      var url = "https://id.scu.edu.cn/api/bff/v1.2/commons/sp_logged?access_token=$access_token&sp_code=bDBhREE1WDMzK3llSzZyVFZNeE81czRDd1hESTI4NWxGaFdsTnlvcGt3eVdTb2cxSjN5a1FJTDVMWTBEQkFFd2k1bWZRMy82OXN6V21ZYzFLd2NlSDl1ekZ4bSt4Q0kzSWJYRG5UZkRzQ002ek10cUlNVGE4V2JmQXJqdnF0NFJza3F6dit4QjRLbHh4dXU1ckhGVXBQMmw3ek8xckozQWFHNWxZcEtRM3EwbGdURHc4Zm9wYW95ZklYUmdBd0VwT3lKVDAwSXk3bmd3YndLbFVIK2MzRGtGYkhmQmJtNFkrSVZSNnJmNDI0ZDVWSklZZkdnSXFOeGtlRHlnT1FyM3lSUDJKTGc5VjZhc2x1bXZSNFpFN3VjRzZ0ZVZlcXJLT1VKOHQzYUVIbkRRTTdMQkUxbUJ6NFl4WGo1R0NSMi9RTllkRUlYdDVnd24wR0tqTGl6Zzd4MENCQWtjcFJFRFdDcklNamEwYkdHVzkwcG9QamFoamgrTllFRjdTbTNHSUJRejhLcGJMdkNPVm9IQU5FMmFWQT09&application_key=scdxplugin_jwt40";
      var response = await dio.get(url,options: Options(followRedirects: true));
      return {"success":true};
    }
    catch(e){
      print((e as DioException).response);
      return {"success":false,"message":e.response.toString()};
    }
  }
}
