#!/bin/bash
 
# 定义颜色
Green="\033[32m"
Font="\033[0m"
 
# 内置配置
GEOIP="cn"                 # 要封禁的国家代码
BLOCKED_PORTS="1024:65535" # 要封禁的端口，支持单端口和连续端口混用，例如 "22,80,443,10000:11000"

# IPv4 IP库地址
GEOIP_IPV4_URL="http://www.ipdeny.com/ipblocks/data/countries/$GEOIP.zone"
# IPv6 IP库地址
GEOIP_IPV6_URL="https://www.ipdeny.com/ipv6/ipaddresses/blocks/$GEOIP.zone"

# 检查ipset是否安装
check_ipset() {
    if ! command -v ipset &> /dev/null; then
        echo -e "${Green}正在安装ipset...${Font}"
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y ipset
        elif command -v yum &> /dev/null; then
            yum install -y ipset
        elif command -v dnf &> /dev/null; then
            dnf install -y ipset
        elif command -v apk &> /dev/null; then
            apk add ipset
        else
            echo -e "${Green}无法自动安装 ipset。请手动安装 ipset 后再运行脚本。${Font}"
            exit 1
        fi
    fi
}
 
# 封禁ip函数
block_ipset(){
    check_ipset

    echo -e "${Green}正在下载IPv4 IPs data...${Font}"
    wget -P /tmp $GEOIP_IPV4_URL 2> /dev/null

    if [ ! -f "/tmp/$GEOIP.zone" ]; then
        echo -e "${Green}IPv4 IPs data下载失败，请检查网络连接！${Font}"
        echo -e "${Green}代码查看地址：http://www.ipdeny.com/ipblocks/data/countries/${Font}"
        exit 1
    fi
    echo -e "${Green}IPv4 IPs data下载成功！${Font}"

    echo -e "${Green}正在下载IPv6 IPs data...${Font}"
    wget -P /tmp $GEOIP_IPV6_URL -O /tmp/$GEOIP-ipv6.zone 2> /dev/null

    IPV6_DOWNLOAD_SUCCESS=false
    if [ -f "/tmp/$GEOIP-ipv6.zone" ]; then
        echo -e "${Green}IPv6 IPs data下载成功！${Font}"
        IPV6_DOWNLOAD_SUCCESS=true
    else
        echo -e "${Green}IPv6 IPs data下载失败，请检查网络连接！${Font}"
        echo -e "${Green}代码查看地址：https://www.ipdeny.com/ipv6/ipaddresses/blocks/${Font}"
        echo -e "${Green}警告：IPv6 IPs data下载失败，将只处理IPv4屏蔽。${Font}"
    fi

    # 删除已存在的同名规则（如果存在）
    ipset destroy $GEOIP 2>/dev/null
    if [ "$IPV6_DOWNLOAD_SUCCESS" = true ]; then
        ipset destroy $GEOIP-ipv6 2>/dev/null
    fi

    # 创建并填充 IPv4 规则
    echo -e "${Green}正在创建并填充IPv4 ipset规则...${Font}"
    ipset -N $GEOIP hash:net family inet
    for i in $(cat /tmp/$GEOIP.zone ); do ipset -A $GEOIP $i; done
    rm -f /tmp/$GEOIP.zone
    echo -e "${Green}IPv4 ipset规则添加成功！${Font}"

    # 创建并填充 IPv6 规则 (如果下载成功)
    if [ "$IPV6_DOWNLOAD_SUCCESS" = true ]; then
        echo -e "${Green}正在创建并填充IPv6 ipset规则...${Font}"
        ipset -N $GEOIP-ipv6 hash:net family inet6
        for i in $(cat /tmp/$GEOIP-ipv6.zone ); do ipset -A $GEOIP-ipv6 $i; done # Corrected file path
        rm -f /tmp/$GEOIP-ipv6.zone
        echo -e "${Green}IPv6 ipset规则添加成功！${Font}"
    fi

    echo -e "${Green}即将开始封禁ip！${Font}"

    # 添加 iptables (IPv4) 规则
    echo -e "${Green}正在添加iptables (IPv4) 封禁规则...${Font}"
    # 删除已存在的相同iptables规则（如果存在）
    iptables -D INPUT -p tcp -m set --match-set "$GEOIP" src -m multiport --dports $BLOCKED_PORTS -j DROP 2>/dev/null
    iptables -D INPUT -p udp -m set --match-set "$GEOIP" src -m multiport --dports $BLOCKED_PORTS -j DROP 2>/dev/null

    # 添加新规则
    iptables -I INPUT -p tcp -m set --match-set "$GEOIP" src -m multiport --dports $BLOCKED_PORTS -j DROP
    iptables -I INPUT -p udp -m set --match-set "$GEOIP" src -m multiport --dports $BLOCKED_PORTS -j DROP
    echo -e "${Green}iptables (IPv4) 封禁规则添加成功！${Font}"

    # 添加 ip6tables (IPv6) 规则 (如果下载成功)
    if [ "$IPV6_DOWNLOAD_SUCCESS" = true ]; then
        echo -e "${Green}正在添加ip6tables (IPv6) 封禁规则...${Font}"
        # 删除已存在的相同ip6tables规则（如果存在）
        ip6tables -D INPUT -p tcp -m set --match-set "$GEOIP-ipv6" src -m multiport --dports $BLOCKED_PORTS -j DROP 2>/dev/null
        ip6tables -D INPUT -p udp -m set --match-set "$GEOIP-ipv6" src -m multiport --dports $BLOCKED_PORTS -j DROP 2>/dev/null

        # 添加新规则
        ip6tables -I INPUT -p tcp -m set --match-set "$GEOIP-ipv6" src -m multiport --dports $BLOCKED_PORTS -j DROP
        ip6tables -I INPUT -p udp -m set --match-set "$GEOIP-ipv6" src -m multiport --dports $BLOCKED_PORTS -j DROP
        echo -e "${Green}ip6tables (IPv6) 封禁规则添加成功！${Font}"
    fi

    echo -e "${Green}所指定国家($GEOIP)的IPv4和IPv6 ip在端口${BLOCKED_PORTS}内已封禁！${Font}"
}
 
# 执行封禁
block_ipset
