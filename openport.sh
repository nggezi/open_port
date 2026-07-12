#!/bin/sh

LAN_IP=$(uci get network.lan.ipaddr | sed 's/\/.*//')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"
PORTS="7681 7766 7676"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

rollback() {
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
    done
    uci commit firewall
}

spinner() {
    pid=$1
    spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        for char in $spin; do
            printf "\r${CYAN}%s${RESET}" "$char"
            sleep 1
        done
    done
    printf "\r${GREEN}✓${RESET}  \n"
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
    uci commit firewall || { rollback; printf "${RED}✗ 写入失败${RESET}\n"; return 1; }
    /etc/init.d/firewall reload &
    spinner $!
    printf "${GREEN}✓ 转发已开启${RESET}\n"
}

do_close() {
    echo ""
    for port in $PORTS; do
        uci delete firewall.fwd_rule_$port 2>/dev/null
    done
    uci commit firewall
    /etc/init.d/firewall reload &
    spinner $!
    printf "${YELLOW}✓ 转发已关闭${RESET}\n"
}

show_banner() {
    clear
    printf '\033[0;36m  ╔══════════════════════════════════════╗\n'
    printf '\033[0m  ║     \033[1mOpenWrt 端口转发一键工具\033[0m      \033[0;36m║\n'
    printf '\033[0m  ║         Open Port Forwader         \033[0;36m║\n'
    printf '\033[0m  ╚══════════════════════════════════════╝\n'
    printf '\033[0m\n'
}

show_menu() {
    show_banner
    printf "  ${BOLD}目标设置${RESET}\n"
    printf "  ┌──────────────────────────────────────┐\n"
    printf "  │ ${CYAN}IP:${RESET}   %-30s │\n" "$LAN_IP"
    printf "  │ ${CYAN}端口:${RESET} %-30s │\n" "$PORTS"
    printf "  └──────────────────────────────────────┘\n"
    echo ""
    printf "  ${BOLD}操作选项${RESET}\n"
    printf "  ┌──────────────────────────────────────┐\n"
    printf "  │  ${GREEN}[1]${RESET}  🚀 一键开启转发                  │\n"
    printf "  │  ${YELLOW}[2]${RESET}  🛑 一键关闭转发                  │\n"
    printf "  └──────────────────────────────────────┘\n"
    echo ""
    printf "  ${BOLD}请输入选项 [1/2]:${RESET} "
}

if [ -n "$1" ]; then
    case "$1" in
        open)  do_open ;;
        close) do_close ;;
        *)     printf "用法: $0 {open|close}\n" ;;
    esac
else
    while true; do
        show_menu
        read -r choice < /dev/tty
        echo ""
        case "$choice" in
            1) do_open ;;
            2) do_close ;;
            q|Q) printf "${CYAN}再见！${RESET}\n"; break ;;
            *) [ -n "$choice" ] && printf "${RED}⚠ 无效选项: $choice${RESET}" ;;
        esac
        printf "\n  按回车继续..."
        read -r < /dev/tty
    done
fi