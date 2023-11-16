command_list = [
    "sys \r",
    "undo local-user admin class manage \r",
    "attack-defense login reauthentication-delay 5 \r",
    "snmp-agent target-host trap address udp-domain 4.108.253.45 vpn-instance __mgnt_vpn__ params securityname ipran@)!# v2c \r",
    "quit \r",
    "save force \r",
    "reset counters interface \r",
    "screen-length disable \r",
    "dis diagnostic-information \r",
    "n \r"
]

for command in command_list:
    print(command)

