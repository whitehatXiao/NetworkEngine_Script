# $language = "python"
# $interface = "1.0"

# This script demonstrates how Python scripting can be used to interact
# with CRT and manipulate an spreadsheet file (for reading by other
# programs such as Microsoft Excel). This script uses Python's csv library
# to create a spreadsheet, then it sends a command to a remote server
# (assuming we're already connected). It reads the output, parses it and
# writes out some of the data to the spreadsheet and saves it.  This
# script also demonstrates how the WaitForStrings function can be used to
# wait for more than one output string.
#
import os
import csv
import time


def main():

    crt.Screen.Synchronous = True

    # Create an Excel compatible spreadsheet
    #

    # current_dir = os.getcwd() # 中文乱码
    # crt.Dialog.MessageBox(current_dir)
    # filename = os.path.join(os.environ['TEMP'], 'chart.csv')
    filename = "chart.csv"
    fileobj = open(filename, 'wb')

    worksheet = csv.writer(fileobj)

    # 提取变量
    host = "192.168.56.10"
    username = "admin"
    password = "admin"

    # 拼接命令
    command = "/TELNET {0} 23".format(host)

    # 连接主机
    crt.Session.Connect(command)
    time.sleep(2)



    # Send the initial command to run and wait for the first linefeed
    #
    crt.Screen.Send("dis ip int brief \n")
    crt.Screen.WaitForString(">")

    # Create an array of strings to wait for.
    #
    # promptStr = "linux$"
    # waitStrs = [ "\n", promptStr ]

    # row = 1

    # while True:

        # Wait for the linefeed at the end of each line, or the shell
        # prompt that indicates we're done.
        #
        # result = crt.Screen.WaitForStrings( waitStrs )

        # We saw the prompt, we're done.
        #
        # if result == 2:
        #     break

        # Fetch current row and read the first 40 characters from the
        # screen on that row. Note, since we read a linefeed character
        # subtract 1 from the return value of CurrentRow to read the
        # actual line.
        #

    screenrow = crt.Screen.CurrentRow - 1

    crt.Dialog.MessageBox("screenrow："+str(screenrow))

    readline = crt.Screen.Get(screenrow, 1, screenrow, 40)

    crt.Dialog.MessageBox("screen Get ："+str(readline))



    # Split the line ( ":" delimited) and put some fields into Excel
    #
    # items = readline.split(":")
    worksheet.writerow(readline)

    # row = row + 1


    fileobj.close()
    crt.Screen.Synchronous = False


main()