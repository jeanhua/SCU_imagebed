import sys
import postImage
import login
import subprocess
import importlib.util

def install_and_import(package):
    try:
        # 尝试导入库
        importlib.util.find_spec(package)
        return importlib.import_module(package)
    except ImportError:
        # 如果导入失败，尝试使用pip安装
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        # 安装后再次尝试导入
        return importlib.import_module(package)

if __name__ == "__main__":
    requests = install_and_import('requests')
    selenium = install_and_import('selenium')
    print('四川大学统一身份登陆')
    id = input("输入学号：")
    password = input("输入密码：")
    cookie = login.login(id, password)
    if cookie==None:
        print('登陆失败')
        exit()

    while True:
        print("输入操作：")
        print("1.查看所有图片")
        print("2.上传图片")
        print("3.退出\n")
        op = input()
        if op == "1":
            with open("./image.txt", 'r', encoding='utf-8') as f:
                print(f.read())
        if op == "2":
            filepath = input("输入图片路径：").replace('"','')
            back = postImage.PostImage(filepath, cookie).run()
            if back == None:
                print("上传失败！")
                continue
            with open("./image.txt", 'a', encoding="utf-8") as f:
                f.write(back + '\n')
        if op == '3':
            break
        else:
            continue
