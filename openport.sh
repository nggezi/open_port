#!/bin/sh

LAN_IP=$(uci get network.lan.ipaddr | sed 's/\/.*//')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"
PORTS="7681 7766 7676"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

rollback() {
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
    done
    uci commit firewall
}

spinner() {
    pid=$1
    delay=0.1
    spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        for char in $spin; do
            printf "\r${CYAN}[%s]${RESET} 处理中..." "$char"
            sleep $delay
        done
    done
    printf "\r${GREEN}[✓]${RESET} 完成！\n"
}

do_open() {
    echo ""
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
    uci commit firewall || { rollback; echo "${RED}✗ 写入失败${RESET}"; return 1; }
    /etc/init.d/firewall reload &
    spinner $!
    echo "${GREEN}✓ 转发已开启${RESET}"
}

do_close() {
    echo ""
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
    done
    uci commit firewall
    /etc/init.d/firewall reload &
    spinner $!
    echo "${YELLOW}✓ 转发已关闭${RESET}"
}

show_banner() {
    clear
    echo "${CYAN}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║${RESET}     ${BOLD}OpenWrt 端口转发一键工具${RESET}      ${CYAN}║"
    echo "  ║${RESET}         Open Port Forwader         ${CYAN}║"
    echo "  ╚══════════════════════════════════════╝"
    echo "${RESET}"
}

show_menu() {
    show_banner
    echo "  ${BOLD}目标设置${RESET}"
    echo "  ┌──────────────────────────────────────┐"
    printf "  │ ${CYAN}IP:${RESET}   %-30s │\n" "$LAN_IP"
    printf "  │ ${CYAN}端口:${RESET} %-30s │\n" "$PORTS"
    echo "  └──────────────────────────────────────┘"
    echo ""
    echo "  ${BOLD}操作选项${RESET}"
    echo "  ┌──────────────────────────────────────┐"
    echo "  │  ${GREEN}[1]${RESET}  🚀 一键开启转发                  │"
    echo "  │  ${YELLOW}[2]${RESET}  🛑 一键关闭转发                  │"
    echo "  └──────────────────────────────────────┘"
    echo ""
    printf "  ${BOLD}请输入选项 [1/2]:${RESET} "
}

if [ -n "$1" ]; then
    case "$1" in
        open)  do_open ;;
        close) do_close ;;
        *)     echo "用法: $0 {open|close}" ;;
    esac
else
    while true; do
        show_menu
        read -r choice < /dev/tty
        echo ""
        case "$choice" in
            1) do_open ;;
            2) do_close ;;
            q|Q) echo "${CYAN}再见！${RESET}"; break ;;
            *) [ -n "$choice" ] && echo "${RED}⚠ 无效选项: $choice${RESET}" ;;
        esac
        printf "\n  按回车继续..."
        read -r < /dev/tty
    done
fi