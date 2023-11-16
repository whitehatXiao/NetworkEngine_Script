# $language = "python"
# $interface = "1.0"
import time
import os

# use advise
# 建议一次处理小于100个ip地址，防止 OOM

# TODO 该Demo是为了证明能够匹配上 MatchINdex

user = [
    "noc189",
    'h3c_xiaozl',
]
passwd = [
    "1qaz#EDC",
    '12#$qwER',
]

ip_list = [
    "192.168.56.10",
    "192.168.56.11",
    "192.168.56.12",
    "19.83.133.250",
    "4.179.152.216",
    "19.84.128.83",
    "19.85.0.15",
    "19.85.0.19",
    "19.85.0.173",
]

# current_time = time.strftime('%Y_%m_%d_%H', time.localtime(time.time()))

# global waiting time
wait_second = 5

# 命令行数组
# 注意： quit 等结束 session 命令不要再运行 configListener()
# screen-length disable 关闭分屏显示，就可以不再循环监听more了

command_list = [
    "sys \r",
    "undo local-user admin class manage \r",
    "attack-defense login reauthentication-delay 5  \r",
    "snmp-agent target-host trap address udp-domain 4.108.253.45 vpn-instance __mgnt_vpn__ params securityname ipran@)!# v2c \r",
    "quit \r",
    "save force \r",
    "reset counters interface \r",
    "screen-length disable \r",
    "dis diagnostic-information \r",
    "n \r"
]

longCommandWaitingTime = "6*60"

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
                raise Exception("[!] connecting faile by" + host.rstrip() )

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
            count = crt.Screen.WaitForStrings(['>', ']',':'])
            waitIndex = crt.Screen.MatchIndex
            crt.Dialog.MessageBox("count :" +  str(count) + ";  waitIdex: "+ str(waitIndex))

            # crt.Dialog.MessageBox("WaitForStrings index is " + str(index))
            #  可能有多次more情况，循环处理输出多次空格
            # configListener()


        time.sleep(10)
        crt.Screen.Send("quit \r")
        time.sleep(10)

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
