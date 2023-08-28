# 统计没有巡检的。
#
# 1. 迭代文件目录，提取ip地址翻入数组
# 2. 将excel的ip保存
# 3. 取出补集合 CbA  b是excel数组，a是分析文件目录数组


import os
import re
import pandas as pd

# 指定目录
directory = "C:\\Users\\white\\Desktop\\A设备巡检日志log"
excel_file = "C:\\Users\\white\\Desktop\\detection_Script\\STN-A巡检脚本\\网元信息20230809033055.xlsx"
saveFile = "C:\\Users\\white\\Desktop\\detection_Script\\Resource\\还未巡查的A设备.txt"

# 创建正则表达式模式，用于匹配IPv4地址
pattern = r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'

# 创建集合存储IPv4地址
ipv4_addresses = set()

count = 0

# 迭代目录下的所有文件
for filename in os.listdir(directory):
    filepath = os.path.join(directory, filename)

    if os.path.isfile(filepath):
        # 匹配文件名中的IPv4地址部分
        match = re.match(pattern, filename)

        if match:
            ipv4_address = match.group(1)
            ipv4_addresses.add(ipv4_address)
            count = count + 1

# # 打印存储的IPv4地址
# print(ipv4_addresses)
# print("\n")
# print(count)
# 读取Excel中的"网元IP"列
df = pd.read_excel(excel_file)
excelIpList = df["网元IP"].tolist()
# 将excelIpList转换为集合
excelIpSet = set(excelIpList)
# 计算ipv4_addresses的补集
complement = excelIpSet - ipv4_addresses
print("\n")
print(complement)

with open(saveFile,'w') as fp:
    for ip_address in complement:
        fp.write(ip_address+'\n')

