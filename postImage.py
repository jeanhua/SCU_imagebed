import json
import time
import os
import requests


class PostImage:
    def __init__(self, filepath, cookies):
        self.filepath = filepath
        self.cookies = cookies

    def run(self):
        url = "https://ecourse.scu.edu.cn/learn/v1/upload/fileupload"
        payload = {}
        files = [
            ('file', (f"{os.path.basename(self.filepath)}_{time.time()}.{str(self.filepath).split('.')[-1]}", open(f'{self.filepath}', 'rb'), 'application/octet-stream'))
        ]
        headers = {
            'Accept': '*/*',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Cookie': f'{self.cookies}',
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
        }
        response = requests.request("POST", url, headers=headers, data=payload, files=files)
        result = json.loads(response.text)
        if(result['status']==400):
            print(response.text)
            return None
        else:
            return f"https://ecourse.scu.edu.cn/{result['data']['httpPath']}"
