#!/bin/bash

# ================================================================
# DonkTool Master Installation Script
# ================================================================
# Comprehensive installation script for all DonkTool capabilities
# 
# This script installs:
# - Core penetration testing tools
# - Web application security tools  
# - Network assessment tools
# - Bluetooth security tools
# - DoS testing tools (with authorization)
# 
# Requires: macOS 14.0+, Homebrew, Xcode Command Line Tools
# ================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_NAME="DonkTool Master Installer"
readonly VERSION="2.0.0"
readonly LOG_FILE="./master-install.log"

# Installation tracking
declare -a INSTALLED_TOOLS=()
declare -a FAILED_TOOLS=()
declare -i TOTAL_TOOLS=0
declare -i SUCCESS_COUNT=0
declare -i FAIL_COUNT=0

# ================================================================
# Utility Functions
# ================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "  $SCRIPT_NAME v$VERSION"
    echo "================================================================"
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${CYAN}🔧 $1${NC}"
    echo "================================================================"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log "INFO: $1"
}

# ================================================================
# System Checks
# ================================================================

check_system_requirements() {
    print_section "System Requirements Check"
    
    # Check macOS version
    local macos_version
    macos_version=$(sw_vers -productVersion)
    local major_version
    major_version=$(echo "$macos_version" | cut -d '.' -f 1)
    
    if [[ "$major_version" -lt 14 ]]; then
        print_error "macOS 14.0+ required. Current: $macos_version"
        exit 1
    fi
    print_success "macOS Version: $macos_version ✓"
    
    # Check Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        print_error "Xcode Command Line Tools not installed"
        print_info "Run: xcode-select --install"
        exit 1
    fi
    print_success "Xcode Command Line Tools ✓"
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not installed"
        print_info "Install from: https://brew.sh"
        exit 1
    fi
    print_success "Homebrew $(brew --version | head -1) ✓"
    
    # Check available disk space (minimum 5GB)
    local available_space
    available_space=$(df -h . | awk 'NR==2{print $4}' | sed 's/G.*//')
    if [[ "${available_space%.*}" -lt 5 ]]; then
        print_warning "Low disk space: ${available_space}GB available (5GB+ recommended)"
    else
        print_success "Disk Space: ${available_space}GB available ✓"
    fi
}

# ================================================================
# Tool Installation Functions
# ================================================================

install_tool() {
    local tool_name="$1"
    local install_command="$2"
    local verify_command="$3"
    
    ((TOTAL_TOOLS++))
    
    echo -e "\n${YELLOW}Installing $tool_name...${NC}"
    
    if eval "$verify_command" &> /dev/null; then
        print_success "$tool_name already installed"
        INSTALLED_TOOLS+=("$tool_name")
        ((SUCCESS_COUNT++))
        return 0
    fi
    
    if eval "$install_command" &> /dev/null; then
        if eval "$verify_command" &> /dev/null; then
            print_success "$tool_name installed successfully"
            INSTALLED_TOOLS+=("$tool_name")
            ((SUCCESS_COUNT++))
        else
            print_error "$tool_name installation failed (verification failed)"
            FAILED_TOOLS+=("$tool_name")
            ((FAIL_COUNT++))
        fi
    else
        print_error "$tool_name installation failed"
        FAILED_TOOLS+=("$tool_name")
        ((FAIL_COUNT++))
    fi
}

install_python_tool() {
    local tool_name="$1"
    local package_name="$2"
    
    install_tool "$tool_name" "pip3 install $package_name" "pip3 show $package_name"
}

install_go_tool() {
    local tool_name="$1"
    local package_url="$2"
    local binary_name="${3:-$tool_name}"
    
    install_tool "$tool_name" "go install $package_url@latest" "command -v $binary_name"
}

install_github_tool() {
    local tool_name="$1"
    local repo_url="$2"
    local install_dir="$HOME/security-tools"
    
    mkdir -p "$install_dir"
    
    install_tool "$tool_name" \
        "cd '$install_dir' && git clone '$repo_url' '$tool_name' && cd '$tool_name' && make install 2>/dev/null || true" \
        "test -d '$install_dir/$tool_name'"
}

# ================================================================
# Core Penetration Testing Tools
# ================================================================

