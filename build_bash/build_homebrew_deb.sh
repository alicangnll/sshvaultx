#!/bin/bash

# SSHVaultX Homebrew Debian Package Builder
# This script creates a .deb package for SSHVaultX VPN optimized for Homebrew on macOS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PACKAGE_NAME="sshvaultx"
VERSION="1.0.0"
MAINTAINER="Ali Can Gönüllü <info@alicangonullu.com>"
DESCRIPTION="Fast and Secure SSH over VPN with SOCKS5 proxy support (Homebrew optimized)"
HOMEPAGE="https://github.com/alicangnll/sshvaultx"
ARCHITECTURE="all"
DEPENDS="python3, python3-paramiko"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Directories
BUILD_DIR="${PROJECT_ROOT}/build"
DEB_DIR="${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_homebrew"
CONTROL_DIR="${DEB_DIR}/DEBIAN"
BIN_DIR="${DEB_DIR}/usr/local/bin"
SHARE_DIR="${DEB_DIR}/usr/local/share/${PACKAGE_NAME}"
DOC_DIR="${DEB_DIR}/usr/local/share/doc/${PACKAGE_NAME}"
MAN_DIR="${DEB_DIR}/usr/local/share/man/man1"
ETC_DIR="${DEB_DIR}/usr/local/etc/${PACKAGE_NAME}"

# Functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if ! command -v dpkg-deb &> /dev/null; then
        missing_deps+=("dpkg-deb")
    fi
    
    if ! command -v fakeroot &> /dev/null; then
        missing_deps+=("fakeroot")
    fi
    
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found. This package is optimized for Homebrew environments."
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Install them with:"
        print_status "  macOS: brew install ${missing_deps[*]}"
        print_status "  Linux: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All dependencies found"
}

clean_build() {
    print_status "Cleaning previous build..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
    print_success "Build directory cleaned"
}

create_directories() {
    print_status "Creating package directories..."
    mkdir -p "${CONTROL_DIR}"
    mkdir -p "${BIN_DIR}"
    mkdir -p "${SHARE_DIR}"
    mkdir -p "${DOC_DIR}"
    mkdir -p "${MAN_DIR}"
    mkdir -p "${ETC_DIR}"
    print_success "Directories created"
}

create_control_file() {
    print_status "Creating control file..."
    cat > "${CONTROL_DIR}/control" << EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCHITECTURE}
Depends: ${DEPENDS}
Maintainer: ${MAINTAINER}
Description: ${DESCRIPTION}
 SSHVaultX is a fast and secure SSH over VPN tool with SOCKS5 proxy support.
 This Homebrew-optimized version includes additional macOS-specific features
 and is designed to work seamlessly with Homebrew's Python environment.
 .
 Features:
  - SOCKS5 Proxy Support
  - Cross-Platform (Windows, macOS, Linux)
  - Multiple Authentication Methods (Password and SSH Key)
  - macOS Integration with automatic proxy configuration
  - Homebrew Python compatibility
  - Interactive Mode
  - Retry Logic with configurable timeouts
  - Optimized for macOS Terminal and iTerm2
 .
 This package installs to /usr/local/ to be compatible with Homebrew.
 .
 Homepage: ${HOMEPAGE}
EOF
    print_success "Control file created"
}

