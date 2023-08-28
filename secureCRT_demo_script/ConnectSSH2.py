# $language = "python"
# $interface = "1.0"

# Connect to an SSH server using the SSH2 protocol. Specify the
# username and password and hostname on the command line as well as
# some SSH2 protocol specific options.

import time
import os
import csv



# host = ""
user = "admin"
passwd = "admin"

def main():
    # Prompt for a password instead of embedding it in a script...
    #
    # passwd = crt.Dialog.Prompt("Enter password for " + host, "Login", "", True)

    # Build a command-line string to pass to the Connect method.

    with open("../Resource/ip.txt", 'r') as rfile:
        host_list = rfile.readlines()
        for host in host_list:
            cmd = "/SSH2 /L %s /PASSWORD %s /C 3DES /M MD5 %s" % (user, passwd, host)
            try:
                crt.Session.Connect(cmd)
            except Exception as e:
                errcode = crt.GetLastError()
                crt.Dialog.MessageBox("[-] errcode:"+str(e))
                continue  # 记录日记信息，继续向下执行
    rfile.close()


main()