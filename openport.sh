#!/bin/sh

# 1. 自动获取 LAN IP 并剔除掩码 (比如把 10.0.0.1/24 变成 10.0.0.1)
LAN_IP=$(uci get network.lan.ipaddr | cut -d'/' -f1)
PORTS="7681 7766 7676"

show_menu() {
    echo "--------------------------------"
    echo "  OpenWrt 端口转发一键工具"
    echo "  目标 IP: $LAN_IP"
    echo "  操作端口: $PORTS"
    echo "--------------------------------"
    echo " 1) 一键开启转发"
    echo " 2) 一键关闭转发"
    echo " q) 退出"
    echo "--------------------------------"
    printf "请输入选项 [1-2/q]: "
}

do_open() {
    # 再次检查 IP 是否合法，防止为空
    if [ -z "$LAN_IP" ]; then
        echo "❌ 错误：无法获取 LAN IP，请手动检查网络配置。"
        return
    fi

    echo "🚀 正在配置规则..."
    for port in $PORTS; do
        rule_id="multi_port_$port"
        uci delete firewall.$rule_id 2>/dev/null
        
        uci set firewall.$rule_id=redirect
        uci set firewall.$rule_id.name="Forward_$port"
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
    # 加上 -r 参数防止转义，明确指定读取到变量 choice
    read -r choice
    case "$choice" in
        1) do_open ;;
        2) do_close ;;
        q|Q) 
            echo "退出脚本。"
            exit 0 
            ;;
        "") 
            # 如果是空输入，直接跳过，不提示错误，防止刷屏
            continue 
            ;;
        *) 
            echo "⚠️  无效输入 [$choice]，请重新选择" 
            ;;
    esac
    # 增加一个小延迟，防止极端情况下的死循环刷屏
    sleep 0.5
done
