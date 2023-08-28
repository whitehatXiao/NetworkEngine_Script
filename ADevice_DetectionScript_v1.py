# $language = "python"
# $interface = "1.0"
import time
import os

#  ADevice_DetectionScript_v1.py
#    (Designed for use with SecureCRT 9.0 and later)
#
#    Last Modified: 19 AUG, 2023
# Added the ssh_method connection scheme. However, this method has some problems,
# when using ssh to establish a connection for the first time,
# the program will pop up the "Accept public key" window, then you need to manually click.
# Therefore, it is recommended to use telnet protocol when running the program for the first time.



user = [
    "noc189",
    'h3c_xiaozl',
]
passwd = [
    "1qaz#EDC",
    '12#$qwER',
]

ip_list = [
    "4.112.96.67",
    "19.72.0.237"
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
]

longCommandWaitingTime = 3 * 60


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

            # device name
            current_name = getName()
            # crt.Dialog.MessageBox("getCurrentname" + str(current_name))

            time.sleep(3)
            if not crt.Session.Connected:
                raise Exception("[!] connecting faile by" + host.rstrip() + "with telnet ")

        except Exception as e:
            # error = crt.GetLastErrorMessage()
            # crt.Dialog.MessageBox("[!] exception info : --" + str(e))
            # 记录连接错误消息
            # errorLogFP.write(str(e)+"\r\n")
            # 在同一个窗口重启可能会导致 connection lost
            crt.Session.Disconnect()
            # 如果仅仅使用 telnet_method() 你应该把 下面的Continue的注释打开
            continue

            # TODO 二次使用SSH协议
            # try:
            #     ssh_method(host)
            #     time.sleep(3)
            #     if not crt.Session.Connected:
            #         raise Exception("[!] connecting faile by" + host.rstrip()  + "with ssh ")
            # except Exception as e:
            #     continue



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
        crt.Screen.Send("dis diagnostic-information \r")
        crt.Screen.WaitForStrings([':'])
        crt.Screen.Send("n \r")
        time.sleep(2)

        # time.sleep(longCommandWaitingTime)
        count = crt.Screen.WaitForStrings([str(current_name)])
        # if count != 0:
        #     crt.Dialog.MessageBox("curname is matching: count is " + str(count))

        # time.sleep(longCommandWaitingTime)
        time.sleep(5)
        crt.Screen.Send("quit \r")
        time.sleep(5)

    # 程序执行完成
    crt.Dialog.MessageBox("[+] 脚本已执行，程序结束")



def ssh_method(host):
    command = "/SSH2 /L {0} /PASSWORD {1} {2}".format(user[1],passwd[1],str(host))
    crt.Session.ConnectInTab(command)



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

        if crt.Screen.WaitForString(">", 10) <= 0:
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


def getName():
    # 拿到当前设备名字
    rowIndex = crt.Screen.CurrentRow
    colindex = crt.Screen.CurrentColumn - 1
    chushi_name = crt.Screen.Get(rowIndex, 1, rowIndex, colindex)
    # name = chushi_name.strip('<>')
    return chushi_name


main()