install_core_tools() {
    print_section "Core Penetration Testing Tools"
    
    # Update Homebrew
    echo -e "\n${YELLOW}Updating Homebrew...${NC}"
    brew update
    
    # Network scanning and enumeration
    install_tool "nmap" "brew install nmap" "command -v nmap"
    install_tool "masscan" "brew install masscan" "command -v masscan"
    install_tool "zmap" "brew install zmap" "command -v zmap"
    
    # Web application testing
    install_tool "sqlmap" "brew install sqlmap" "command -v sqlmap"
    install_tool "nikto" "brew install nikto" "command -v nikto"
    install_tool "gobuster" "brew install gobuster" "command -v gobuster"
    install_tool "dirb" "brew install dirb" "command -v dirb"
    install_tool "ffuf" "brew install ffuf" "command -v ffuf"
    install_tool "feroxbuster" "brew install feroxbuster" "command -v feroxbuster"
    
    # SSL/TLS testing
    install_tool "sslyze" "brew install sslyze" "command -v sslyze"
    install_tool "sslscan" "brew install sslscan" "command -v sslscan"
    install_tool "testssl" "brew install testssl" "command -v testssl"
    
    # Password attacks
    install_tool "hydra" "brew install hydra" "command -v hydra"
    install_tool "john" "brew install john" "command -v john"
    install_tool "hashcat" "brew install hashcat" "command -v hashcat"
    
    # Exploitation frameworks
    install_tool "metasploit" "brew install metasploit" "command -v msfconsole"
    
    # Network analysis
    install_tool "wireshark" "brew install --cask wireshark" "test -d '/Applications/Wireshark.app'"
    install_tool "tcpdump" "echo 'tcpdump pre-installed'" "command -v tcpdump"
    install_tool "ngrep" "brew install ngrep" "command -v ngrep"
}

# ================================================================
# Advanced Web Application Security Tools
# ================================================================

install_web_tools() {
    print_section "Web Application Security Tools"
    
    # Modern web security tools
    install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx"
    install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana"
    install_go_tool "dnsx" "github.com/projectdiscovery/dnsx/cmd/dnsx"
    install_go_tool "naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu"
    
    # Web proxies and testing tools
    install_tool "burp-suite" "brew install --cask burp-suite" "test -d '/Applications/Burp Suite Community Edition.app'"
    install_tool "zaproxy" "brew install --cask zap" "test -d '/Applications/ZAP.app'"
    
    # Additional web tools
    install_python_tool "dirsearch" "dirsearch"
    install_python_tool "wfuzz" "wfuzz"
    install_tool "whatweb" "brew install whatweb" "command -v whatweb"
    
    # Install custom wordlists
    local wordlist_dir="$HOME/.local/share/wordlists"
    mkdir -p "$wordlist_dir"
    
    if [[ ! -f "$wordlist_dir/common.txt" ]]; then
        echo -e "\n${YELLOW}Installing wordlists...${NC}"
        curl -s "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" -o "$wordlist_dir/common.txt"
        curl -s "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt" -o "$wordlist_dir/directory-list-medium.txt"
        print_success "Wordlists installed"
    fi
}

# ================================================================
# Bluetooth Security Tools
# ================================================================

install_bluetooth_tools() {
    print_section "Bluetooth Security Tools"
    
    print_info "Note: Primary Bluetooth security capabilities are built into DonkTool using native macOS frameworks"
    
    # Bluetooth analysis tools
    install_tool "bluez" "brew install bluez" "brew list bluez"
    install_tool "bettercap" "brew install bettercap" "command -v bettercap"
    
    # Ubertooth tools (if available)
    install_tool "ubertooth" "brew install ubertooth" "brew list ubertooth" || true
    
    # Python Bluetooth libraries
    install_python_tool "bleak" "bleak"
    install_python_tool "pybluez" "pybluez"
    
    print_success "Bluetooth security framework ready (native macOS CoreBluetooth/IOBluetooth)"
}

# ================================================================
# DoS Testing Tools (Requires Authorization)
# ================================================================

