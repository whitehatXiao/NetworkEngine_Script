# coding: utf-8

sourceFilename = "还未巡查的A设备.txt"
destinationFilename = "formatted_ip_list.txt"

ip_list = []
with open(sourceFilename, "r") as file:
    for line in file:
        ip = line.strip()
        ip_list.append('"{}"'.format(ip))

formatted_list = ",\n".join(ip_list)

# 将格式化的IP地址列表保存到文件
with open(destinationFilename, "w") as file:
    file.write(formatted_list)
