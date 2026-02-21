#!/bin/sh

# 自动获取当前路由器的 LAN IP (通常是 192.168.1.1)
# 这样无论在哪个路由器跑，都会转发给自己
LAN_IP=$(uci get network.lan.ipaddr)
PORTS="7681 7766 7676"

show_menu() {
    echo "=============================="
    echo "   OpenWrt 端口一键开关工具"
    echo "   目标 IP: $LAN_IP"
    echo "=============================="
    echo " 1) 开启转发 (外部=内部)"
    echo " 2) 关闭并清理规则"
    echo " q) 退出"
    echo "------------------------------"
    printf "请选择 [1-2/q]: "
}

do_open() {
    echo "正在添加规则..."
    for port in $PORTS; do
        rule_name="autofwd_$port"
        # 先尝试删除旧的，防止重复
        uci delete firewall.$rule_name 2>/dev/null
        
        uci set firewall.$rule_name=redirect
        uci set firewall.$rule_name.name="AutoForward_$port"
        uci set firewall.$rule_name.src='wan'
        uci set firewall.$rule_name.dest='lan'
        uci set firewall.$rule_name.proto='tcp udp'
        uci set firewall.$rule_name.src_dport="$port"   # 外部访问端口
        uci set firewall.$rule_name.dest_ip="$LAN_IP"   # 转发给谁
        uci set firewall.$rule_name.dest_port="$port"  # 内部实际端口
        uci set firewall.$rule_name.target='DNAT'
    done
    uci commit firewall
    /etc/init.d/firewall restart
    echo "✅ 端口 $PORTS 已全部开启！"
}

do_close() {
    echo "正在删除规则..."
    for port in $PORTS; do
        uci delete firewall."autofwd_$port" 2>/dev/null
    done
    uci commit firewall
    /etc/init.d/firewall restart
    echo "❌ 规则已清理完毕。"
}

# 循环逻辑
while true; do
    show_menu
    read choice
    case "$choice" in
        1) do_open ;;
        2) do_close ;;
        q|Q) exit 0 ;;
        *) echo "无效选项，请重试。" ;;
    esac
    echo ""
done
