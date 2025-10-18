# SSHVaultX VPN

[![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-alicangnll-orange.svg)](https://github.com/alicangnll)

**Fast and Secure SSH over VPN** - Advanced Python implementation with proper SOCKS5 proxy support

## 🚀 Features

- **SOCKS5 Proxy Support**: Full SOCKS5 implementation for seamless proxy tunneling
- **Cross-Platform**: Works on Windows, macOS, and Linux
- **Multiple Authentication Methods**: Password and SSH key authentication
- **Windows Integration**: Automatic proxy configuration for Windows systems
- **Interactive Mode**: User-friendly command-line interface
- **Retry Logic**: Automatic connection retry with configurable timeouts
- **Secure**: Uses Paramiko for robust SSH connections

## 📋 Requirements

- Python 3.7 or higher
- SSH server access (with password or key authentication)

## 🛠️ Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/alicangnll/sshvaultx.git
   cd sshvaultx
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## 🚀 Quick Start

### Password Authentication
```bash
python main.py --ip 192.168.1.100 --port 22 --user root --password mypass
```

### SSH Key Authentication
```bash
python main.py --ip 192.168.1.100 --user root --key ~/.ssh/id_rsa
```

### Interactive Mode
```bash
python main.py --ip 10.0.0.1 --port 22 --user vpn --interactive
```

## 📖 Usage

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--ip`, `--host` | SSH server IP address or hostname | Required |
| `--port`, `-p` | SSH server port | 22 |
| `--user`, `-u`, `--username` | SSH username | Required |
| `--password`, `-w` | SSH password | Optional |
| `--key`, `-k`, `--keyfile` | SSH private key file path | Optional |
| `--key-passphrase` | SSH private key passphrase | Optional |
| `--interactive`, `-i` | Interactive mode | False |
| `--proxy-port` | Local SOCKS5 proxy port | 9000 |
| `--timeout`, `-t` | SSH connection timeout (seconds) | 10 |
| `--quiet`, `-q` | Quiet mode (minimal output) | False |

### Examples

**Basic connection with password:**
```bash
python main.py --ip server.com --user admin --password mypassword
```

**SSH key with passphrase:**
```bash
python main.py --ip server.com --user admin --key ~/.ssh/id_rsa --key-passphrase mypassphrase
```

**Custom port and proxy:**
```bash
python main.py --ip server.com --port 2222 --user admin --key ~/.ssh/id_rsa --proxy-port 8080
```

**Quiet mode:**
```bash
python main.py --ip server.com --user admin --key ~/.ssh/id_rsa --quiet
```

## 🔧 Configuration

### Windows Users
SSHVaultX automatically configures Windows proxy settings when connected. The proxy will be set to `socks5://127.0.0.1:9000` (or your specified port).

### Other Platforms
Configure your applications to use the SOCKS5 proxy at `127.0.0.1:9000` (or your specified port).

## 🛡️ Security Notes

- **Password Security**: Avoid using `--password` in command line for security reasons. Use interactive mode instead.
- **Key Files**: Ensure your SSH private keys have appropriate permissions (600).
- **Server Trust**: The application uses `AutoAddPolicy()` for host keys. Consider implementing proper host key verification for production use.

## 🔍 Troubleshooting

### Connection Issues
- Verify SSH server credentials and accessibility
- Check firewall settings on both client and server
- Ensure the SSH server supports direct TCP connections

### Proxy Issues
- Verify the proxy port is not in use by another application
- Check if your application supports SOCKS5 proxies
- On Windows, ensure you have administrator privileges for proxy configuration

### Authentication Issues
- Verify SSH key file path and permissions
- Check if the key file is encrypted and requires a passphrase
- Ensure the SSH server accepts your authentication method

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

## ⚠️ Disclaimer

**IMPORTANT LEGAL NOTICE**

This software is provided for educational and legitimate purposes only. Users are responsible for:

- **Compliance with Laws**: Ensure all usage complies with local, national, and international laws
- **Authorization**: Only use this tool on systems you own or have explicit permission to access
- **Security**: Use strong authentication methods and keep credentials secure
- **Privacy**: Be aware that network traffic may be monitored by network administrators
- **Terms of Service**: Respect the terms of service of any networks or services you access

**The authors and contributors are not responsible for any misuse of this software. Use at your own risk.**

## 🔗 Links

- **GitHub Repository**: [github.com/alicangnll/sshvaultx](https://github.com/alicangnll/sshvaultx)
- **Author**: [@alicangnll](https://github.com/alicangnll)

---

**Made with ❤️ by [@alicangnll](https://github.com/alicangnll)**
