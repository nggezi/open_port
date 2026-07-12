#!/bin/sh

LAN_IP=$(uci get network.lan.ipaddr | sed 's/\/.*//')
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"
PORTS="7681 7766 7676"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

CLEAR='\033[H\033[2J'
BOLD='\033[1m'

show_banner() {
    printf '%b' "$CLEAR"
    printf '%b\n' "${CYAN}  ╔════════════════════════════════════════╗"
    printf '%b\n' "${CYAN}  ║${RESET}    ${BOLD}OpenWrt 端口转发管理${RESET}          ${CYAN}║"
    printf '%b\n' "${CYAN}  ║${RESET}        Port Forward Manager         ${CYAN}║"
    printf '%b\n' "${CYAN}  ╚════════════════════════════════════════╝${RESET}"
    printf '\n'
}

show_menu() {
    show_banner
    printf '  %b目标设置%b\n' "$BOLD" "$RESET"
    printf '  ┌────────────────────────────────────────┐\n'
    printf '  │ %b%-10s%b %-29s │\n' "$CYAN" "IP:" "$RESET" "$LAN_IP"
    printf '  │ %b%-10s%b %-29s │\n' "$CYAN" "端口:" "$RESET" "$PORTS"
    printf '  └────────────────────────────────────────┘\n'
    printf '\n'
    printf '  %b操作选项%b\n' "$BOLD" "$RESET"
    printf '  ┌────────────────────────────────────────┐\n'
    printf '  │  %b[1]%b  开启转发                          │\n' "$GREEN" "$RESET"
    printf '  │  %b[2]%b  关闭转发                          │\n' "$YELLOW" "$RESET"
    printf '  │  %b[q]%b  退出                              │\n' "$CYAN" "$RESET"
    printf '  └────────────────────────────────────────┘\n'
    printf '\n'
    printf '  %b请输入选项 [1/2/q]: %b' "$BOLD" "$RESET"
}

do_open() {
    printf '\n'
    for port in $PORTS; do
        rule_id="fwd_rule_$port"
        uci delete firewall.$rule_id 2>/dev/null
        uci set firewall.$rule_id=redirect
        uci set firewall.$rule_id.name="Auto_Forward_$port"
        uci set firewall.$rule_id.src='wan'
        uci set firewall.$rule_id.dest='lan'
        uci set firewall.$rule_id.proto='tcp udp'
        uci set firewall.$rule_id.src_dport="$port"
        uci set firewall.$rule_id.dest_ip="$LAN_IP"
        uci set firewall.$rule_id.dest_port="$port"
        uci set firewall.$rule_id.target='DNAT'
    done
    uci commit firewall || {
        printf '%b\n' "${RED}  ✗ 写入失败${RESET}"
        return 1
    }
    /etc/init.d/firewall restart >/dev/null 2>&1
    printf '%b\n' "${GREEN}  ✓ 转发已开启${RESET}"
}

do_close() {
    printf '\n'
    for port in $PORTS; do
        rule_id="fwd_rule_$port"
        uci delete firewall.$rule_id 2>/dev/null
    done
    if uci commit firewall; then
        /etc/init.d/firewall restart >/dev/null 2>&1
        printf '%b\n' "${YELLOW}  ✓ 转发已关闭${RESET}"
    else
        printf '%b\n' "${RED}  ✗ 操作失败${RESET}"
    fi
}

if [ -n "$1" ]; then
    case "$1" in
        open)  do_open ;;
        close) do_close ;;
        *)     printf '用法: %s {open|close}\n' "$0" ;;
    esac
else
    while true; do
        show_menu
        read -r choice < /dev/tty
        printf '\n'
        case "$choice" in
            1) do_open ;;
            2) do_close ;;
            q|Q) printf '%b\n' "${CYAN}  再见！${RESET}"; break ;;
            *) [ -n "$choice" ] && printf '%b %s\n' "${RED}  ⚠ 无效选项${RESET}" "$choice" ;;
        esac
        printf '\n  %b按回车继续...%b' "$BOLD" "$RESET"
        read -r < /dev/tty
    done
fi