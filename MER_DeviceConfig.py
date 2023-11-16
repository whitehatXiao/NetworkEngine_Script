# $language = "python"
# $interface = "1.0"
import time
import os

user = [
    "noc189",
    'h3c_xiaozl',
]
passwd = [
    "1qaz#EDC",
    '12#$qwER',
]

ip_list = [
    '14.123.24.254',
    '14.123.24.255',
    '14.125.0.254',
    '14.125.0.255',
    '14.123.144.254',
    '14.123.144.255',
    '14.123.184.254',
    '14.123.184.255',
    '14.123.48.254',
    '14.123.48.255',
    '14.123.40.254',
    '14.123.40.255',
    '14.123.128.254',
    '14.123.128.255',
    '14.123.136.254',
    '14.123.136.255',
    '14.123.152.254',
    '14.123.152.255',
    '14.123.160.254',
    '14.123.160.255',
    '14.123.56.254',
    '14.123.56.256'
]

# current_time = time.strftime('%Y_%m_%d_%H', time.localtime(time.time()))

# global waiting time
wait_second = 5

# 命令行数组
# 注意： quit 等结束 session 命令不要再运行 configListener()
# screen-length disable 关闭分屏显示，就可以不再循环监听more了

command_list = [
    "screen-length disable \r",
    "dis current-configuration \r",
    "dis bgp peer  l2vpn evpn \r",
    "dis bgp peer  vpnv4 \r",
    "dis bgp peer  vpnv6 \r",
    "dis bgp peer  ipv4 vpn-instance CDMA-RAN \r"

]


def main():
    # 开启异步模式
    crt.Screen.Synchronous = False

    for host in ip_list:
        # crt.Dialog.MessageBox("[*] current_host:"+host )
        # 初始时清除session连接
        if crt.Session.Connected:
            crt.Session.Disconnect()
        try:
            telnet_method(host)

            time.sleep(3)
            if not crt.Session.Connected:
                raise Exception("[!] connecting faile by" + host.rstrip())

        except Exception as e:
            # error = crt.GetLastErrorMessage()
            crt.Dialog.MessageBox("[!] exception info : --" + str(e))
            # 记录连接错误消息
            # errorLogFP.write(str(e)+"\r\n")
            # 在同一个窗口重启可能会导致 connection lost
            crt.Session.Disconnect()
            continue

        # test ? isSkipping
        # crt.Dialog.MessageBox("[*] current_host:"+host )
        # 不忽略转义字符都看不到配置界面
        crt.Screen.IgnoreEscape = True
        crt.Screen.IgnoreCase = True

        # crt.Screen.Send('\r\n')
        # crt.Screen.Send('\r\n')
        # crt.Screen.Send('\r\n')

        for command in command_list:
            # time.sleep(1)
            # print(command)
            # 终端bug，多次发送
            # crt.Dialog.MessageBox("Command : "+str(command))
            crt.Screen.Send(command)
            # crt.Screen.SendSpecial("TN3270_RETURN")
            # crt.Screen.Send('\r\n')
            # crt.Screen.Send('\r\n')
            # time.sleep(2)
            # 展示界面下等待的是 > ， 配置界面下等待的是 ]
            crt.Screen.WaitForStrings(['>', ']'])
            # crt.Dialog.MessageBox("WaitForStrings index is " + str(index))
            #  可能有多次more情况，循环处理输出多次空格
            # configListener()

        # "dis diagnostic-information \r",
        # "n \r"
        time.sleep(5)
        crt.Screen.Send("quit \r")
        time.sleep(5)

    # 程序执行完成
    crt.Dialog.MessageBox("[+] 脚本已执行，程序结束")


def telnet_method(host):
    # 异常处理： ip 不通、login，password 错误或输入超时
    # is_login_Success = 1
    # is_passwd_Success = 1
    # isauthentication = 1
    # 拼接命令
    command = "/TELNET {0} 23".format(host)
    # 连接主机
    try:
        crt.Session.Connect(command, True, False)
        # time.sleep(2)
        # 登录过程
        is_login_Success = crt.Screen.WaitForString("login:", wait_second)
        crt.Screen.Send("{0}\r".format(user[0]))
        is_passwd_Success = crt.Screen.WaitForString("Password:", wait_second)
        crt.Screen.Send("{0}\r".format(passwd[0]))

        if crt.Screen.WaitForString(">", wait_second) <= 0:
            # raise Exception("[!] Exception Failed to Authentication")
            # 用户名密码错误，尝试第二组用户名密码
            crt.Screen.WaitForString("login:", wait_second)
            crt.Screen.Send("{0}\r".format(user[1]))
            crt.Screen.WaitForString("Password:", wait_second)
            crt.Screen.Send("{0}\r".format(passwd[1]))

            if crt.Screen.WaitForString(">", wait_second) <= 0:
                raise Exception("[!] Exception Failed to Authentication")

        # crt.Dialog.MessageBox("isSuccess: " + str(is_login_Success))

        if is_login_Success <= 0 or is_passwd_Success <= 0:
            raise Exception("[!] Exception Failed to detect login or Password from ---> " + host.rstrip())

    except Exception as e:
        # crt.Dialog.MessageBox("[!] Exception : " + str(e))
        raise Exception("[!] Exception : " + str(e).rstrip() + " by --> " + host.rstrip())


main()