install_dos_tools() {
    print_section "DoS Testing Tools Installation"
    
    echo -e "${RED}"
    echo "⚠️  WARNING: DoS TESTING TOOLS INSTALLATION ⚠️"
    echo "================================================================"
    echo "These tools are designed for authorized penetration testing ONLY"
    echo "Unauthorized use is illegal and can result in criminal charges"
    echo "================================================================"
    echo -e "${NC}"
    
    echo -e "\n${YELLOW}Authorization Requirements:${NC}"
    echo "✓ I have explicit written permission to test target systems"
    echo "✓ I understand the legal implications of DoS testing"
    echo "✓ I will use these tools only for authorized security testing"
    echo "✓ I accept full responsibility for proper use"
    
    echo -e "\n${BLUE}Do you agree to these terms and wish to install DoS testing tools?${NC}"
    read -p "Type 'I AGREE' to continue or 'NO' to skip: " -r authorization
    
    if [[ "$authorization" != "I AGREE" ]]; then
        print_warning "DoS tools installation skipped"
        return 0
    fi
    
    print_info "Installing DoS testing tools with authorization..."
    
    # HTTP stress testing tools
    install_tool "wrk" "brew install wrk" "command -v wrk"
    install_tool "artillery" "npm install -g artillery" "command -v artillery"
    install_tool "siege" "brew install siege" "command -v siege"
    
    # Low-and-slow attack tools
    install_tool "slowhttptest" "brew install slowhttptest" "command -v slowhttptest"
    
    # Network layer tools
    install_tool "hping3" "brew install hping3" "command -v hping3"
    install_tool "t50" "brew install t50" "command -v t50"
    
    # Install Python-based DoS tools
    local dos_tools_dir="$HOME/security-tools/dos-tools"
    mkdir -p "$dos_tools_dir"
    
    # Install popular DoS testing scripts
    install_github_tool "goldeneye" "https://github.com/jseidl/GoldenEye.git"
    install_github_tool "hulk" "https://github.com/grafov/hulk.git"
    install_github_tool "xerxes" "https://github.com/zanyarjamal/xerxes.git"
    
    print_success "DoS testing tools installed with authorization"
}

# ================================================================
# Additional Security Tools
# ================================================================

install_additional_tools() {
    print_section "Additional Security Tools"
    
    # Reverse engineering
    install_tool "radare2" "brew install radare2" "command -v r2"
    install_tool "ghidra" "brew install --cask ghidra" "test -d '/Applications/ghidra.app'"
    
    # Forensics
    install_tool "volatility3" "pip3 install volatility3" "pip3 show volatility3"
    install_tool "autopsy" "brew install --cask autopsy" "test -d '/Applications/Autopsy.app'"
    
    # Mobile security
    install_tool "frida" "pip3 install frida-tools" "command -v frida"
    install_tool "objection" "pip3 install objection" "command -v objection"
    
    # Cloud security
    install_tool "awscli" "brew install awscli" "command -v aws"
    install_tool "azure-cli" "brew install azure-cli" "command -v az"
    
    # Container security
    install_tool "docker" "brew install --cask docker" "command -v docker"
    install_tool "trivy" "brew install trivy" "command -v trivy"
}

# ================================================================
# Post-Installation Setup
# ================================================================

setup_environment() {
    print_section "Environment Setup"
    
    # Create security tools directory structure
    local tools_dir="$HOME/security-tools"
    mkdir -p "$tools_dir"/{wordlists,exploits,scripts,reports,evidence}
    
    # Set up PATH additions
    local bash_profile="$HOME/.bash_profile"
    local zsh_profile="$HOME/.zshrc"
    
    # Go PATH setup
    local go_path="export PATH=\$PATH:\$(go env GOPATH)/bin"
    
    if [[ -f "$zsh_profile" ]]; then
        if ! grep -q "$(go env GOPATH)/bin" "$zsh_profile"; then
            echo -e "\n# DonkTool Security Tools PATH" >> "$zsh_profile"
            echo "$go_path" >> "$zsh_profile"
            print_success "Updated ~/.zshrc with Go tools PATH"
        fi
    fi
    
    if [[ -f "$bash_profile" ]]; then
        if ! grep -q "$(go env GOPATH)/bin" "$bash_profile"; then
            echo -e "\n# DonkTool Security Tools PATH" >> "$bash_profile"
            echo "$go_path" >> "$bash_profile"
            print_success "Updated ~/.bash_profile with Go tools PATH"
        fi
    fi
    
    # Update Nuclei templates
    if command -v nuclei &> /dev/null; then
        echo -e "\n${YELLOW}Updating Nuclei templates...${NC}"
        nuclei -update-templates
        print_success "Nuclei templates updated"
    fi
    
    # Create DonkTool configuration
    local config_dir="$HOME/.config/donktool"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/tools.conf" << EOF
# DonkTool Security Tools Configuration
# Generated by master-install.sh v$VERSION on $(date)

TOOLS_DIR="$tools_dir"
WORDLISTS_DIR="$tools_dir/wordlists"
EXPLOITS_DIR="$tools_dir/exploits"
REPORTS_DIR="$tools_dir/reports"
EVIDENCE_DIR="$tools_dir/evidence"

# Tool paths will be auto-detected by DonkTool
# Manual overrides can be specified here if needed
EOF
    
    print_success "DonkTool configuration created at $config_dir/tools.conf"
}

