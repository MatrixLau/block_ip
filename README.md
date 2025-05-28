# block_ip.sh 使用说明

`block_ip.sh` 是一个用于通过 ipset 和 iptables/ip6tables 封禁指定国家 IP 地址访问特定端口的脚本。
修改自https://7li7li.com/archives/1139 ，感谢大佬的付出

## 功能

- 自动检查并安装 `ipset`。
- 从 ipdeny.com 下载指定国家的 IPv4 和 IPv6 IP 地址列表。
- 创建 ipset 规则。
- 添加 iptables 和 ip6tables 规则，封禁来自指定国家 IP 地址对指定端口的访问。

## 使用方法

1.  下载脚本：
    ```bash
    wget https://raw.githubusercontent.com/MatrixLau/block_ip/refs/heads/master/block_ip.sh -O /usr/local/bin/block_ip.sh
    ```

2.  赋予脚本执行权限：
    ```bash
    chmod +x /usr/local/bin/block_ip.sh
    ```

3.  运行脚本：
    ```bash
    sudo /usr/local/bin/block_ip.sh
    ```
    脚本需要 root 权限来安装 ipset 和修改 iptables/ip6tables 规则。

## 配置

您可以通过修改脚本顶部的变量来配置要封禁的国家和端口：

-   `GEOIP`: 指定要封禁的国家代码。默认为 "cn" (中国)。您可以在 [https://www.ipdeny.com/ipblocks/](https://www.ipdeny.com/ipblocks/) 找到其他国家代码。
-   `BLOCKED_PORTS`: 指定要封禁的端口。支持单个端口（如 "22"）、多个端口（如 "22,80,443"）以及端口范围（如 "10000:11000"），也可以混合使用（如 "22,80,443,10000:11000"）。默认为 "1024:65535"。

**示例：**

如果您想封禁来自美国的 IP 地址对 80 和 443 端口的访问，可以将脚本修改为：

```bash
GEOIP="us"
BLOCKED_PORTS="80,443"
```

## 开机自启 (Systemd)

为了让脚本在系统启动时自动运行，您可以创建一个 systemd 服务。

1.  创建服务文件：
    ```bash
    sudo nano /etc/systemd/system/block-ip.service
    ```

2.  将以下内容写入服务文件并保存：
    ```
    [Unit]
    Description=Block IPs Service
    After=network.target

    [Service]
    Type=oneshot
    ExecStart=/usr/local/bin/block_ip.sh
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
    ```

3.  重新加载 systemd 管理器配置：
    ```bash
    sudo systemctl daemon-reload
    ```

4.  启用服务，使其在开机时启动：
    ```bash
    sudo systemctl enable block-ip.service
    ```

5.  立即启动服务：
    ```bash
    sudo systemctl start block-ip.service
    ```

## 注意事项

-   脚本会覆盖之前由本脚本添加的同名 ipset 规则和 iptables/ip6tables 规则。
-   脚本依赖于 ipdeny.com 提供的 IP 地址库，请确保您的服务器可以访问该网站。
-   封禁规则在系统重启后可能会失效，您可能需要将脚本添加到启动项中以实现永久封禁。
-   请谨慎使用本脚本，错误的配置可能导致网络连接问题。
