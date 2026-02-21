#!/bin/sh

# === 自动获取 LAN IP (通常是 192.168.1.1) ===
# 脚本会自动尝试获取当前路由器的 LAN IP 作为默认转发目标
DEFAULT_TARGET=$(uci get network.lan.ipaddr)

# 需要操作的端口列表
PORTS="7681 7766 7676"

show_menu() {
    echo "--------------------------------"
    echo "  OpenWrt 端口转发一键工具"
    echo "  目标 IP: $DEFAULT_TARGET"
    echo "  操作端口: $PORTS"
    echo "--------------------------------"
    echo " 1) 一键开启转发"
    echo " 2) 一键关闭转发"
    echo " q) 退出"
    echo "--------------------------------"
    printf "请输入选项 [1-2/q]: "
}

do_open() {
    echo "🚀 正在配置规则..."
    for port in $PORTS; do
        rule_id="multi_port_$port"
        # 先清理旧规则
        uci delete firewall.$rule_id 2>/dev/null
        
        # 写入新规则
        uci set firewall.$rule_id=redirect
        uci set firewall.$rule_id.name="Forward_$port"
        uci set firewall.$rule_id.src='wan'
        uci set firewall.$rule_id.dest='lan'
        uci set firewall.$rule_id.proto='tcp udp'
        uci set firewall.$rule_id.src_dport="$port"
        uci set firewall.$rule_id.dest_ip="$DEFAULT_TARGET"
        uci set firewall.$rule_id.dest_port="$port"
        uci set firewall.$rule_id.target='DNAT'
    done
    uci commit firewall
    /etc/init.d/firewall restart
    echo "✅ 转发已开启！"
}

do_close() {
    echo "🛑 正在清理规则..."
    for port in $PORTS; do
        rule_id="multi_port_$port"
        uci delete firewall.$rule_id 2>/dev/null
    done
    uci commit firewall
    /etc/init.d/firewall restart
    echo "❌ 转发已关闭！"
}

# 循环显示菜单
while true; do
    show_menu
    read choice
    case $choice in
        1) do_open ;;
        2) do_close ;;
        q|Q) exit 0 ;;
        *) echo "无效输入，请重新选择" ;;
    esac
    echo ""
done
