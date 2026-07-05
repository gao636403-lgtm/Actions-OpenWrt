#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
##-----------------Del duplicate packages------------------
rm -rf feeds/packages/net/open-app-filter
##-----------------Add OpenClash meta core------------------
curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
chmod +x /tmp/clash >/dev/null 2>&1
mkdir -p feeds/luci/applications/luci-app-openclash/root/etc/openclash/core
mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_meta >/dev/null 2>&1
rm -rf /tmp/clash.tar.gz >/dev/null 2>&1
##-----------------Delete DDNS's examples-----------------
sed -i '/myddns_ipv4/,$d' feeds/packages/net/ddns-scripts/files/etc/config/ddns
##-----------------Manually set CPU frequency for MT7981B-----------------
sed -i '/"mediatek"\/\*|\"mvebu"\/\*/{n; s/.*/\tcpu_freq="1.3GHz" ;;/}' package/emortal/autocore/files/generic/cpuinfo
# ===== RAX3000M NAND custom first boot settings =====
mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-custom-settings <<'EOF'
#!/bin/sh

ROOT_PASSWORD='789998abcC@'

WIFI_SSID='money99999999'
WIFI_PASSWORD='13860775850'

PPPOE_USERNAME='057993300017'
PPPOE_PASSWORD='304975'

# 设置 root 密码
if [ -n "$ROOT_PASSWORD" ]; then
  (echo "$ROOT_PASSWORD"; sleep 1; echo "$ROOT_PASSWORD") | passwd root
fi

# 设置 LAN IP
uci set network.lan.ipaddr='192.168.3.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 设置 PPPoE
if [ -n "$PPPOE_USERNAME" ] && [ -n "$PPPOE_PASSWORD" ]; then
  uci set network.wan.proto='pppoe'
  uci set network.wan.username="$PPPOE_USERNAME"
  uci set network.wan.password="$PPPOE_PASSWORD"
  uci commit network
fi

# 设置 WiFi：纯 WPA3
uci set wireless.@wifi-device[0].disabled='0'
uci set wireless.@wifi-device[1].disabled='0' 2>/dev/null

uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-iface[0].ssid="$WIFI_SSID"
uci set wireless.@wifi-iface[0].encryption='sae'
uci set wireless.@wifi-iface[0].key="$WIFI_PASSWORD"

uci set wireless.@wifi-iface[1].disabled='0' 2>/dev/null
uci set wireless.@wifi-iface[1].ssid="$WIFI_SSID" 2>/dev/null
uci set wireless.@wifi-iface[1].encryption='sae' 2>/dev/null
uci set wireless.@wifi-iface[1].key="$WIFI_PASSWORD" 2>/dev/null

uci commit wireless

exit 0
EOF

chmod +x files/etc/uci-defaults/99-custom-settings