create_install_script() {
    print_status "Creating postinst script..."
    cat > "${CONTROL_DIR}/postinst" << 'EOF'
#!/bin/bash
set -e

# Make the script executable
chmod +x /usr/local/bin/sshvaultx

# Update man page database
if command -v mandb &> /dev/null; then
    mandb -q
fi

# Create symlink for easier access
if [ ! -L /usr/local/bin/sshvaultx-vpn ]; then
    ln -s /usr/local/bin/sshvaultx /usr/local/bin/sshvaultx-vpn
fi

# Set up Homebrew Python path if available
if [ -d "/opt/homebrew/bin" ] && [ -f "/opt/homebrew/bin/python3" ]; then
    # Apple Silicon Mac
    sed -i '' '1s|^#!/usr/bin/env python3|#!/opt/homebrew/bin/python3|' /usr/local/bin/sshvaultx
elif [ -d "/usr/local/bin" ] && [ -f "/usr/local/bin/python3" ]; then
    # Intel Mac
    sed -i '' '1s|^#!/usr/bin/env python3|#!/usr/local/bin/python3|' /usr/local/bin/sshvaultx
fi

# Create configuration directory
mkdir -p /usr/local/etc/sshvaultx

# Create sample configuration file
if [ ! -f "/usr/local/etc/sshvaultx/config.example" ]; then
    cat > /usr/local/etc/sshvaultx/config.example << 'CONFIG_EOF'
# SSHVaultX Configuration Example
# Copy this file to ~/.sshvaultx/config and customize as needed

# Default server settings
DEFAULT_SERVER=""
DEFAULT_USER=""
DEFAULT_PORT=22
DEFAULT_PROXY_PORT=9000

# Connection settings
CONNECTION_TIMEOUT=10
MAX_RETRIES=3
RETRY_DELAY=2

# Logging settings
LOG_LEVEL="INFO"
LOG_FILE=""

# Security settings
VERIFY_HOST_KEYS=true
STRICT_HOST_KEY_CHECKING=true
CONFIG_EOF
fi

echo "SSHVaultX VPN (Homebrew) installed successfully!"
echo "Usage: sshvaultx --help"
echo "Configuration: ~/.sshvaultx/config"
echo "Symlink: sshvaultx-vpn (alias for sshvaultx)"
EOF
    chmod +x "${CONTROL_DIR}/postinst"
    print_success "Post-install script created"
}

create_remove_script() {
    print_status "Creating prerm script..."
    cat > "${CONTROL_DIR}/prerm" << 'EOF'
#!/bin/bash
set -e

# Remove symlink
if [ -L /usr/local/bin/sshvaultx-vpn ]; then
    rm /usr/local/bin/sshvaultx-vpn
fi

# Remove man page database entry
if command -v mandb &> /dev/null; then
    mandb -q
fi

echo "SSHVaultX VPN (Homebrew) removed successfully!"
EOF
    chmod +x "${CONTROL_DIR}/prerm"
    print_success "Pre-remove script created"
}

