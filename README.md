# Open Port

OpenWrt 端口转发管理工具

## 界面预览

```
  ╔════════════════════════════════════════╗
  ║    OpenWrt 端口转发管理          ║
  ║        Port Forward Manager         ║
  ╚════════════════════════════════════════╝

  目标设置
  ┌────────────────────────────────────────┐
  │ IP:       192.168.1.1                  │
  │ 端口:     7681 7766 7676               │
  └────────────────────────────────────────┘

  操作选项
  ┌────────────────────────────────────────┐
  │  [1]  开启转发                          │
  │  [2]  关闭转发                          │
  │  [q]  退出                              │
  └────────────────────────────────────────┘

  请输入选项 [1/2/q]:
```

## 功能

- 自动获取路由器 LAN IP（支持 `/24` 等掩码格式）
- 一键开启/关闭多个端口的 WAN→LAN 端口转发
- 支持 TCP/UDP 协议
- 美观的交互界面

## 使用方法

### 交互模式

```sh
wget -qO- https://raw.githubusercontent.com/nggezi/open_port/main/openport.sh | sh
```

### 命令行模式

```sh
# 开启转发
wget -qO- https://raw.githubusercontent.com/nggezi/open_port/main/openport.sh | sh -s open

# 关闭转发
wget -qO- https://raw.githubusercontent.com/nggezi/open_port/main/openport.sh | sh -s close
```

## 配置

默认转发端口：`7681`、`7766`、`7676`

如需修改，编辑脚本第 4 行：

```sh
PORTS="7681 7766 7676"
```

## 安全提示

- 开启转发后，端口将暴露到外网，请确认来源可信
- 建议仅在需要时开启，使用后及时关闭