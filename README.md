# Cybersecurity Scripts

A collection of cybersecurity-related scripts, Linux automation tools, reconnaissance utilities, and security testing helpers.

This repository serves as a personal collection of practical tools developed by **ThawSitt** to automate repetitive tasks, improve security workflows, and explore cybersecurity through hands-on scripting.

## About

The goal of this project is to build and maintain reusable scripts for cybersecurity, penetration testing, Linux administration, and network analysis.

Most tools are developed using Bash and Python, with a focus on simplicity, practicality, and ease of use.

## Repository Structure

```text
cybersecurity-scripts/
│
├── kali-linux/
├── reconnaissance/
├── network-analysis/
├── system-administration/
└── utilities/
```

| Directory | Description |
|---|---|
| `kali-linux/` | Kali Linux automation and environment setup scripts |
| `reconnaissance/` | Information gathering and enumeration utilities |
| `network-analysis/` | Network inspection and traffic analysis helpers |
| `system-administration/` | Linux system administration and automation |
| `utilities/` | General-purpose scripts and supporting tools |

*The repository will grow as new scripts and utilities are developed.*

## Available Scripts

### Kali Linux

| Script | Description | Language |
|---|---|---|
| [kali-workspace-setup.sh](kali-linux/kali-workspace-setup.sh) | Automates the startup of a Kali Linux workspace, including Firefox Profile Manager, OpenVPN, and root terminal sessions. | Bash |

For installation instructions, requirements, configuration, and usage examples, see the README inside each category.

## Requirements

Requirements depend on the individual script.

Common requirements may include:

- Kali Linux or another compatible Linux distribution
- Bash
- Python 3
- Required system utilities and dependencies
- Appropriate permissions for privileged operations

Always check the documentation of the individual script before running it.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/ThawSitt/cybersecurity-scripts.git
```

Navigate into the repository:

```bash
cd cybersecurity-scripts
```

Choose a category and follow its README for installation and usage instructions.

For example:

```bash
cd kali-linux
```

## Usage and Safety

These scripts are intended for educational purposes, personal experimentation, system administration, and authorized security testing.

- Only use security tools against systems you own or have explicit permission to test.
- Review scripts before executing them, especially those requiring root privileges.
- Never commit passwords, API keys, private keys, VPN credentials, or other sensitive information.
- Verify dependencies and configuration before running a script.
- Understand what a script does before using it on a production system.

## Contributing

Suggestions, bug reports, and improvements are welcome.

If you would like to contribute:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Test your scripts.
5. Submit a pull request describing your changes.

Please keep scripts organized, documented, and easy to understand.

## Disclaimer

This repository is provided for educational and informational purposes.

The author does not encourage unauthorized access, malicious activity, or the misuse of cybersecurity tools.

Users are solely responsible for ensuring that their activities comply with applicable laws and that they have proper authorization before testing any system.

The author is not responsible for damage, data loss, or misuse resulting from the use of these scripts.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 ThawSitt.

See the LICENSE file for the complete license terms.

## Author

**ThawSitt**

Personal cybersecurity scripting and automation projects.