copy_files() {
    print_status "Copying application files..."
    
    # Copy main Python script with Homebrew shebang
    cp ../main.py "${BIN_DIR}/sshvaultx"
    
    # Update shebang for Homebrew Python
    if [ -d "/opt/homebrew/bin" ]; then
        # Apple Silicon Mac
        sed -i '' '1s|^#!/usr/bin/env python3|#!/opt/homebrew/bin/python3|' "${BIN_DIR}/sshvaultx"
    elif [ -d "/usr/local/bin" ]; then
        # Intel Mac
        sed -i '' '1s|^#!/usr/bin/env python3|#!/usr/local/bin/python3|' "${BIN_DIR}/sshvaultx"
    fi
    
    chmod +x "${BIN_DIR}/sshvaultx"
    
    # Copy requirements.txt
    cp ../requirements.txt "${SHARE_DIR}/"
    
    # Copy README as documentation
    cp ../README.md "${DOC_DIR}/"
    
    # Create Homebrew-specific documentation
    cat > "${DOC_DIR}/HOMEBREW.md" << 'EOF'
# SSHVaultX for Homebrew

This is a Homebrew-optimized version of SSHVaultX VPN.

## Installation

```bash
# Install via Homebrew (if available in homebrew-core)
brew install sshvaultx

# Or install this .deb package
sudo dpkg -i sshvaultx_1.0.0_homebrew_all.deb
```

## Usage

```bash
# Basic usage
sshvaultx --ip server.com --user admin --key ~/.ssh/id_rsa

# Using the symlink
sshvaultx-vpn --ip server.com --user admin --key ~/.ssh/id_rsa
```

## Configuration

Configuration file: `~/.sshvaultx/config`
Example configuration: `/usr/local/etc/sshvaultx/config.example`

## Homebrew Integration

This package is designed to work seamlessly with Homebrew's Python environment:
- Uses Homebrew's Python interpreter
- Installs to `/usr/local/` (Homebrew's prefix)
- Compatible with Homebrew's package management

## Uninstallation

```bash
# Remove package
sudo dpkg -r sshvaultx

# Or via Homebrew (if installed via Homebrew)
brew uninstall sshvaultx
```
EOF
    
    # Create changelog
    cat > "${DOC_DIR}/changelog.Debian" << EOF
${PACKAGE_NAME} (${VERSION}) homebrew; urgency=medium

  * Initial Homebrew-optimized release
  * SOCKS5 proxy support
  * macOS integration with automatic proxy configuration
  * Homebrew Python compatibility
  * Cross-platform compatibility
  * SSH key and password authentication
  * Interactive mode with improved UX
  * Added configuration file support
  * Added symlink for easier access (sshvaultx-vpn)

 -- ${MAINTAINER}  $(date -R)
EOF
    gzip -9 "${DOC_DIR}/changelog.Debian"
    
    # Create copyright file
    cat > "${DOC_DIR}/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${PACKAGE_NAME}
Source: ${HOMEPAGE}

Files: *
Copyright: $(date +%Y) ${MAINTAINER}
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF
    
    print_success "Files copied"
}

create_man_page() {
    print_status "Creating man page..."
    cat > "${MAN_DIR}/sshvaultx.1" << EOF
.TH SSHVAULTX 1 "$(date '+%B %Y')" "SSHVaultX VPN (Homebrew)" "User Commands"
.SH NAME
sshvaultx \- Fast and Secure SSH over VPN with SOCKS5 proxy support (Homebrew)
.SH SYNOPSIS
.B sshvaultx
[\fIOPTIONS\fR]
.SH DESCRIPTION
SSHVaultX is a fast and secure SSH over VPN tool with SOCKS5 proxy support.
This Homebrew-optimized version includes additional macOS-specific features
and is designed to work seamlessly with Homebrew's Python environment.
.SH OPTIONS
.TP
\fB--ip\fR, \fB--host\fR
SSH server IP address or hostname (required)
.TP
\fB--port\fR, \fB-p\fR
SSH server port (default: 22)
.TP
\fB--user\fR, \fB-u\fR, \fB--username\fR
SSH username (required)
.TP
\fB--password\fR, \fB-w\fR
SSH password (not recommended for security)
.TP
\fB--key\fR, \fB-k\fR, \fB--keyfile\fR
SSH private key file path
.TP
\fB--key-passphrase\fR
SSH private key passphrase (if key is encrypted)
.TP
\fB--interactive\fR, \fB-i\fR
Interactive mode (prompt for missing credentials)
.TP
\fB--proxy-port\fR
Local SOCKS5 proxy port (default: 9000)
.TP
\fB--timeout\fR, \fB-t\fR
SSH connection timeout in seconds (default: 10)
.TP
\fB--quiet\fR, \fB-q\fR
Quiet mode (minimal output)
.TP
\fB--help\fR, \fB-h\fR
Show help message and exit
.SH EXAMPLES
.TP
Password authentication:
.B sshvaultx --ip 192.168.1.100 --user root --password mypass
.TP
SSH key authentication:
.B sshvaultx --ip 192.168.1.100 --user root --key ~/.ssh/id_rsa
.TP
Interactive mode:
.B sshvaultx --ip 10.0.0.1 --user vpn --interactive
.TP
Using symlink:
.B sshvaultx-vpn --ip server.com --user admin --key ~/.ssh/id_rsa
.SH CONFIGURATION
Configuration file: ~/.sshvaultx/config
Example configuration: /usr/local/etc/sshvaultx/config.example
.SH HOMEBREW INTEGRATION
This package is designed to work seamlessly with Homebrew:
- Uses Homebrew's Python interpreter
- Installs to /usr/local/ (Homebrew's prefix)
- Compatible with Homebrew's package management
.SH AUTHOR
Written by alicangnll
.SH HOMEPAGE
${HOMEPAGE}
.SH COPYRIGHT
Copyright (C) $(date +%Y) alicangnll. License MIT.
EOF
    gzip -9 "${MAN_DIR}/sshvaultx.1"
    print_success "Man page created"
}

create_homebrew_formula() {
    print_status "Creating Homebrew formula..."
    cat > "${SHARE_DIR}/sshvaultx.rb" << EOF
class Sshvaultx < Formula
  desc "Fast and Secure SSH over VPN with SOCKS5 proxy support"
  homepage "https://github.com/alicangnll/sshvaultx"
  url "https://github.com/alicangnll/sshvaultx/archive/v${VERSION}.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.9"

  def install
    system "python3", "-m", "pip", "install", *std_pip_args, "."
    bin.install "main.py" => "sshvaultx"
    man1.install "sshvaultx.1.gz"
    doc.install "README.md"
  end

  test do
    system "#{bin}/sshvaultx", "--help"
  end
end
EOF
    print_success "Homebrew formula created"
}

build_package() {
    print_status "Building Homebrew Debian package..."
    
    # Calculate installed size
    local size=$(du -sk "${DEB_DIR}" | cut -f1)
    echo "Installed-Size: ${size}" >> "${CONTROL_DIR}/control"
    
    # Build the package
    fakeroot dpkg-deb --build --root-owner-group "${DEB_DIR}" "${BUILD_DIR}/"
    
    local deb_file="${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
    
    if [ -f "${deb_file}" ]; then
        print_success "Package built successfully: ${deb_file}"
        
        # Show package info
        print_status "Package information:"
        dpkg-deb --info "${deb_file}"
        
        # Show package contents
        print_status "Package contents:"
        dpkg-deb --contents "${deb_file}"
        
        # Show package size
        local package_size=$(du -h "${deb_file}" | cut -f1)
        print_success "Package size: ${package_size}"
        
        # Copy to packages directory
        mkdir -p packages
        cp "${deb_file}" packages/
        print_success "Package copied to packages directory"
        
    else
        print_error "Package build failed!"
        exit 1
    fi
}

show_usage() {
    echo "SSHVaultX Homebrew Debian Package Builder"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Set package version (default: ${VERSION})"
    echo "  -c, --clean    Clean build directory and exit"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build with default version"
    echo "  $0 --version 1.2.3   # Build with custom version"
    echo "  $0 --clean           # Clean build directory"
    echo ""
    echo "This script creates a Homebrew-optimized .deb package with:"
    echo "  - Homebrew Python compatibility"
    echo "  - macOS-specific optimizations"
    echo "  - Configuration file support"
    echo "  - Symlink for easier access (sshvaultx-vpn)"
    echo "  - Homebrew formula template"
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -c|--clean)
                print_status "Cleaning build directory..."
                rm -rf "${BUILD_DIR}"
                print_success "Build directory cleaned"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "Starting SSHVaultX Homebrew Debian package build..."
    print_status "Version: ${VERSION}"
    print_status "Architecture: ${ARCHITECTURE}"
    print_status "Target: Homebrew-optimized"
    
    check_dependencies
    clean_build
    create_directories
    create_control_file
    create_install_script
    create_remove_script
    copy_files
    create_man_page
    create_homebrew_formula
    build_package
    
    print_success "Build completed successfully!"
    print_status "To install the package: sudo dpkg -i packages/${PACKAGE_NAME}_${VERSION}_homebrew_${ARCHITECTURE}.deb"
    print_status "To remove the package: sudo dpkg -r ${PACKAGE_NAME}"
    print_status "Homebrew formula: packages/sshvaultx.rb"
    print_status "Configuration: ~/.sshvaultx/config"
    print_status "Symlink: sshvaultx-vpn (alias for sshvaultx)"
}

# Run main function with all arguments
main "$@"
