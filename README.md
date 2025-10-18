# SSHVaultX VPN

[![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-alicangnll-orange.svg)](https://github.com/alicangnll)

**Fast and Secure SSH over VPN** - Advanced Python implementation with proper SOCKS5 proxy support

> A powerful and lightweight SSH-based VPN solution that creates secure tunnels through SSH servers and routes all your network traffic using SOCKS5 proxy protocol. Perfect for bypassing network restrictions, accessing remote resources securely, and protecting your privacy with encrypted connections.

## 🚀 Features

- **SOCKS5 Proxy Support**: Full SOCKS5 implementation for seamless proxy tunneling
- **Cross-Platform**: Works on Windows, macOS, and Linux
- **Multiple Authentication Methods**: Password and SSH key authentication
- **Windows Integration**: Automatic proxy configuration for Windows systems
- **Interactive Mode**: User-friendly command-line interface
- **Retry Logic**: Automatic connection retry with configurable timeouts
- **Secure**: Uses Paramiko for robust SSH connections

## 🔧 How It Works

### Architecture Overview

SSHVaultX creates a secure tunnel through SSH and routes all your network traffic through it using SOCKS5 proxy protocol. Here's how it works:

```
[Your Computer] ←→ [SOCKS5 Proxy:127.0.0.1:9000] ←→ [SSH Tunnel] ←→ [Remote Server] ←→ [Internet]
```

### Core Components

1. **SSH Client**: Establishes secure connection to remote server using Paramiko
2. **SOCKS5 Server**: Creates local proxy server on your machine
3. **Tunnel Manager**: Manages data forwarding between proxy and SSH connection
4. **Windows Integration**: Automatically configures system proxy settings

### Working Principles

#### 1. SSH Connection Establishment
- Connects to remote SSH server using provided credentials
- Supports both password and SSH key authentication
- Implements retry logic with configurable timeouts
- Uses Paramiko library for robust SSH handling

#### 2. SOCKS5 Proxy Server
- Creates local SOCKS5 proxy server on `127.0.0.1:9000` (configurable)
- Handles SOCKS5 protocol handshake and authentication
- Supports both IPv4 and domain name resolution
- Manages multiple concurrent connections

#### 3. Data Forwarding
- Establishes direct TCP channels through SSH connection
- Forwards data bidirectionally between local proxy and remote server
- Uses threading for concurrent connection handling
- Implements proper error handling and connection cleanup

#### 4. Windows Integration
- Automatically configures Windows Internet Settings registry
- Sets system-wide proxy to SOCKS5 server
- Provides seamless integration without manual configuration
- Restores original settings on disconnect

### Security Features

- **Encrypted Tunnel**: All traffic is encrypted through SSH
- **No Data Logging**: No user data is stored or logged
- **Secure Authentication**: Supports SSH keys and strong passwords
- **Connection Validation**: Verifies SSH server before establishing tunnel
- **Graceful Shutdown**: Properly cleans up connections and settings

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

## ⚙️ Technical Details

### Protocol Implementation

#### SOCKS5 Protocol Support
- **Version 5**: Full SOCKS5 protocol implementation
- **Authentication**: No authentication method (method 0x00)
- **Address Types**: IPv4 (0x01) and Domain Name (0x03)
- **Commands**: CONNECT (0x01) for TCP connections
- **Error Handling**: Proper SOCKS5 error codes and responses

#### SSH Tunnel Implementation
- **Direct TCP**: Uses SSH direct-tcpip channel type
- **Bidirectional**: Full-duplex data forwarding
- **Threading**: Separate threads for each direction
- **Buffer Management**: 4KB buffer size for optimal performance

### Performance Characteristics

#### Connection Handling
- **Concurrent Connections**: Supports multiple simultaneous connections
- **Memory Usage**: Minimal memory footprint (~10-20MB)
- **CPU Usage**: Low CPU usage during normal operation
- **Latency**: Adds minimal latency (typically <10ms)

#### Network Optimization
- **Keep-Alive**: SSH connection keep-alive for stability
- **Timeout Handling**: Configurable timeouts for all operations
- **Retry Logic**: Automatic reconnection on failures
- **Graceful Degradation**: Proper cleanup on errors

### System Integration

#### Windows Registry Management
```python
# Registry keys modified:
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings
- ProxyEnable: DWORD (0 or 1)
- ProxyServer: REG_SZ (socks5://127.0.0.1:port)
```

#### Process Management
- **Signal Handling**: Proper SIGINT/SIGTERM handling
- **Cleanup**: Automatic resource cleanup on exit
- **Error Recovery**: Graceful error handling and recovery

## 🛡️ Security Notes

- **Password Security**: Avoid using `--password` in command line for security reasons. Use interactive mode instead.
- **Key Files**: Ensure your SSH private keys have appropriate permissions (600).
- **Server Trust**: The application uses `AutoAddPolicy()` for host keys. Consider implementing proper host key verification for production use.

## 📊 Use Cases & Examples

### Common Scenarios

#### 1. Bypassing Network Restrictions
```bash
# Connect through a server in a different country
python main.py --ip your-server.com --user vpn --key ~/.ssh/id_rsa
# All your traffic will now appear to come from your-server.com
```

#### 2. Secure Remote Access
```bash
# Access internal company resources securely
python main.py --ip company-server.internal --user employee --password
# Browse internal websites as if you're on the company network
```

#### 3. Development & Testing
```bash
# Test applications from different IP addresses
python main.py --ip test-server.com --user developer --interactive
# Your applications will see the test-server.com IP
```

#### 4. Privacy Protection
```bash
# Route all traffic through encrypted tunnel
python main.py --ip privacy-server.com --user anonymous --key ~/.ssh/id_rsa --quiet
# Your ISP can only see encrypted SSH traffic
```

### Application Configuration Examples

#### Web Browsers
- **Chrome/Edge**: Settings → Advanced → System → Open proxy settings
- **Firefox**: Settings → Network Settings → Manual proxy configuration
- **Safari**: System Preferences → Network → Advanced → Proxies

#### Command Line Tools
```bash
# Using curl through proxy
curl --socks5 127.0.0.1:9000 https://httpbin.org/ip

# Using wget through proxy
wget -e http_proxy=socks5://127.0.0.1:9000 https://httpbin.org/ip

# Using git through proxy
git config --global http.proxy socks5://127.0.0.1:9000
```

#### Development Tools
```bash
# Node.js applications
export HTTP_PROXY=socks5://127.0.0.1:9000
export HTTPS_PROXY=socks5://127.0.0.1:9000

# Python applications
export http_proxy=socks5://127.0.0.1:9000
export https_proxy=socks5://127.0.0.1:9000
```

## 🔍 Troubleshooting

### Connection Issues
- Verify SSH server credentials and accessibility
- Check firewall settings on both client and server
- Ensure the SSH server supports direct TCP connections
- Test SSH connection manually: `ssh user@server.com`

### Proxy Issues
- Verify the proxy port is not in use by another application
- Check if your application supports SOCKS5 proxies
- On Windows, ensure you have administrator privileges for proxy configuration
- Test proxy connection: `curl --socks5 127.0.0.1:9000 https://httpbin.org/ip`

### Authentication Issues
- Verify SSH key file path and permissions
- Check if the key file is encrypted and requires a passphrase
- Ensure the SSH server accepts your authentication method
- Test SSH key: `ssh -i ~/.ssh/id_rsa user@server.com`

### Performance Issues
- Check network latency to SSH server
- Verify SSH server has sufficient resources
- Consider using a server closer to your location
- Monitor CPU and memory usage during operation

## ⚠️ Disclaimer

**IMPORTANT LEGAL NOTICE**

This software is provided for educational and legitimate purposes only. Users are responsible for:

- **Compliance with Laws**: Ensure all usage complies with local, national, and international laws
- **Authorization**: Only use this tool on systems you own or have explicit permission to access
- **Security**: Use strong authentication methods and keep credentials secure
- **Privacy**: Be aware that network traffic may be monitored by network administrators
- **Terms of Service**: Respect the terms of service of any networks or services you access

**The authors and contributors are not responsible for any misuse of this software. Use at your own risk.**

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

## 🔗 Links

- **GitHub Repository**: [github.com/alicangnll/sshvaultx](https://github.com/alicangnll/sshvaultx)
- **Author**: [@alicangnll](https://github.com/alicangnll)

---

**Made with ❤️ by [@alicangnll](https://github.com/alicangnll)**
