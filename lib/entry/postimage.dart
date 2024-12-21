import 'dart:typed_data';
import 'package:dio/dio.dart';

Future<Map> postImage(Uint8List image_bytes,String fileName,Dio sender) async {
  var headers = {
    'Accept': '*/*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Origin': 'https://ecourse.scu.edu.cn',
    'Pragma': 'no-cache',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
    'X-Requested-With': 'XMLHttpRequest',
    'sec-ch-ua': '"Microsoft Edge";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"'
  };
  var data = FormData.fromMap({
    'files': [
      MultipartFile.fromBytes(image_bytes,filename: fileName)
    ],

  });
  try{
    var response = await sender.request(
      'https://ecourse.scu.edu.cn/learn/v1/upload/fileupload',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
    if (response.data["status"] != 400) {
      return {"success":true,"data":"https://ecourse.scu.edu.cn${response.data['data']['httpPath']}"};
    }
    else {
      return {"success":false,"data":response.data};
    }
  }catch(e){
    print((e as DioException).response?.data);
    return {"success":false,"data":e.response?.data};
  }
}
