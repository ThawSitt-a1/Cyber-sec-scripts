
#!/usr/bin/env bash

# ==========================================
# Kali Linux - GNOME Terminal Startup
# Four tabs in one terminal window
# ==========================================

VPN_CONFIG="/home/jack/Downloads/eu-west-3-hthaw0908-regular.ovpn"
VPN_LOCK="/run/lock/thm-openvpn.lock"

# ==========================================
# Check dependencies
# ==========================================

for cmd in gnome-terminal firefox openvpn flock pgrep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing dependency: $cmd"
        exit 1
    fi
done

if [[ ! -f "$VPN_CONFIG" ]]; then
    echo "OpenVPN configuration not found: $VPN_CONFIG"
    exit 1
fi

# ==========================================
# Authenticate sudo
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

if pgrep -x openvpn >/dev/null; then
    echo "OpenVPN is already running."
    echo "Skipping VPN launch to prevent duplicates."
else
    echo "Launching OpenVPN..."

    gnome-terminal \
        --tab \
        --title="OpenVPN" \
        -- bash -c '
            VPN_CONFIG="$1"
            VPN_LOCK="$2"

            echo "Starting OpenVPN..."

            sudo flock -n "$VPN_LOCK" \
                openvpn --config "$VPN_CONFIG"

            STATUS=$?

            echo
            echo "OpenVPN stopped. Exit code: $STATUS"
            read -rp "Press Enter to close..."
            exec bash -i
        ' _ "$VPN_CONFIG" "$VPN_LOCK"
fi

# ==========================================
# Tab 3: Root Shell 1
# ==========================================

gnome-terminal \
    --tab \
    --title="Root Shell 1" \
    -- bash -c '
        sudo -i
        exec bash -i
    '

# ==========================================
# Tab 4: Root Shell 2
# ==========================================

gnome-terminal \
    --tab \
    --title="Root Shell 2" \
    -- bash -c '
        sudo -i
        exec bash -i
    '

echo "Kali workspace startup completed."
