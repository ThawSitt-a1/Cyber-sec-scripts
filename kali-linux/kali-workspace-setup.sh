#!/usr/bin/env bash

# ==================================================
# Script:       kali-workspace-setup.sh
# Author:       ThawSitt
# Description:  Automates Kali Linux workspace startup.
#               Launches Firefox Profile Manager,
#               OpenVPN, and root terminal sessions.
# Platform:     Kali Linux
# Shell:        Bash
# ==================================================

VPN_CONFIG="/home/jack/Downloads/eu-west-3-hthaw0908-regular.ovpn"

# ==========================================
# Check dependencies
# ==========================================

if ! command -v gnome-terminal >/dev/null 2>&1; then
    echo "GNOME Terminal not found!"
    exit 1
fi

if ! command -v firefox >/dev/null 2>&1; then
    echo "Firefox not found!"
    exit 1
fi

if [[ ! -f "$VPN_CONFIG" ]]; then
    echo "OpenVPN configuration not found: $VPN_CONFIG"
    exit 1
fi

# ==========================================
# Authenticate sudo once
# ==========================================

echo "Authenticating sudo..."
if ! sudo -v; then
    echo "Sudo authentication failed!"
    exit 1
fi

# ==========================================
# Tab 1: Firefox Profile Manager
# ==========================================

echo "Launching Firefox Profile Manager..."
firefox -P -no-remote &

# ==========================================
# Tab 2: OpenVPN
# ==========================================

gnome-terminal \
    --tab \
    --title="OpenVPN" \
    -- bash -c "
        sudo su -c 'openvpn --config \"$VPN_CONFIG\"'
        echo
        read -rp 'OpenVPN stopped. Press Enter to continue...'
        exec bash -i
    "

# ==========================================
# Tab 3: Root Shell 1
# ==========================================

gnome-terminal \
    --tab \
    --title="Root Shell 1" \
    -- bash -c '
        sudo su
        exec bash -i
    '

# ==========================================
# Tab 4: Root Shell 2
# ==========================================

gnome-terminal \
    --tab \
    --title="Root Shell 2" \
    -- bash -c '
        sudo su
        exec bash -i
    '

echo "Kali workspace startup completed."
                                        