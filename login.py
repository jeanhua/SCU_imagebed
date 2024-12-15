import base64
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
import ddddocr


def login(id, password):
    loginUrl = "https://ecourse.scu.edu.cn/unifiedlogin/v1/loginmanage/login/direction?redirect_url=https://ecourse.scu.edu.cn/learn/live?type=0"
    drivers = webdriver.Edge()
    drivers.get(loginUrl)
    time.sleep(1)
    user_input = drivers.find_element(by=By.XPATH, value='//*[@id="app"]/div[1]/div/div[2]/div/div[1]/div[2]/div[2]/div/form/div[1]/div/div/div[2]/div/input')
    pw_input = drivers.find_element(by=By.XPATH, value='//*[@id="app"]/div[1]/div/div[2]/div/div[1]/div[2]/div[2]/div/form/div[2]/div/div/div[2]/div/input')

    # 自动识别验证码
    vercode_input = drivers.find_element(by=By.XPATH,value='//*[@id="app"]/div[1]/div/div[2]/div/div[1]/div[2]/div[2]/div/form/div[3]/div/div/div/div/input')
    vercode = drivers.find_element(by=By.XPATH,value='//*[@id="app"]/div[1]/div/div[2]/div/div[1]/div[2]/div[2]/div/form/div[3]/div/div/img')
    vercode_base64 = vercode.get_attribute("src").split(',')[1]
    ocr = ddddocr.DdddOcr(show_ad=False)
    res = ocr.classification(base64.b64decode(vercode_base64))
    vercode_input.send_keys(res)

    login_btn = drivers.find_element(by=By.XPATH, value='//*[@id="app"]/div[1]/div/div[2]/div/div[1]/div[2]/div[2]/div/form/div[4]/div/button')
    user_input.send_keys(id)
    pw_input.send_keys(password)
    time.sleep(0.8)
    login_btn.click()
    WebDriverWait(drivers, 120, 0.5).until(lambda
                                               driver: driver.current_url == "https://ecourse.scu.edu.cn/learn/live?type=0",
                                           "请检查网络连接")
    cookies = drivers.get_cookies()
    cookieText = ""
    for cookie in cookies:
        cookieText += cookie['name'] + "=" + cookie['value'] + ";"
    return cookieText
