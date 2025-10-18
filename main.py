#!/usr/bin/env python3
"""
SSHVaultX VPN - Fast and Secure SSH over VPN (Advanced Version)
Python implementation with proper SOCKS5 proxy support
"""

import sys
import os
import signal
import threading
import time
import getpass
import socket
import struct
import argparse
from typing import Optional
import paramiko

# For Windows proxy configuration
if sys.platform == "win32":
    try:
        import winreg
        import ctypes
        from ctypes import wintypes
    except ImportError:
        print("Warning: Windows registry modules not available")
        winreg = None
        ctypes = None
        wintypes = None


class SSHVaultX:
    def __init__(self, proxy_port=9000, timeout=10):
        self.forward_port = proxy_port
        self.timeout = timeout
        self.ssh_client: Optional[paramiko.SSHClient] = None
        self.socks_server: Optional[socket.socket] = None
        self.server_thread: Optional[threading.Thread] = None
        self.running = False
        
        # Windows proxy configuration
        if sys.platform == "win32" and winreg:
            self._setup_windows_proxy_functions()
    
    def _setup_windows_proxy_functions(self):
        """Setup Windows proxy configuration functions"""
        if not ctypes or not wintypes:
            return
            
        # Windows API functions for proxy configuration
        self.wininet = ctypes.windll.wininet
        self.INTERNET_OPTION_SETTINGS_CHANGED = 39
        self.INTERNET_OPTION_REFRESH = 37
    
    def _set_windows_proxy(self):
        """Configure Windows proxy settings"""
        if sys.platform != "win32" or not winreg:
            return
            
        try:
            # Open registry key for Internet Settings
            registry = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
                0,
                winreg.KEY_WRITE
            )
            
            # Set proxy settings
            winreg.SetValueEx(registry, "ProxyEnable", 0, winreg.REG_DWORD, 1)
            winreg.SetValueEx(registry, "ProxyServer", 0, winreg.REG_SZ, f"socks5://127.0.0.1:{self.forward_port}")
            
            winreg.CloseKey(registry)
            
            # Refresh Internet settings
            if ctypes:
                self.wininet.InternetSetOption(
                    None, 
                    self.INTERNET_OPTION_SETTINGS_CHANGED, 
                    None, 
                    0
                )
                self.wininet.InternetSetOption(
                    None, 
                    self.INTERNET_OPTION_REFRESH, 
                    None, 
                    0
                )
                
        except Exception as e:
            print(f"Warning: Could not set Windows proxy: {e}")
    
    def _unset_windows_proxy(self):
        """Disable Windows proxy settings"""
        if sys.platform != "win32" or not winreg:
            return
            
        try:
            registry = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
                0,
                winreg.KEY_WRITE
            )
            
            winreg.SetValueEx(registry, "ProxyEnable", 0, winreg.REG_DWORD, 0)
            winreg.SetValueEx(registry, "ProxyServer", 0, winreg.REG_SZ, "")
            
            winreg.CloseKey(registry)
            
        except Exception as e:
            print(f"Warning: Could not unset Windows proxy: {e}")
    
    def _parse_socks5_request(self, data):
        """Parse SOCKS5 connection request"""
        if len(data) < 10:
            return None, None, None
        
        # Check SOCKS5 version and command
        if data[0] != 0x05 or data[1] != 0x01:
            return None, None, None
        
        # Parse address type
        addr_type = data[3]
        offset = 4
        
        if addr_type == 0x01:  # IPv4
            if len(data) < 10:
                return None, None, None
            ip = socket.inet_ntoa(data[offset:offset+4])
            port = struct.unpack('>H', data[offset+4:offset+6])[0]
            return ip, port, data[offset+6:]
        
        elif addr_type == 0x03:  # Domain name
            if len(data) < 5:
                return None, None, None
            name_len = data[offset]
            if len(data) < offset + 1 + name_len + 2:
                return None, None, None
            domain = data[offset+1:offset+1+name_len].decode('utf-8')
            port = struct.unpack('>H', data[offset+1+name_len:offset+1+name_len+2])[0]
            return domain, port, data[offset+1+name_len+2:]
        
        return None, None, None
    
    def _handle_socks5_client(self, client_socket, address):
        """Handle SOCKS5 client connection"""
        try:
            # Receive initial handshake
            data = client_socket.recv(1024)
            if not data or data[0] != 0x05:
                return
            
            # Send authentication method (no authentication)
            client_socket.send(b'\x05\x00')
            
            # Receive connection request
            data = client_socket.recv(1024)
            if not data:
                return
            
            # Parse request
            target_host, target_port, remaining_data = self._parse_socks5_request(data)
            if not target_host or not target_port:
                # Send connection refused
                client_socket.send(b'\x05\x01\x00\x01' + b'\x00' * 6)
                return
            
            # Create SSH tunnel
            try:
                # Get SSH transport
                transport = self.ssh_client.get_transport()
                
                # Create direct TCP connection through SSH
                dest_addr = (target_host, target_port)
                local_addr = ('127.0.0.1', 0)
                
                # Open channel for direct TCP connection
                channel = transport.open_channel('direct-tcpip', dest_addr, local_addr)
                
                # Send success response
                response = b'\x05\x00\x00\x01' + data[4:10]
                client_socket.send(response)
                
                # Forward data between client and SSH channel
                self._forward_data(client_socket, channel)
                
            except Exception as e:
                # Send connection refused
                response = b'\x05\x01\x00\x01' + b'\x00' * 6
                client_socket.send(response)
                
        except Exception as e:
            pass
        finally:
            try:
                client_socket.close()
            except:
                pass
    
    def _forward_data(self, client_socket, channel):
        """Forward data between client and SSH channel"""
        def forward(src, dst, name):
            try:
                while self.running:
                    data = src.recv(4096)
                    if not data:
                        break
                    dst.send(data)
            except Exception as e:
                pass
            finally:
                try:
                    src.close()
                except:
                    pass
                try:
                    dst.close()
                except:
                    pass
        
        # Start bidirectional forwarding
        client_to_channel = threading.Thread(
            target=forward, 
            args=(client_socket, channel, "client->channel")
        )
        channel_to_client = threading.Thread(
            target=forward, 
            args=(channel, client_socket, "channel->client")
        )
        
        client_to_channel.daemon = True
        channel_to_client.daemon = True
        
        client_to_channel.start()
        channel_to_client.start()
        
        # Wait for either thread to finish
        client_to_channel.join()
        channel_to_client.join()
    
    def _create_socks5_server(self, quiet=False):
        """Create SOCKS5 proxy server"""
        def socks_server():
            self.socks_server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socks_server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socks_server.bind(('127.0.0.1', self.forward_port))
            self.socks_server.listen(5)
            
            if not quiet:
                print(f"SOCKS5 proxy server started on 127.0.0.1:{self.forward_port}")
            
            while self.running:
                try:
                    client_socket, address = self.socks_server.accept()
                    client_thread = threading.Thread(
                        target=self._handle_socks5_client, 
                        args=(client_socket, address)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                except Exception as e:
                    if self.running and not quiet:
                        print(f"Server error: {e}")
                    break
            
            try:
                self.socks_server.close()
            except:
                pass
        
        self.server_thread = threading.Thread(target=socks_server)
        self.server_thread.daemon = True
        self.server_thread.start()
    
    def connect_ssh_vpn(self, ip: str, port: int, username: str, password: str = None, key_file: str = None, key_passphrase: str = None, quiet=False):
        """Connect to SSH server and start VPN tunnel"""
        if not quiet:
            print(f"Connecting to {ip}:{port}...")
        
        max_retries = 3
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                self.ssh_client = paramiko.SSHClient()
                self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                if key_file:
                    if not quiet:
                        print(f"Using SSH key: {key_file}")
                    
                    try:
                        if key_passphrase:
                            private_key = paramiko.RSAKey.from_private_key_file(key_file, password=key_passphrase)
                        else:
                            private_key = paramiko.RSAKey.from_private_key_file(key_file)
                    except paramiko.ssh_exception.PasswordRequiredException:
                        if not quiet:
                            print("Key file is encrypted but no passphrase provided")
                        raise Exception("Encrypted key requires passphrase")
                    except Exception as e:
                        if not quiet:
                            print(f"Error loading key file: {e}")
                        raise Exception(f"Failed to load key file: {e}")
                    self.ssh_client.connect(
                        ip, port, username, 
                        pkey=private_key, 
                        timeout=self.timeout,
                        allow_agent=False,
                        look_for_keys=False,
                        banner_timeout=30,
                        auth_timeout=30
                    )
                else:
                    self.ssh_client.connect(
                        ip, port, username, 
                        password, 
                        timeout=self.timeout,
                        allow_agent=False,
                        look_for_keys=False,
                        banner_timeout=30,
                        auth_timeout=30
                    )
                self.running = True
                self._create_socks5_server(quiet=quiet)
                
                if sys.platform == "win32":
                    self._set_windows_proxy()
                    if not quiet:
                        print("Connected!\nConnected to Proxy\nFor exit use CTRL + C")
                else:
                    if not quiet:
                        print(f"Connected!\nSOCKS5 Proxy Address 127.0.0.1:{self.forward_port}\nFor exit use CTRL + C")
                
                break
                
            except paramiko.ssh_exception.SSHException as e:
                if not quiet:
                    print(f"SSH connection failed (attempt {attempt + 1}/{max_retries}): {e}")
                if attempt < max_retries - 1:
                    if not quiet:
                        print(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    if not quiet:
                        print("Max retry attempts reached")
                    self.disconnect_vpn()
                    raise Exception(f"SSH connection failed after {max_retries} attempts: {e}")
                    
            except Exception as e:
                if not quiet:
                    print(f"Connection failed (attempt {attempt + 1}/{max_retries}): {e}")
                if attempt < max_retries - 1:
                    if not quiet:
                        print(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    if not quiet:
                        print("Max retry attempts reached")
                    self.disconnect_vpn()
                    raise
    
    def disconnect_vpn(self):
        """Disconnect VPN and cleanup"""
        print("Disconnecting...")
        
        self.running = False
        
        if self.socks_server:
            try:
                self.socks_server.close()
            except:
                pass
            self.socks_server = None
        
        if self.ssh_client:
            try:
                self.ssh_client.close()
            except:
                pass
            self.ssh_client = None
        
        if sys.platform == "win32":
            self._unset_windows_proxy()
        else:
            print("Disconnected!\n")
    
    def signal_handler(self, signum, frame):
        """Handle Ctrl+C gracefully"""
        print("\nShutting down...")
        self.disconnect_vpn()
        sys.exit(0)


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="SSHVaultX VPN - Fast and Secure SSH over VPN",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Password authentication
  python alivpn_python.py --ip 192.168.1.100 --port 22 --user root --password mypass
  
  # SSH Key authentication
  python alivpn_python.py --ip 192.168.1.100 --user root --key ~/.ssh/id_rsa
  
  # SSH Key with passphrase
  python alivpn_python.py --ip server.com --user admin --key ~/.ssh/id_rsa --key-passphrase mypassphrase
  
  # Interactive mode
  python alivpn_python.py --ip 10.0.0.1 --port 22 --user vpn --interactive
  
  # Custom port with key
  python alivpn_python.py --ip server.com --port 2222 --user admin --key ~/.ssh/id_rsa
        """
    )
    
    parser.add_argument('--ip', '--host', required=False, help='SSH server IP address or hostname')
    parser.add_argument('--port', '-p', type=int, default=22, help='SSH server port (default: 22)')
    parser.add_argument('--user', '-u', '--username', help='SSH username')
    parser.add_argument('--password', '-w', help='SSH password (not recommended for security)')
    parser.add_argument('--key', '-k', '--keyfile', help='SSH private key file path')
    parser.add_argument('--key-passphrase', help='SSH private key passphrase (if key is encrypted)')
    parser.add_argument('--interactive', '-i', action='store_true', help='Interactive mode (prompt for missing credentials)')
    parser.add_argument('--proxy-port', type=int, default=9000, help='Local SOCKS5 proxy port (default: 9000)')
    parser.add_argument('--timeout', '-t', type=int, default=10, help='SSH connection timeout in seconds (default: 10)')
    parser.add_argument('--quiet', '-q', action='store_true', help='Quiet mode (minimal output)')
    
    return parser.parse_args()

def get_connection_details(args):
    """Get connection details from arguments or interactive input"""
    ip = args.ip
    port = args.port
    username = args.user
    password = args.password
    key_file = args.key
    key_passphrase = args.key_passphrase
    
    # Validate port
    if port <= 0 or port >= 65535:
        print("Error: Port number must be between 1 and 65534")
        sys.exit(1)
    
    # Only show header if we need to ask for something
    header_shown = False
    
    # Check if we have either password or key authentication
    has_auth = password or key_file
    
    # Interactive mode for missing credentials
    if args.interactive or not all([ip, username]) or not has_auth:
        if not header_shown:
            print("=" * 36)
            print("SSHVaultX VPN - Fast and Secure SSH over VPN")
            print("GitHub: @alicangnll")
            print("=" * 36)
            header_shown = True
        
        try:
            if not ip:
                ip = input("SSH IP: ").strip()
                if not ip:
                    print("Empty IP address!")
                    sys.exit(1)
            
            if not username:
                username = input("SSH Username: ").strip()
                if not username:
                    print("Empty username!")
                    sys.exit(1)
            
            # Ask for port if not provided or if interactive mode
            if args.interactive or port == 22:
                port_input = input(f"SSH Port (default: {port}): ").strip()
                if port_input:
                    try:
                        port = int(port_input)
                        if port <= 0 or port >= 65535:
                            print("Invalid port number! Using default port 22.")
                            port = 22
                    except ValueError:
                        print("Invalid port number! Using default port 22.")
                        port = 22
            
            # Ask for authentication method if neither is provided
            if not password and not key_file:
                print("\nAuthentication method:")
                print("1. Password")
                print("2. SSH Key")
                choice = input("Choose (1 or 2): ").strip()
                
                if choice == "1":
                    password = getpass.getpass("SSH Password: ").strip()
                    if not password:
                        print("Empty password!")
                        sys.exit(1)
                elif choice == "2":
                    key_file = input("SSH Key file path: ").strip()
                    if not key_file:
                        print("Empty key file path!")
                        sys.exit(1)
                    # Check if key file exists
                    if not os.path.exists(key_file):
                        print(f"Key file not found: {key_file}")
                        sys.exit(1)
                    # Ask for passphrase if needed
                    key_passphrase = getpass.getpass("Key passphrase (press Enter if none): ").strip()
                else:
                    print("Invalid choice!")
                    sys.exit(1)
            elif not password and key_file:
                # Key file provided but no passphrase, ask if needed
                key_passphrase = getpass.getpass("Key passphrase (press Enter if none): ").strip()
            elif not key_file and password:
                # Password provided, nothing to ask
                pass
                    
        except KeyboardInterrupt:
            print("\nExiting...")
            sys.exit(0)
    
    # Validate required fields
    if not ip:
        print("Error: SSH IP address is required")
        sys.exit(1)
    if not username:
        print("Error: SSH username is required")
        sys.exit(1)
    if not password and not key_file:
        print("Error: Either SSH password or key file is required")
        sys.exit(1)
    
    return ip, port, username, password, key_file, key_passphrase

def show_disclaimer():
    """Show legal disclaimer"""
    print("=" * 60)
    print("IMPORTANT LEGAL NOTICE - READ CAREFULLY")
    print("=" * 60)
    print("This software is provided for educational and legitimate purposes only.")
    print("Users are responsible for:")
    print("- Compliance with all applicable laws and regulations")
    print("- Only using this tool on systems you own or have explicit permission to access")
    print("- Using strong authentication methods and keeping credentials secure")
    print("- Being aware that network traffic may be monitored by administrators")
    print("- Respecting the terms of service of any networks or services accessed")
    print("")
    print("The authors and contributors are not responsible for any misuse of this software.")
    print("Use at your own risk and in accordance with applicable laws.")
    print("=" * 60)
    print("By continuing, you acknowledge that you have read and understood this notice.")
    print("=" * 60)
    print("")

def main():
    """Main function"""
    args = parse_arguments()
    
    # Always show disclaimer unless in quiet mode
    if not args.quiet:
        show_disclaimer()
        print(f"Arguments: IP={args.ip}, Port={args.port}, User={args.user}, ProxyPort={args.proxy_port}, Quiet={args.quiet}")
    
    ip, port, username, password, key_file, key_passphrase = get_connection_details(args)
    
    if not args.quiet:
        print("=" * 36)
        print("SSHVaultX VPN - Fast and Secure SSH over VPN")
        print("GitHub: @alicangnll")
        print("=" * 36)
    
    vpn = SSHVaultX(proxy_port=args.proxy_port, timeout=args.timeout)
    signal.signal(signal.SIGINT, vpn.signal_handler)
    signal.signal(signal.SIGTERM, vpn.signal_handler)
    
    try:
        vpn.connect_ssh_vpn(ip, port, username, password, key_file, key_passphrase, quiet=args.quiet)
        
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        vpn.signal_handler(signal.SIGINT, None)
    except Exception as e:
        if not args.quiet:
            print(f"An error occurred.\nERROR: {e}")
        vpn.disconnect_vpn()
        sys.exit(1)


if __name__ == "__main__":
    main()
