# OpenWrt UCI Parameters Reference

## Overview
OpenWrt's Unified Configuration Interface (UCI) organizes configuration settings into packages, sections, and options. Each package corresponds to a configuration file in `/etc/config/`.

## Common UCI Configuration Files

### 1. Network Configuration (`/etc/config/network`)

**Sections:**
- `config interface` - Network interfaces
- `config device` - Network devices
- `config route` - Static routes
- `config rule` - Routing rules
- `config switch` - Switch configuration
- `config switch_vlan` - VLAN configuration

**Common Options:**
- `option ifname` - Interface name (e.g., 'eth0', 'wlan0')
- `option proto` - Protocol type ('static', 'dhcp', 'pppoe', 'none')
- `option ipaddr` - IP address
- `option netmask` - Subnet mask
- `option gateway` - Default gateway
- `option dns` - DNS servers
- `option macaddr` - MAC address
- `option mtu` - Maximum Transmission Unit
- `option type` - Interface type ('bridge', 'ethernet')
- `option stp` - Spanning Tree Protocol (for bridges)
- `option igmp_snooping` - IGMP snooping (for bridges)

### 2. Wireless Configuration (`/etc/config/wireless`)

**Sections:**
- `config wifi-device` - Wireless radio configuration
- `config wifi-iface` - Wireless interface configuration

**Common Options:**
- `option type` - Driver type ('mac80211', 'prism2')
- `option channel` - Wireless channel
- `option hwmode` - Hardware mode ('11g', '11n', '11ac')
- `option txpower` - Transmission power
- `option country` - Country code
- `option disabled` - Enable/disable radio
- `option ssid` - Network SSID
- `option encryption` - Encryption type ('none', 'psk', 'psk2', 'wep')
- `option key` - Wireless password/key
- `option mode` - Interface mode ('ap', 'sta', 'adhoc', 'mesh')
- `option network` - Associated network interface
- `option hidden` - Hide SSID
- `option isolate` - Client isolation

### 3. Firewall Configuration (`/etc/config/firewall`)

**Sections:**
- `config defaults` - Default firewall settings
- `config zone` - Firewall zones
- `config forwarding` - Zone forwarding rules
- `config rule` - Firewall rules
- `config redirect` - Port forwarding rules
- `config include` - Include other config files

**Common Options:**
- `option input` - Default input policy ('ACCEPT', 'REJECT', 'DROP')
- `option output` - Default output policy
- `option forward` - Default forward policy
- `option name` - Rule/zone name
- `option src` - Source zone/network
- `option dest` - Destination zone/network
- `option src_port` - Source port
- `option dest_port` - Destination port
- `option proto` - Protocol ('tcp', 'udp', 'icmp', 'all')
- `option target` - Rule target ('ACCEPT', 'REJECT', 'DROP')
- `option src_ip` - Source IP address
- `option dest_ip` - Destination IP address
- `option extra` - Additional iptables options

### 4. DHCP Configuration (`/etc/config/dhcp`)

**Sections:**
- `config dnsmasq` - DNS and DHCP server settings
- `config dhcp` - DHCP pool configuration
- `config host` - Static DHCP leases
- `config domain` - Domain configuration

**Common Options:**
- `option domainneeded` - Only forward FQDNs
- `option boguspriv` - Prevent reverse DNS for private ranges
- `option filterwin2k` - Filter Windows-specific DNS requests
- `option local` - Local domain suffix
- `option leasefile` - DHCP lease file location
- `option start` - DHCP pool start address
- `option limit` - Maximum DHCP leases
- `option leasetime` - Lease time duration
- `option ignore` - Ignore interface
- `option interface` - Interface for DHCP
- `option range` - DHCP range
- `option name` - Host name
- `option mac` - MAC address
- `option ip` - Static IP address

### 5. System Configuration (`/etc/config/system`)

**Sections:**
- `config system` - System settings
- `config timeserver` - NTP configuration
- `config led` - LED configuration
- `config button` - Button configuration

**Common Options:**
- `option hostname` - System hostname
- `option timezone` - System timezone
- `option log_size` - Log buffer size
- `option log_proto` - Log protocol ('udp', 'tcp')
- `option server` - NTP server
- `option enabled` - Enable/disable feature
- `option name` - LED/button name
- `option sysfs` - Sysfs path
- `option trigger` - LED trigger
- `option action` - Button action

### 6. LuCI Configuration (`/etc/config/luci`)

**Sections:**
- `config core` - Core LuCI settings
- `config uci` - UCI settings
- `config http` - HTTP server settings

**Common Options:**
- `option lang` - Interface language
- `option mediaurlbase` - Media URL base
- `option resourcebase` - Resource base URL
- `option sessiontime` - Session timeout
- `option main` - Main configuration
- `option state` - Configuration state

### 7. Dropbear Configuration (`/etc/config/dropbear`)

**Sections:**
- `config dropbear` - SSH server settings

**Common Options:**
- `option Port` - SSH port
- `option PasswordAuth` - Password authentication
- `option RootPasswordAuth` - Root password authentication
- `option BannerFile` - Banner file
- `option Interface` - Listen interface

### 8. Uhttpd Configuration (`/etc/config/uhttpd`)

**Sections:**
- `config uhttpd` - Web server settings

**Common Options:**
- `option listen_http` - HTTP listen address
- `option listen_https` - HTTPS listen address
- `option home` - Document root
- `option rfc1918_filter` - RFC1918 filtering
- `option cert` - SSL certificate
- `option key` - SSL private key
- `option cgi_prefix` - CGI prefix
- `option script_timeout` - Script timeout

## Common UCI Commands

```bash
# Show all configurations
uci show

# Show specific package
uci show network
uci show wireless
uci show firewall

# Get specific value
uci get network.lan.ipaddr

# Set specific value
uci set network.lan.ipaddr=192.168.1.1

# Delete option
uci delete network.lan.gateway

# Add new section
uci add network interface
uci set network.@interface[-1].proto=static

# Commit changes
uci commit

# Revert changes
uci revert network

# Export configuration
uci export network > network_backup.txt

# Import configuration
uci import network < network_backup.txt
```

## Configuration File Locations

- `/etc/config/network` - Network interfaces and routing
- `/etc/config/wireless` - Wireless configuration
- `/etc/config/firewall` - Firewall rules
- `/etc/config/dhcp` - DHCP and DNS settings
- `/etc/config/system` - System settings
- `/etc/config/luci` - LuCI web interface
- `/etc/config/dropbear` - SSH server
- `/etc/config/uhttpd` - Web server
- `/etc/config/ntpd` - NTP daemon
- `/etc/config/olsrd` - OLSR mesh networking
- `/etc/config/batman-adv` - B.A.T.M.A.N. mesh
- `/etc/config/olsrd6` - OLSR IPv6
- `/etc/config/olsrd6` - OLSR IPv6
- `/etc/config/olsrd6` - OLSR IPv6

## Notes

- UCI configurations are stored in `/etc/config/` directory
- Changes must be committed with `uci commit` to be persistent
- Use `uci show` to view current configurations
- Use `uci export` to backup configurations
- Use `uci import` to restore configurations
- Some parameters may vary depending on installed packages

