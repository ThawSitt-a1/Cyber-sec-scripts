# Kali Workspace Setup

**Author:** ThawSitt 
**Country:** Myanmar
**Script:** `kali-workspace-setup.sh`  
**Platform:** Kali Linux  
**Shell:** Bash

## Overview

A Bash automation script that prepares a Kali Linux working environment by launching commonly used applications and terminal sessions.

The script is designed to reduce repetitive manual setup when starting a cybersecurity or penetration testing session.

### Features

- Checks whether required applications are installed.
- Verifies that the OpenVPN configuration file exists.
- Authenticates sudo before launching terminal sessions.
- Opens Firefox Profile Manager with a separate Firefox process.
- Launches an OpenVPN connection in a dedicated terminal.
- Opens two separate root terminal sessions.
- Keeps terminal sessions available for further commands.

## Requirements

- Kali Linux
- Bash
- GNOME Terminal
- Firefox
- OpenVPN
- A valid OpenVPN configuration file
- A user account with sudo privileges

## Configuration

Before running the script, update the VPN configuration path:

```bash
VPN_CONFIG="file path to your OpenVPN configuration file.ovpn"
```

Replace the path with the location of your own `.ovpn` configuration file.

## Installation

Clone the repository:

```bash
git clone https://github.com/ThawSitt/cybersecurity-scripts.git
```

Navigate to the script directory:

```bash
cd cybersecurity-scripts/kali-linux
```

Make the script executable:

```bash
chmod +x kali-workspace-setup.sh
```

## Usage

Run the script as your normal user:

```bash
./kali-workspace-setup.sh
```

**Do not run the entire script using `sudo`.** The script requests sudo authentication when necessary. Running the whole script as root can cause Firefox to launch with the wrong user permissions.

## Important Notes

- Firefox Profile Manager launches as a separate graphical application, not inside a terminal tab.
- The OpenVPN session runs with root privileges.
- The two additional terminal sessions open interactive root shells.
- The script relies on your sudo timestamp configuration if you want authentication to be reused across terminal sessions.
- GNOME Terminal may attach separately requested tabs to different windows depending on the active window.

## Security Considerations

- Never hardcode your sudo password in this script.
- Do not commit private VPN configuration files, credentials, certificates, or private keys.
- Review your sudo configuration before enabling shared authentication timestamps.
- Use root privileges only when necessary.

## Author

**ThawSitt**

Part of the Cybersecurity Scripts collection.