# ================================================================
# Installation Summary
# ================================================================

print_summary() {
    print_section "Installation Summary"
    
    echo -e "\n${GREEN}Installation Complete!${NC}"
    echo "================================================================"
    echo -e "Total tools processed: ${BLUE}$TOTAL_TOOLS${NC}"
    echo -e "Successfully installed: ${GREEN}$SUCCESS_COUNT${NC}"
    echo -e "Failed installations: ${RED}$FAIL_COUNT${NC}"
    
    if [[ ${#INSTALLED_TOOLS[@]} -gt 0 ]]; then
        echo -e "\n${GREEN}✅ Successfully Installed Tools:${NC}"
        printf '%s\n' "${INSTALLED_TOOLS[@]}" | sort | column -c 80
    fi
    
    if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
        echo -e "\n${RED}❌ Failed Installations:${NC}"
        printf '%s\n' "${FAILED_TOOLS[@]}" | sort
        echo -e "\n${YELLOW}Check the log file for details: $LOG_FILE${NC}"
    fi
    
    echo -e "\n${CYAN}Next Steps:${NC}"
    echo "1. Open DonkTool.xcodeproj in Xcode"
    echo "2. Build and run the application (⌘+R)"
    echo "3. Verify tool installation in Settings"
    echo "4. Review and accept the ethical use policy"
    echo "5. Begin authorized security testing"
    
    echo -e "\n${BLUE}Security Reminder:${NC}"
    echo "⚠️  Always obtain explicit written permission before testing"
    echo "⚠️  Follow all applicable laws and regulations"
    echo "⚠️  Use these tools responsibly and ethically"
    
    if [[ $SUCCESS_COUNT -eq $TOTAL_TOOLS ]]; then
        echo -e "\n${GREEN}🎉 Perfect installation! All tools ready for use.${NC}"
    elif [[ $SUCCESS_COUNT -gt $((TOTAL_TOOLS * 3 / 4)) ]]; then
        echo -e "\n${YELLOW}⚠️  Most tools installed successfully. Check failed items above.${NC}"
    else
        echo -e "\n${RED}⚠️  Several installations failed. Review log and retry.${NC}"
    fi
}

# ================================================================
# Main Installation Flow
# ================================================================

main() {
    # Initialize log
    echo "DonkTool Master Installation Log - $(date)" > "$LOG_FILE"
    
    print_header
    
    echo -e "${PURPLE}Welcome to the DonkTool Master Installation Script!${NC}"
    echo "This will install all tools needed for comprehensive security testing."
    echo ""
    echo -e "${YELLOW}⚠️  Important: This installation requires administrative privileges${NC}"
    echo -e "${YELLOW}⚠️  and will install numerous security testing tools.${NC}"
    echo ""
    echo -e "${BLUE}Installation includes:${NC}"
    echo "• Core penetration testing tools (nmap, sqlmap, hydra, etc.)"
    echo "• Web application security tools (nuclei, burp-suite, etc.)" 
    echo "• Bluetooth security tools (native macOS + additional tools)"
    echo "• DoS testing tools (requires separate authorization)"
    echo "• Additional security tools (forensics, reverse engineering)"
    echo ""
    
    read -p "Continue with installation? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Run installation steps
    check_system_requirements
    install_core_tools
    install_web_tools
    install_bluetooth_tools
    install_dos_tools
    install_additional_tools
    setup_environment
    print_summary
    
    print_success "DonkTool Master Installation completed!"
    print_info "Log saved to: $LOG_FILE"
}

# ================================================================
# Script Execution
# ================================================================

# Trap errors and cleanup
trap 'print_error "Installation interrupted"; exit 1' INT TERM

# Check if running as root (not recommended)
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root is not recommended"
    print_info "Some tools work better with standard user permissions"
fi

# Run main installation
main "$@"

# Make tools available immediately
if [[ -n "${ZSH_VERSION:-}" ]]; then
    print_info "Run 'source ~/.zshrc' to update PATH, or restart terminal"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    print_info "Run 'source ~/.bash_profile' to update PATH, or restart terminal" 
fi

exit 0