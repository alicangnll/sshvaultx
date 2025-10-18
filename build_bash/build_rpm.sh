#!/bin/bash

# SSHVaultX RPM Package Builder
# This script creates an RPM package for SSHVaultX VPN

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
RELEASE="1"
VENDOR="alicangnll"
MAINTAINER="Ali Can Gönüllü <info@alicangonullu.com>"
DESCRIPTION="Fast and Secure SSH over VPN with SOCKS5 proxy support"
HOMEPAGE="https://github.com/alicangnll/sshvaultx"
ARCHITECTURE="noarch"
REQUIRES="python3, python3-paramiko"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Directories
BUILD_DIR="${PROJECT_ROOT}/build"
RPM_DIR="${BUILD_DIR}/rpm"
SPEC_DIR="${RPM_DIR}/SPECS"
SOURCES_DIR="${RPM_DIR}/SOURCES"
BUILDROOT_DIR="${RPM_DIR}/BUILDROOT"
RPMS_DIR="${RPM_DIR}/RPMS"
SRPMS_DIR="${RPM_DIR}/SRPMS"

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
    
    if ! command -v rpmbuild &> /dev/null; then
        missing_deps+=("rpm-build")
    fi
    
    if ! command -v fakeroot &> /dev/null; then
        missing_deps+=("fakeroot")
    fi
    
    if ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    if ! command -v gzip &> /dev/null; then
        missing_deps+=("gzip")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Install them with:"
        print_status "  CentOS/RHEL: sudo yum install ${missing_deps[*]}"
        print_status "  Fedora: sudo dnf install ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All dependencies found"
}

clean_build() {
    print_status "Cleaning previous build..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${RPM_DIR}"
    print_success "Build directory cleaned"
}

create_rpm_directories() {
    print_status "Creating RPM build directories..."
    mkdir -p "${SPEC_DIR}"
    mkdir -p "${SOURCES_DIR}"
    mkdir -p "${BUILDROOT_DIR}"
    mkdir -p "${RPMS_DIR}"
    mkdir -p "${SRPMS_DIR}"
    mkdir -p "${RPM_DIR}/BUILD"
    mkdir -p "${RPM_DIR}/tmp"
    print_success "RPM directories created"
}

create_spec_file() {
    print_status "Creating RPM spec file..."
    cat > "${SPEC_DIR}/${PACKAGE_NAME}.spec" << EOF
Name:           ${PACKAGE_NAME}
Version:        ${VERSION}
Release:        ${RELEASE}%{?dist}
Summary:        ${DESCRIPTION}

License:        MIT
URL:            ${HOMEPAGE}
Source0:        %{name}-%{version}.tar.gz

BuildArch:      ${ARCHITECTURE}
Requires:       ${REQUIRES}

%description
SSHVaultX is a fast and secure SSH over VPN tool with SOCKS5 proxy support.
It provides an easy way to create secure tunnels through SSH servers and
route traffic through them using SOCKS5 proxy protocol.

Features:
- SOCKS5 Proxy Support
- Cross-Platform (Windows, macOS, Linux)
- Multiple Authentication Methods (Password and SSH Key)
- Windows Integration with automatic proxy configuration
- Interactive Mode
- Retry Logic with configurable timeouts

%prep
%setup -q -n %{name}-%{version}

%build
# No build step needed for Python script

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/%{name}
mkdir -p %{buildroot}/usr/share/doc/%{name}
mkdir -p %{buildroot}/usr/share/man/man1

# Install main script
install -m 755 main.py %{buildroot}/usr/bin/%{name}

# Install requirements
install -m 644 requirements.txt %{buildroot}/usr/share/%{name}/

# Install documentation
install -m 644 README.md %{buildroot}/usr/share/doc/%{name}/

# Create changelog
cat > %{buildroot}/usr/share/doc/%{name}/changelog << 'CHANGELOG_EOF'
%{name} (%{version}-%{release}) unstable; urgency=medium

  * Initial release
  * SOCKS5 proxy support
  * Cross-platform compatibility
  * SSH key and password authentication
  * Windows proxy integration

 -- ${MAINTAINER}  $(date -R)
CHANGELOG_EOF

gzip -9 %{buildroot}/usr/share/doc/%{name}/changelog

# Create copyright file
cat > %{buildroot}/usr/share/doc/%{name}/copyright << 'COPYRIGHT_EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: %{name}
Source: %{url}

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
COPYRIGHT_EOF

# Create man page
cat > %{buildroot}/usr/share/man/man1/%{name}.1 << 'MANPAGE_EOF'
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
%{url}
.SH COPYRIGHT
Copyright (C) $(date +%Y) alicangnll. License MIT.
MANPAGE_EOF

gzip -9 %{buildroot}/usr/share/man/man1/%{name}.1

%files
%defattr(-,root,root,-)
/usr/bin/%{name}
/usr/share/%{name}/requirements.txt
/usr/share/doc/%{name}/README.md
/usr/share/doc/%{name}/changelog.gz
/usr/share/doc/%{name}/copyright
/usr/share/man/man1/%{name}.1.gz

%changelog
* $(date '+%a %b %d %Y') ${MAINTAINER} - %{version}-%{release}
- Initial release
- SOCKS5 proxy support
- Cross-platform compatibility
- SSH key and password authentication
- Windows proxy integration

EOF
    print_success "RPM spec file created"
}

