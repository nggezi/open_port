#!/bin/sh

LAN_IP=$(uci get network.lan.ipaddr | sed 's/\/.*//')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"
PORTS="7681 7766 7676"

rollback() {
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
    done
    uci commit firewall
}

do_open() {
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
        uci set firewall.fwd_rule_$port=redirect
        uci set firewall.fwd_rule_$port.name="Auto_Forward_$port"
        uci set firewall.fwd_rule_$port.src='wan'
        uci set firewall.fwd_rule_$port.dest='lan'
        uci set firewall.fwd_rule_$port.proto='tcp udp'
        uci set firewall.fwd_rule_$port.src_dport="$port"
        uci set firewall.fwd_rule_$port.dest_ip="$LAN_IP"
        uci set firewall.fwd_rule_$port.dest_port="$port"
        uci set firewall.fwd_rule_$port.target='DNAT'
    done
    uci commit firewall || { rollback; echo "❌ 写入失败"; return 1; }
    /etc/init.d/firewall reload
    echo "✅ 转发已开启"
}

do_close() {
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
    done
    uci commit firewall
    /etc/init.d/firewall reload
    echo "❌ 转发已关闭"
}

if [ -n "$1" ]; then
    case "$1" in
        open)  do_open ;;
        close) do_close ;;
        *)     echo "用法: $0 {open|close}" ;;
    esac
else
    show_menu() {
        echo "--------------------------------"
        echo "  OpenWrt 端口转发一键工具"
        echo "  当前目标 IP: $LAN_IP"
        echo "  操作端口: $PORTS"
        echo "--------------------------------"
        echo " 1) 一键开启转发"
        echo " 2) 一键关闭转发"
        echo " q) 退出"
        echo "--------------------------------"
        printf "请输入选项 [1, 2, q]: "
    }
    while true; do
        show_menu
        read -r choice < /dev/tty
        case "$choice" in
            1) do_open ;;
            2) do_close ;;
            q|Q) echo "退出"; break ;;
            *) [ -n "$choice" ] && echo "⚠️ 无效选项: $choice" ;;
        esac
        echo ""
    done
fi