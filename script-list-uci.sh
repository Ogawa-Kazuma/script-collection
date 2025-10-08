#!/bin/bash

# OpenWrt UCI Parameters List Script
# This script provides comprehensive information about OpenWrt UCI parameters

echo "=== OpenWrt UCI Parameters Explorer ==="
echo "========================================"
echo

# Function to display UCI help
show_uci_help() {
    echo "UCI Command Help:"
    echo "-----------------"
    uci -h 2>/dev/null || echo "UCI command not available or not in PATH"
    echo
}

# Function to list all UCI configurations
list_all_uci_configs() {
    echo "All UCI Configurations:"
    echo "======================"
    uci show 2>/dev/null || echo "Unable to show UCI configurations"
    echo
}

# Function to list specific UCI packages
list_uci_packages() {
    echo "Available UCI Packages:"
    echo "======================"
    ls /etc/config/ 2>/dev/null | while read config_file; do
        echo "- $config_file"
    done
    echo
}

# Function to show network configuration
show_network_config() {
    echo "Network Configuration:"
    echo "====================="
    uci show network 2>/dev/null || echo "Network configuration not available"
    echo
}

# Function to show wireless configuration
show_wireless_config() {
    echo "Wireless Configuration:"
    echo "======================"
    uci show wireless 2>/dev/null || echo "Wireless configuration not available"
    echo
}

# Function to show firewall configuration
show_firewall_config() {
    echo "Firewall Configuration:"
    echo "======================"
    uci show firewall 2>/dev/null || echo "Firewall configuration not available"
    echo
}

# Function to show system configuration
show_system_config() {
    echo "System Configuration:"
    echo "===================="
    uci show system 2>/dev/null || echo "System configuration not available"
    echo
}

# Function to show DHCP configuration
show_dhcp_config() {
    echo "DHCP Configuration:"
    echo "=================="
    uci show dhcp 2>/dev/null || echo "DHCP configuration not available"
    echo
}

# Function to show all configuration files
show_all_config_files() {
    echo "All Configuration Files:"
    echo "========================"
    for config_file in /etc/config/*; do
        if [ -f "$config_file" ]; then
            echo "File: $(basename $config_file)"
            echo "Content:"
            cat "$config_file" 2>/dev/null | head -20
            echo "---"
        fi
    done
    echo
}

# Function to show UCI schema information
show_uci_schema() {
    echo "UCI Schema Information:"
    echo "======================"
    find /usr/share/uci-defaults/ -name "*.sh" 2>/dev/null | head -10 | while read schema_file; do
        echo "Schema: $(basename $schema_file)"
    done
    echo
}

# Main execution
case "${1:-all}" in
    "help")
        show_uci_help
        ;;
    "all")
        show_uci_help
        list_uci_packages
        list_all_uci_configs
        ;;
    "network")
        show_network_config
        ;;
    "wireless")
        show_wireless_config
        ;;
    "firewall")
        show_firewall_config
        ;;
    "system")
        show_system_config
        ;;
    "dhcp")
        show_dhcp_config
        ;;
    "files")
        show_all_config_files
        ;;
    "schema")
        show_uci_schema
        ;;
    *)
        echo "Usage: $0 [help|all|network|wireless|firewall|system|dhcp|files|schema]"
        echo
        echo "Options:"
        echo "  help     - Show UCI command help"
        echo "  all      - Show all UCI configurations (default)"
        echo "  network  - Show network configuration"
        echo "  wireless - Show wireless configuration"
        echo "  firewall - Show firewall configuration"
        echo "  system   - Show system configuration"
        echo "  dhcp     - Show DHCP configuration"
        echo "  files    - Show all configuration files"
        echo "  schema   - Show UCI schema information"
        ;;
esac

