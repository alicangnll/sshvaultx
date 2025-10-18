#!/bin/bash

# SSHVaultX Debian Package Builder
# This script creates a .deb package for SSHVaultX VPN

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
MAINTAINER="alicangnll <info@alicangonullu.com>"
DESCRIPTION="Fast and Secure SSH over VPN with SOCKS5 proxy support"
HOMEPAGE="https://github.com/alicangnll/sshvaultx"
ARCHITECTURE="all"
DEPENDS="python3, python3-paramiko"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Directories
BUILD_DIR="${PROJECT_ROOT}/build"
DEB_DIR="${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}"
CONTROL_DIR="${DEB_DIR}/DEBIAN"
BIN_DIR="${DEB_DIR}/usr/bin"
SHARE_DIR="${DEB_DIR}/usr/share/${PACKAGE_NAME}"
DOC_DIR="${DEB_DIR}/usr/share/doc/${PACKAGE_NAME}"
MAN_DIR="${DEB_DIR}/usr/share/man/man1"

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
    
    # Check if required tools are installed
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
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Install them with: sudo apt-get install ${missing_deps[*]}"
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
 It provides an easy way to create secure tunnels through SSH servers and
 route traffic through them using SOCKS5 proxy protocol.
 .
 Features:
  - SOCKS5 Proxy Support
  - Cross-Platform (Windows, macOS, Linux)
  - Multiple Authentication Methods (Password and SSH Key)
  - Windows Integration with automatic proxy configuration
  - Interactive Mode
  - Retry Logic with configurable timeouts
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
chmod +x /usr/bin/sshvaultx

# Update man page database
if command -v mandb &> /dev/null; then
    mandb -q
fi

echo "SSHVaultX VPN installed successfully!"
echo "Usage: sshvaultx --help"
EOF
    chmod +x "${CONTROL_DIR}/postinst"
    print_success "Post-install script created"
}

create_remove_script() {
    print_status "Creating prerm script..."
    cat > "${CONTROL_DIR}/prerm" << 'EOF'
#!/bin/bash
set -e

# Remove man page database entry
if command -v mandb &> /dev/null; then
    mandb -q
fi

echo "SSHVaultX VPN removed successfully!"
EOF
    chmod +x "${CONTROL_DIR}/prerm"
    print_success "Pre-remove script created"
}

copy_files() {
    print_status "Copying application files..."
    
    # Copy main Python script
    cp ../main.py "${BIN_DIR}/sshvaultx"
    chmod +x "${BIN_DIR}/sshvaultx"
    
    # Copy requirements.txt
    cp ../requirements.txt "${SHARE_DIR}/"
    
    # Copy README as documentation
    cp ../README.md "${DOC_DIR}/"
    
    # Create changelog
    cat > "${DOC_DIR}/changelog.Debian" << EOF
${PACKAGE_NAME} (${VERSION}) unstable; urgency=medium

  * Initial release
  * SOCKS5 proxy support
  * Cross-platform compatibility
  * SSH key and password authentication
  * Windows proxy integration

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
.TH SSHVAULTX 1 "$(date '+%B %Y')" "SSHVaultX VPN" "User Commands"
.SH NAME
sshvaultx \- Fast and Secure SSH over VPN with SOCKS5 proxy support
.SH SYNOPSIS
.B sshvaultx
[\fIOPTIONS\fR]
.SH DESCRIPTION
SSHVaultX is a fast and secure SSH over VPN tool with SOCKS5 proxy support.
It provides an easy way to create secure tunnels through SSH servers and
route traffic through them using SOCKS5 proxy protocol.
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

build_package() {
    print_status "Building Debian package..."
    
    # Calculate installed size
    local size=$(du -sk "${DEB_DIR}" | cut -f1)
    echo "Installed-Size: ${size}" >> "${CONTROL_DIR}/control"
    
    # Build the package
    fakeroot dpkg-deb --build "${DEB_DIR}" "${BUILD_DIR}/"
    
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
        
    else
        print_error "Package build failed!"
        exit 1
    fi
}

show_usage() {
    echo "SSHVaultX Debian Package Builder"
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
    
    print_status "Starting SSHVaultX Debian package build..."
    print_status "Version: ${VERSION}"
    print_status "Architecture: ${ARCHITECTURE}"
    
    check_dependencies
    clean_build
    create_directories
    create_control_file
    create_install_script
    create_remove_script
    copy_files
    create_man_page
    build_package
    
    print_success "Build completed successfully!"
    print_status "To install the package: sudo dpkg -i ${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
    print_status "To remove the package: sudo dpkg -r ${PACKAGE_NAME}"
}

# Run main function with all arguments
main "$@"