create_source_tarball() {
    print_status "Creating source tarball..."
    
    local tarball_name="${PACKAGE_NAME}-${VERSION}"
    local tarball_dir="${BUILD_DIR}/${tarball_name}"
    
    # Ensure SOURCES directory exists
    mkdir -p "${SOURCES_DIR}"
    
    # Create temporary directory for tarball
    mkdir -p "${tarball_dir}"
    
    # Copy source files
    cp ../main.py "${tarball_dir}/"
    cp ../requirements.txt "${tarball_dir}/"
    cp ../README.md "${tarball_dir}/"
    
    # Create tarball using relative paths
    tar -czf "${SOURCES_DIR}/${tarball_name}.tar.gz" -C "${BUILD_DIR}" "${tarball_name}/"
    
    # Clean up temporary directory
    rm -rf "${tarball_dir}"
    
    print_success "Source tarball created: ${SOURCES_DIR}/${tarball_name}.tar.gz"
}

build_rpm() {
    print_status "Building RPM package..."
    
    # Build the RPM using relative paths
    rpmbuild --define "_topdir ${RPM_DIR}" \
             --define "_builddir ${RPM_DIR}/BUILD" \
             --define "_rpmdir ${RPMS_DIR}" \
             --define "_sourcedir ${SOURCES_DIR}" \
             --define "_specdir ${SPEC_DIR}" \
             --define "_srcrpmdir ${SRPMS_DIR}" \
             --define "_buildrootdir ${BUILDROOT_DIR}" \
             --define "_tmppath ${RPM_DIR}/tmp" \
             -ba "${SPEC_DIR}/${PACKAGE_NAME}.spec"
    
    # Find the built RPM
    local rpm_file=$(find "${RPMS_DIR}" -name "*.rpm" | head -1)
    local srpm_file=$(find "${SRPMS_DIR}" -name "*.rpm" | head -1)
    
    if [ -f "${rpm_file}" ]; then
        print_success "RPM package built successfully: ${rpm_file}"
        
        # Show package info
        print_status "RPM package information:"
        rpm -qip "${rpm_file}"
        
        # Show package contents
        print_status "RPM package contents:"
        rpm -qlp "${rpm_file}"
        
        # Show package size
        local package_size=$(du -h "${rpm_file}" | cut -f1)
        print_success "RPM package size: ${package_size}"
        
        # Copy to packages directory
        mkdir -p packages
        cp "${rpm_file}" packages/
        print_success "RPM copied to packages directory"
        
    else
        print_error "RPM package build failed!"
        exit 1
    fi
    
    if [ -f "${srpm_file}" ]; then
        print_success "Source RPM built successfully: ${srpm_file}"
        cp "${srpm_file}" packages/
        print_success "Source RPM copied to packages directory"
    fi
}

install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Check if pip is available
    if command -v pip3 &> /dev/null; then
        pip3 install --user paramiko
        print_success "Python dependencies installed via pip3"
    elif command -v python3 -m pip &> /dev/null; then
        python3 -m pip install --user paramiko
        print_success "Python dependencies installed via python3 -m pip"
    else
        print_warning "pip not found. Please install paramiko manually:"
        print_warning "  CentOS/RHEL: sudo yum install python3-paramiko"
        print_warning "  Fedora: sudo dnf install python3-paramiko"
    fi
}

show_usage() {
    echo "SSHVaultX RPM Package Builder"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Set package version (default: ${VERSION})"
    echo "  -r, --release  Set package release (default: ${RELEASE})"
    echo "  -c, --clean    Clean build directory and exit"
    echo "  -i, --install  Install dependencies and exit"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build with default version"
    echo "  $0 --version 1.2.3   # Build with custom version"
    echo "  $0 --release 2       # Build with custom release"
    echo "  $0 --clean           # Clean build directory"
    echo "  $0 --install          # Install dependencies"
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
            -r|--release)
                RELEASE="$2"
                shift 2
                ;;
            -c|--clean)
                print_status "Cleaning build directory..."
                rm -rf "${BUILD_DIR}"
                print_success "Build directory cleaned"
                exit 0
                ;;
            -i|--install)
                install_dependencies
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "Starting SSHVaultX RPM package build..."
    print_status "Version: ${VERSION}"
    print_status "Release: ${RELEASE}"
    print_status "Architecture: ${ARCHITECTURE}"
    
    check_dependencies
    clean_build
    create_rpm_directories
    create_spec_file
    create_source_tarball
    build_rpm
    
    print_success "Build completed successfully!"
    print_status "To install the RPM: sudo rpm -i packages/${PACKAGE_NAME}-${VERSION}-${RELEASE}.*.rpm"
    print_status "To remove the RPM: sudo rpm -e ${PACKAGE_NAME}"
    print_status "To install with dependencies: sudo yum localinstall packages/${PACKAGE_NAME}-${VERSION}-${RELEASE}.*.rpm"
}

# Run main function with all arguments
main "$@"
