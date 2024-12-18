"""
四川大学教务系统统一登陆认证脚本
使用方法：
    1.调用 get_access_token(client_id: str, username: str, password: str) 方法获取 access_token 和 refresh_token
    参数有:
        client_id 客户端id，用于区分不同的网站，比如大川学堂是 1371cbeda563697537f28d99b4744a973uDKtgYqL5B ，具体的可以F12抓包登陆查看
        username 学号
        password 密码
    2.(可选)获取到access_token后，调用 get_2FA_result(access_token: str, applicaation_key)
        applicaation_key是应用标识，具体也可抓包查看，比如大川学堂是 scdxplugin_jwt40
        返回false说明登陆成功，否则则需要二次认证(短信验证码之类的)
    3.使用accesstoken重定向到对应的网站即可登陆成功，获取request的cookie即可进行各种操作
"""

import time
import requests
import ddddocr
import json
import base64
from gmssl import sm2


def sm2_encrypt_base64(data: str, public_key_base64: str) -> str:
    public_key = base64.b64decode(public_key_base64).hex()
    sm2_crypt = sm2.CryptSM2(public_key=public_key, private_key=None)
    encrypted_data = sm2_crypt.encrypt(data.encode('utf-8'))
    encrypted_data = b'\x04' + encrypted_data
    encrypted_base64 = base64.b64encode(encrypted_data).decode('utf-8')
    return encrypted_base64


def get_access_token(client_id: str, username: str, password: str):
    timestamp = int(time.time() * 1000)
    response = requests.get(
        f"https://id.scu.edu.cn/api/public/bff/v1.2/one_time_login/captcha?_enterprise_id=scdx&timestamp={timestamp}")
    result = json.loads(response.text)
    code_captcha = result['data']['code']
    captcha = result['data']['captcha']
    ocr = ddddocr.DdddOcr(show_ad=False)
    cap_text = ocr.classification(base64.b64decode(captcha))
    result = json.loads(requests.post("https://id.scu.edu.cn/api/public/bff/v1.2/sm2_key", data="{}").text)
    sm2_pubkey = result['data']['publicKey']
    code_sm2 = result['data']['code']
    password_encrypt = sm2_encrypt_base64(password, sm2_pubkey)
    payload = "{\"client_id\":\"{client_id}\",\"grant_type\":\"password\",\"scope\":\"read\",\"username\":\"{username}\",\"password\":\"{password_encrypt}\",\"_enterprise_id\":\"scdx\",\"sm2_code\":\"{sm2_code}\",\"cap_code\":\"{cap_code}\",\"cap_text\":\"{cap_text}\"}".replace(
        "{username}", username).replace("{password_encrypt}", password_encrypt).replace("{sm2_code}", code_sm2).replace(
        "{cap_code}", code_captcha).replace("{cap_text}", cap_text).replace("{client_id}", client_id)
    headers = {
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
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
        'sec-ch-ua': '"Microsoft Edge";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"'
    }
    response = requests.request("POST", "https://id.scu.edu.cn/api/public/bff/v1.2/rest_token", headers=headers,
                                data=payload)
    result = json.loads(response.text)
    if not result['success']:
        print(response.text)
        return None,None
    access_token = result['data']['access_token']
    refresh_token = result['data']['refresh_token']
    return access_token,refresh_token


def get_2FA_result(access_token: str, applicaation_key):
    url = f"https://id.scu.edu.cn/api/bff/v1.2/commons/application_2factor?access_token={access_token}&application_key={applicaation_key}"
    payload = {}
    headers = {
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Pragma': 'no-cache',
        'Referer': 'https://id.scu.edu.cn/frontend/login',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-origin',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
        'sec-ch-ua': '"Microsoft Edge";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"'
    }
    response = requests.request("GET", url, headers=headers, data=payload)
    print(response.text)
    result = json.loads(response.text)
    if result['success']:
        return result['data']['twoFactor']
