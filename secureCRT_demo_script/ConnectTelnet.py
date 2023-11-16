# $language = "Python"
# $interface = "1.0"

# Connect to a telnet server and automate the initial login sequence.
# Note that synchronous mode is enabled to prevent server output from
# potentially being missed.

import time
import os
# user = 'admin'
# passwd = 'admin'

iplist_file = "../Resource/ip.txt"
iplist_file_mode = "r"


def main():
    crt.Screen.Synchronous = True

    # 提取变量
    # host = "192.168.56.10"
    username = "admin"
    password = "admin"

    with open(iplist_file, iplist_file_mode) as rfile:
        host_list = rfile.readlines()
        for host in host_list:

            if crt.Session.Connected:
                # crt.Dialog.MessageBox("[!] Exception :   conneted")
                crt.Session.Disconnect()
                # crt.GetScriptTab().Close()

            try:
                method_name(host.rstrip(), password, username)
                time.sleep(3)

            except Exception as e :
                crt.Dialog.MessageBox(str(e))
                continue



def method_name(host, password, username):
    is_login_Success = 1
    is_passwd_Success =1
    # 拼接命令
    command = "/TELNET {0} 23".format(host)
    # 连接主机
    try:
        crt.Session.Connect(command, True , False)
        # time.sleep(2)
        # 登录过程
        is_login_Success = crt.Screen.WaitForString("login:", 2)
        crt.Screen.Send("{0}\r".format(username))
        is_passwd_Success = crt.Screen.WaitForString("Password:", 2)
        crt.Screen.Send("{0}\r".format(password))

        crt.Dialog.MessageBox("isSuccess: " + str(is_login_Success) + str(is_passwd_Success))

        if is_login_Success <= 0 or is_passwd_Success <= 0:
            raise Exception("[!] Exception Failed to detect login or Password from ---> " + host.rstrip())

    except Exception as e:
        # crt.Dialog.MessageBox("[!] Exception : " + str(e))
        raise Exception("[!] Exception : " + str(e) + " by --> " + host )





def method_name1(host, password, username):
    # 拼接命令
    command = "/TELNET {0} 23".format(host)
    # 连接主机
    # crt.Screen.Synchronous = True
    try:
         crt.Session.Connect(command)
    except Exception as e:
        crt.Dialog.MessageBox("[!] Exception : " + str(e))
    # 登录过程
    crt.Screen.WaitForString("login:")
    crt.Screen.Send("{0}\r".format(username))
    crt.Screen.WaitForString("Password:")
    crt.Screen.Send("{0}\r".format(password))


main()
