import os.path
import postImage
import login

if __name__ == "__main__":
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
        print("3.退出")
        op = input()
        if op == "1":
            if os.path.exists("./image.txt"):
                with open("./image.txt", 'r', encoding='utf-8') as f:
                    print(f.read())
            else:
                print("没有什么东西……")
        if op == "2":
            filepath = input("输入图片路径：").replace('"','')
            back = postImage.PostImage(filepath, cookie).run()
            if back == None:
                print("上传失败！")
                continue
            print("上传成功！URL:"+back.replace(' ','%20'))
            with open("./image.txt", 'a', encoding="utf-8") as f:
                f.write(back.replace(' ','%20') + '\n')
        if op == '3':
            break
        else:
            continue
