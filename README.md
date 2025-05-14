# block_ip.sh 使用说明

`block_ip.sh` 是一个用于通过 ipset 和 iptables/ip6tables 封禁指定国家 IP 地址访问特定端口的脚本。

## 功能

- 自动检查并安装 `ipset`。
- 从 ipdeny.com 下载指定国家的 IPv4 和 IPv6 IP 地址列表。
- 创建 ipset 规则。
- 添加 iptables 和 ip6tables 规则，封禁来自指定国家 IP 地址对指定端口的访问。

## 使用方法

1.  下载脚本：
    ```bash
    wget https://raw.githubusercontent.com/your_repo/your_branch/block_ip/block_ip.sh -O block_ip.sh
    ```
    *(请将 `https://raw.githubusercontent.com/your_repo/your_branch/block_ip/block_ip.sh` 替换为脚本的实际下载地址)*

2.  赋予脚本执行权限：
    ```bash
    chmod +x block_ip.sh
    ```

3.  运行脚本：
    ```bash
    sudo ./block_ip.sh
    ```
    脚本需要 root 权限来安装 ipset 和修改 iptables/ip6tables 规则。

## 配置

您可以通过修改脚本顶部的变量来配置要封禁的国家和端口：

-   `GEOIP`: 指定要封禁的国家代码。默认为 "cn" (中国)。您可以在 [http://www.ipdeny.com/ipblocks/data/countries/](http://www.ipdeny.com/ipblocks/data/countries/) 找到其他国家代码。
-   `BLOCKED_PORTS`: 指定要封禁的端口。支持单个端口（如 "22"）、多个端口（如 "22,80,443"）以及端口范围（如 "10000:11000"），也可以混合使用（如 "22,80,443,10000:11000"）。默认为 "1024:65535"。

**示例：**

如果您想封禁来自美国的 IP 地址对 80 和 443 端口的访问，可以将脚本修改为：

```bash
GEOIP="us"
BLOCKED_PORTS="80,443"
```

## 注意事项

-   脚本会覆盖之前由本脚本添加的同名 ipset 规则和 iptables/ip6tables 规则。
-   脚本依赖于 ipdeny.com 提供的 IP 地址库，请确保您的服务器可以访问该网站。
-   封禁规则在系统重启后可能会失效，您可能需要将脚本添加到启动项中以实现永久封禁。
-   请谨慎使用本脚本，错误的配置可能导致网络连接问题。
