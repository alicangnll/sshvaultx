# 🔐 SSHVaultX VPN

> **Professional SSH-based VPN solution with enterprise-grade security and performance**

[![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-Open%20Source-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

## 🚀 Overview

**SSHVaultX VPN** is a cutting-edge, open-source VPN solution that leverages SSH tunneling technology to provide secure, encrypted network connections. Built with Python, it offers enterprise-grade security without compromising on performance or ease of use.

### ✨ Key Highlights

- **🔒 Military-Grade Encryption**: SSH-based tunneling ensures your data is protected with industry-standard encryption
- **⚡ High Performance**: Optimized SOCKS5 proxy implementation for minimal latency
- **🌐 Universal Compatibility**: Seamless operation across Windows, Linux, and macOS
- **🛡️ Zero-Log Policy**: No data collection, no tracking, complete privacy
- **🔧 Enterprise Ready**: Command-line interface perfect for automation and scripting

## 🎯 Features

| Feature | Description |
|---------|-------------|
| **🔐 SSH Authentication** | Support for both password and SSH key authentication |
| **⚡ SOCKS5 Proxy** | High-performance local proxy server on `127.0.0.1:9000` |
| **🔄 Auto-Retry** | Intelligent connection retry mechanism with exponential backoff |
| **⏱️ Timeout Control** | Configurable connection timeouts for optimal performance |
| **🖥️ Cross-Platform** | Native support for Windows, Linux, and macOS |
| **🔧 CLI Interface** | Professional command-line interface with full automation support |
| **🛡️ Security First** | No logging, no data collection, complete privacy protection |

## 🚀 Quick Start

### Prerequisites
- Python 3.7 or higher
- SSH server access (Linux/Unix system)
- Network connectivity

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/SSHVaultX-VPN.git
cd SSHVaultX-VPN

# Install dependencies
pip install -r requirements.txt

# Make executable (Linux/macOS)
chmod +x alivpn_python.py
```

### Basic Usage

```bash
# Interactive mode
python3 alivpn_python.py --interactive

# Command-line mode
python3 alivpn_python.py --ip your-server.com --user username --password yourpassword

# SSH Key authentication
python3 alivpn_python.py --ip your-server.com --user username --key ~/.ssh/id_rsa
```

## 📋 Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| **Windows** | ✅ Full Support | Auto proxy configuration, native integration |
| **Linux** | ✅ Full Support | Manual proxy setup, systemd service ready |
| **macOS** | ✅ Full Support | Manual proxy setup, launchd service ready |

## 💻 Advanced Usage

### Command Line Options

```bash
python3 alivpn_python.py [OPTIONS]

Options:
  --ip, --host IP        SSH server IP address or hostname
  --port, -p PORT        SSH server port (default: 22)
  --user, -u USER        SSH username
  --password, -w PASS    SSH password (not recommended for security)
  --key, -k KEYFILE      SSH private key file path
  --key-passphrase PASS  SSH private key passphrase
  --interactive, -i      Interactive mode for missing credentials
  --proxy-port PORT      Local SOCKS5 proxy port (default: 9000)
  --timeout, -t SECONDS  SSH connection timeout (default: 10)
  --quiet, -q            Quiet mode with minimal output
  --help, -h             Show help message
```

### Usage Examples

```bash
# Basic password authentication
python3 alivpn_python.py --ip 192.168.1.100 --user admin --password secret123

# SSH key authentication
python3 alivpn_python.py --ip server.example.com --user root --key ~/.ssh/id_rsa

# Custom port and proxy settings
python3 alivpn_python.py --ip server.com --port 2222 --user vpn --key ~/.ssh/id_rsa --proxy-port 8080

# Quiet mode for scripting
python3 alivpn_python.py --ip server.com --user admin --password pass --quiet

# Interactive mode
python3 alivpn_python.py --interactive
```

## 🔧 Configuration

### Windows Proxy Setup
SSHVaultX automatically configures Windows proxy settings when connected. No manual configuration required.

### Linux/macOS Proxy Setup
Configure your applications to use SOCKS5 proxy:
- **Host**: `127.0.0.1`
- **Port**: `9000` (or custom port specified with `--proxy-port`)
- **Type**: SOCKS5

## 🛡️ Security & Privacy

- **🔒 End-to-End Encryption**: All traffic is encrypted through SSH tunnel
- **🛡️ Zero-Log Policy**: No data collection or logging
- **🔐 Secure Authentication**: Support for SSH keys and passwords
- **🌐 No DNS Leaks**: All DNS queries routed through secure tunnel
- **⚡ No Data Retention**: No logs, no tracking, complete anonymity

## 📊 Performance

- **Low Latency**: Optimized SOCKS5 implementation
- **High Throughput**: Efficient data forwarding
- **Memory Efficient**: Minimal resource usage
- **Auto-Retry**: Intelligent reconnection on failures
- **Timeout Control**: Configurable connection timeouts

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Legal Disclaimer

This software is provided for educational and legitimate security purposes only. Users are responsible for complying with all applicable laws and regulations in their jurisdiction. The developers are not responsible for any misuse of this software.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/SSHVaultX-VPN/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/SSHVaultX-VPN/discussions)
- **Security**: [Security Policy](SECURITY.md)

---

<div align="center">

**Made with ❤️ by the SSHVaultX Team**

[⭐ Star this repo](https://github.com/yourusername/SSHVaultX-VPN) • [🐛 Report Bug](https://github.com/yourusername/SSHVaultX-VPN/issues) • [💡 Request Feature](https://github.com/yourusername/SSHVaultX-VPN/issues)

</div>
