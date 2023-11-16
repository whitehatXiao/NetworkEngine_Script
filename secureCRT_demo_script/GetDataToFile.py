# $language = "python"
# $interface = "1.0"

# This script demonstrates how to capture line by line output from a
# command sent to a server. It then saves each line of output to a file.
# This script shows how the 'WaitForStrings' command can be used to wait
# for multiple possible outputs.

import time
import os

def main():


    # Open a file for writing.
    #
    # filename = os.path.join(os.environ['TEMP'], 'output.txt')
    filename = "error_info.log"
    fp = open(filename, "wb+")

    # 提取变量
    host = "192.168.56.10"
    user = "admin"
    passwd = "admin"

    # objTab = crt.GetScriptTab()
    crt.Screen.Synchronous = True
    # 拼接命令
    command = "/TELNET {0} 23".format(host)
    # 连接主机
    crt.Session.Connect(command)
    time.sleep(2)
# 登录过程
    crt.Screen.WaitForString("login:",2)
    crt.Screen.Send("{0}\r".format(user))
    crt.Screen.WaitForString("Password:",2)
    crt.Screen.Send("{0}\r".format(passwd))
    time.sleep(2)


    # Send the initial command then throw out the first linefeed that we
    # see by waiting for it.
    #
    crt.Screen.Send('display ip inter brief \r')
    crt.Screen.WaitForString(">")

    # Create an array of strings to wait for.
    #
    # row = 1

    # while True:

        # Wait for the linefeed at the end of each line, or the shell
        # prompt that indicates we're done.
        #
        # result = crt.Screen.WaitForStrings( waitStrs )
        #
        # # If we saw the prompt, we're done.
        # if result == 2:
        #     break

        # The result was 1 (we got a linefeed, indicating that we
        # received another line of of output). Fetch current row number
        # of the cursor and read the first 20 characters from the screen
        # on that row.
        #
        # This shows how the 'Get' function can be used to read
        # line-oriented output from a command, Subtract 1 from the
        # currentRow to since the linefeed moved currentRow down by one.
        #

    screenrow = crt.Screen.CurrentRow - 1

    crt.Dialog.MessageBox("screenrow："+str(screenrow))

    readline = crt.Screen.Get(screenrow, 1, screenrow, 40)

    crt.Dialog.MessageBox("screen Get ："+str(readline))


        # NOTE: We read 20 characters from the screen 'readline' may
        # contain trailing whitespace if the data was less than 20
        # characters wide.

        # Write the line out with an appended end-of-line sequence
    fp.write(readline + os.linesep)

    crt.Screen.Synchronous = False


main()