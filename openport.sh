#!/bin/sh

# 1. 核心修复：提取纯 IP，剔除 /24 等掩码
# 使用 sed 过滤掉斜杠及其后面的内容
LAN_IP=$(uci get network.lan.ipaddr | sed 's/\/.*//')
PORTS="7681 7766 7676"

# 如果获取不到 IP，给一个保底值
[ -z "$LAN_IP" ] && LAN_IP="192.168.1.1"

show_menu() {
    echo "--------------------------------"
    echo "  OpenWrt 端口转发一键工具"
    echo "  当前目标 IP: $LAN_IP"
    echo "  操作端口: $PORTS"
    echo "--------------------------------"
    echo " 1) 🚀 一键开启转发"
    echo " 2) 🛑 一键关闭转发"
    echo " q) 退出"
    echo "--------------------------------"
    printf "请输入选项 [1, 2, q]: "
}

do_open() {
    echo "正在写入防火墙规则..."
    for port in $PORTS; do
        rule_id="fwd_rule_$port"
        # 先清理同名规则
        uci delete firewall.$rule_id 2>/dev/null

        # 建立新规则
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
    uci commit firewall
    /etc/init.d/firewall restart
    echo "✅ 转发已开启！外网现在可以访问了。"
}

do_close() {
    echo "正在清理规则..."
    for port in $PORTS; do
        rule_id="fwd_rule_$port"
        uci delete firewall.$rule_id 2>/dev/null
    done
    uci commit firewall
    /etc/init.d/firewall restart
    echo "❌ 转发已关闭。"
}

# 循环显示菜单
while true; do
    show_menu
    # 修复：增加判断，防止在某些终端下 read 自动跳过
    read -r choice < /dev/tty

    case "$choice" in
        1)
            do_open
            ;;
        2)
            do_close
            ;;
        q|Q)
            echo "退出脚本。"
            break
            ;;
        *)
            # 只有在确实有输入时才报错，防止刷屏
            if [ -n "$choice" ]; then
                echo "⚠️ 无效选项: $choice"
            fi
            ;;
    esac
    echo ""
done