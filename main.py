import os.path
import requests
import postImage
import SCU_login
import login


if __name__ == "__main__":
    print('四川大学统一身份登陆')
    id = input("输入学号：")
    password = input("输入密码：")

    # 新版登陆
    access_token, refresh_token = SCU_login.get_access_token('1371cbeda563697537f28d99b4744a973uDKtgYqL5B', id,password)
    url = "https://id.scu.edu.cn/api/bff/v1.2/commons/session/save"
    session = requests.Session()
    payload = "{\"access_token\":\"{access_token}\"}".replace("{access_token}", access_token)
    session.request("POST", url, data=payload)
    with open("./sp_code.txt", 'r', encoding='utf-8') as f:
        sp_code = f.read().split('\n')[0]  # 登陆失败可以尝试改成1
    url = f"https://id.scu.edu.cn/api/bff/v1.2/commons/sp_logged?access_token={access_token}&sp_code={sp_code}&application_key=scdxplugin_jwt40"
    response = session.request("GET", url)
    cookie = session.cookies.get('S1_rman_sid')
    if cookie is None:
        print('登陆失败')
        exit()
    cookie = 'S1_rman_sid=' + cookie + ';'

    # 老版登陆,如果登陆失败解除下面的注释，并将上面的代码注释
    # cookie = login.login(id, password)
    # if cookie == None:
    #     print('登陆失败')
    #     exit()

    while True:
        print("输入操作：")
        print("1.查看所有图片")
        print("2.上传图片")
        print("3.退出")
        op = input()
        if op == "1":
            if os.path.exists("./image.txt"):
                with open("./image.txt", 'r', encoding='utf-8') as f:
                    print(f.read())
            else:
                print("没有什么东西……")
        if op == "2":
            filepath = input("输入图片路径：").replace('"', '')
            back = postImage.PostImage(filepath, cookie).run()
            if back is None:
                print("上传失败！")
                continue
            print("上传成功！URL:" + back.replace(' ', '%20'))
            with open("./image.txt", 'a', encoding="utf-8") as f:
                f.write(back.replace(' ', '%20') + '\n')
        if op == '3':
            break
        else:
            continue
