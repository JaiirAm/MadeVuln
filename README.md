# MadeVuln
This Bash script automates the process of configuring a Linux machine to be intentionally vulnerable. It supports both Debian-based and Red Hat-based systems and allows easy toggling between a vulnerable state and a secure state.

## Features

- Detects and supports Debian-based (e.g., Ubuntu, Kali) and Red Hat-based (e.g., CentOS, RHEL) Linux distributions
- Installs required packages: Apache, PHP, MariaDB, OpenSSH, and DVWA
- Configures SSH to allow password authentication and root login (insecure configuration)
- Sets up DVWA with an open database and weak credentials
- Configures the firewall to allow HTTP (80), SSH (22), and MySQL (3306)
- Provides an option to restore the system to a secure state by uninstalling services and reverting configurations

## Prerequisites

- Ensure the script is run as a user with sudo privileges

## Usage

### To Set Up a Vulnerable Environment

```bash
./setup.sh --vuln
```

This will:
- Install and configure required services (Apache, PHP, MariaDB, OpenSSH)
- Set up DVWA and prepare the database
- Weaken SSH security settings (enable root login and password authentication)
- Adjust the firewall to allow necessary ports

### To Restore a Secure State

```bash
./setup.sh --fix
```

This will:
- Uninstall DVWA and related services
- Restore secure SSH configurations
- Reinforce the firewall settings

## Example Workflow

1. Run the script to create a vulnerable system:

```bash
chmod +x setup.sh
sudo ./setup.sh --vuln
```

2. Access DVWA in your browser:

```
http://<your_machine_ip>/dvwa
```

3. When testing is complete, restore the system to a secure state:

```bash
sudo ./setup.sh --fix
```

## Notes

- Default MySQL root password is set to an empty string (insecure for testing purposes)
- This script is intended for ethical hacking and vulnerability scanning purposes only. Use it responsibly!

## License

MIT License

## Disclaimer

This script is intended for educational and testing purposes only. The author is not responsible for misuse or damage caused by running this script in production environments.


