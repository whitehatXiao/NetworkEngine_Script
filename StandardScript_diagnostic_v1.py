# $language = "python"
# $interface = "1.0"
import time
import os

# use advise
# 建议一次处理小于100个ip地址，防止 OOM

user = 'noc189'
passwd = '1qaz#EDC'


secureCRT_4A = r"\\tsclient\C\Users\lin\Desktop\detection_Script"

# iplist_file = os.getcwd()+"\\Resource\\ip.txt"
iplist_file = secureCRT_4A+"\\Resource\\ip.txt"
iplist_file_mode = "r"


# detection_log_dir = os.getcwd()+"\\detection_log\\"
# exception_log_dir = os.getcwd()+"\\exception_log\\"
detection_log_dir = secureCRT_4A+"\\detection_log\\"
exception_log_dir = secureCRT_4A+"\\exception_log\\"


errorLog_file = exception_log_dir + "errorInfo.txt"
errorLog_file_mode = "wb+"


current_time = time.strftime('%Y_%m_%d_%H', time.localtime(time.time()))

# global waiting time
wait_second = 5


# 命令行数组
# 注意： quit 等结束 session 命令不要再运行 configListener()
command_list = [
    "display cur \r",
    "display ip int brief \r",
]


def main():

    # 开启异步模式
    crt.Screen.Synchronous = False

    if not os.path.exists(iplist_file):
        crt.Dialog.MessageBox("[!]"
            "Session list file not found:\n\n" +
            iplist_file + "\n\n" +
            "Create a session list file as described in the description of " +
            "this script code and then run the script again.")
        return

    # 记录错误日志
    errorLogFP = open(errorLog_file , errorLog_file_mode)

    with open(iplist_file, iplist_file_mode) as rfile:
        host_list = rfile.readlines()
        for host in host_list:
            # crt.Dialog.MessageBox("[*] current_host:"+host )
            # 初始时清除session连接
            if crt.Session.Connected:
                crt.Session.Disconnect()
            try:
                # TODO 选择 ssh2 或者 telnet
                # ssh_method(host)
                telnet_method(host)

                #  crt.Session.Connected 不是阻塞式方法，那目前为止就还是只能用 time.sleep 了
                time.sleep(3)
                if not crt.Session.Connected :
                    raise Exception("[!] connecting faile by" + host.rstrip() + "  --->  " + current_time)

            except Exception as e:
                # error = crt.GetLastErrorMessage()
                # crt.Dialog.MessageBox("[!] exception info :" + str(error) + " --" + str(e))
                # 记录连接错误消息
                errorLogFP.write(str(e)+"\r\n")
                continue

            crt.Screen.IgnoreEscape = True
            crt.Screen.IgnoreCase = True

            # 终端bug，多次发送
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.WaitForString('>')

            current_name = getName()
            # crt.Dialog.MessageBox('[*] currentname:' + str(current_name))

            #  日记记录
            # In such cases where an end user may have already started logging to a file manually (say,
            # before your script has been launched), you should first check to ensure logging isn't already
            # enabled before you attempt to start logging from within your script. If logging has already been
            # started, calling Session.Log will result in an error. For example:
            if crt.Session.Logging:
                crt.Session.Log(False)

            #   去除字符串后面的特殊字符
            logfile = detection_log_dir + current_name.rstrip() + "_" + host.rstrip() + ".log"
            # crt.Dialog.MessageBox("logfile :" + str(logfile))
            crt.Session.LogFileName = logfile
            crt.Session.Log(True)
            # time.sleep(1)


            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.WaitForString('>')
            crt.Screen.Send(command_list[0])
            #  可能有多次more情况，循环处理输出多次空格
            configListener()

            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.WaitForString('>')
            crt.Screen.Send(command_list[1])
            configListener()

            crt.Screen.Send('\r')
            crt.Screen.Send('\r')
            crt.Screen.WaitForString('>')
            time.sleep(3)

            # 发送quit段爱
            crt.Screen.Send("quit\r")



            # time.sleep(2)
            #  关闭标签页 ， 操作不被允许;
            # crt.GetActiveTab().Close()

            time.sleep(1)

    rfile.close()
    errorLogFP.close()

    # 程序执行完成
    crt.Dialog.MessageBox("[+] 脚本已执行，程序结束")


def ssh_method(host):
    command = '/SSH2 /L %s /PASSWORD %s /C 3DES /M MD5 %s' % (user, passwd, host);
    crt.Session.ConnectInTab(command)


def telnet_method(host):
    # 异常处理： ip 不通、login，password 错误或输入超时
    is_login_Success = 1
    is_passwd_Success = 1
    # 拼接命令
    command = "/TELNET {0} 23".format(host)
    # 连接主机
    try:
        crt.Session.Connect(command, True , False)
        # time.sleep(2)
        # 登录过程
        is_login_Success = crt.Screen.WaitForString("login:", 2)
        crt.Screen.Send("{0}\r".format(user))
        is_passwd_Success = crt.Screen.WaitForString("Password:", 2)
        crt.Screen.Send("{0}\r".format(passwd))

        # crt.Dialog.MessageBox("isSuccess: " + str(is_login_Success))

        if is_login_Success <= 0 or is_passwd_Success <= 0:
            raise Exception("[!] Exception Failed to detect login or Password or login account and passwd verify failure from ---> " + host.rstrip())

    except Exception as e:
        # crt.Dialog.MessageBox("[!] Exception : " + str(e))
        raise Exception("[!] Exception : " + str(e).rstrip() + " by --> " + host.rstrip() )



def configListener():
    while True:
        # crt.Screen.WaitForStrings(["  ---- More ----", '<bj'], 10)  "<bj" ？？
        # TODO
        count = crt.Screen.WaitForStrings(["---- More ----","<never-match>"],wait_second)
        # MatchIndex 属性为 WaitForStrings 中匹配的 index 号
        # count 为匹配中次数
        waitindex = crt.Screen.MatchIndex
        if count != 0:
            if waitindex == 1:
                # crt.Dialog.MessageBox(' match: ---- More ----')
                # time.sleep(1)
                crt.Screen.Send(' ')
            elif waitindex == 2:
                # crt.Dialog.MessageBox('match : <never-match> ')
                # time.sleep(1)
                crt.Screen.Send('\r')
                break
        else:
            # crt.Dialog.MessageBox('No match Found')
            # time.sleep(1)
            crt.Screen.Send('\r')
            break



def getName():
    # 拿到当前设备名字
    rowIndex = crt.Screen.CurrentRow
    colindex = crt.Screen.CurrentColumn - 1
    chushi_name = crt.Screen.Get(rowIndex, 1, rowIndex, colindex)
    name = chushi_name.strip('<>')
    return name




main()

