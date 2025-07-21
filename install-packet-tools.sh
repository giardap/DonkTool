#!/bin/bash

# DonkTool Professional Packet Capture Tools Installation Script
# This script installs Wireshark CLI tools and other packet analysis utilities

echo "🦈 DonkTool Professional Packet Capture Tools Installer"
echo "======================================================"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install with Homebrew
install_with_brew() {
    if ! command_exists brew; then
        echo "📦 Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            export PATH="/usr/local/bin:$PATH"
        fi
    else
        echo "✅ Homebrew is already installed"
    fi
    
    echo "🔄 Updating Homebrew..."
    brew update
}

# Install Wireshark (includes tshark, dumpcap, and other CLI tools)
install_wireshark() {
    echo "🦈 Installing Wireshark CLI Tools..."
    
    if command_exists tshark; then
        echo "✅ tshark is already installed"
        tshark --version | head -1
    else
        echo "📦 Installing Wireshark (includes tshark CLI)..."
        brew install --cask wireshark
        
        # Add Wireshark CLI tools to PATH
        if [[ -d "/Applications/Wireshark.app/Contents/MacOS" ]]; then
            echo "🔗 Adding Wireshark CLI tools to PATH..."
            
            # Create symlinks for easier access
            sudo ln -sf "/Applications/Wireshark.app/Contents/MacOS/tshark" "/usr/local/bin/tshark" 2>/dev/null
            sudo ln -sf "/Applications/Wireshark.app/Contents/MacOS/dumpcap" "/usr/local/bin/dumpcap" 2>/dev/null
            sudo ln -sf "/Applications/Wireshark.app/Contents/MacOS/capinfos" "/usr/local/bin/capinfos" 2>/dev/null
            sudo ln -sf "/Applications/Wireshark.app/Contents/MacOS/editcap" "/usr/local/bin/editcap" 2>/dev/null
            
            echo "✅ Wireshark CLI tools linked to /usr/local/bin/"
        fi
    fi
}

# Install additional network analysis tools
install_network_tools() {
    echo "🔧 Installing additional network analysis tools..."
    
    # nmap for network scanning
    if ! command_exists nmap; then
        echo "📦 Installing nmap..."
        brew install nmap
    else
        echo "✅ nmap is already installed"
    fi
    
    # iftop for real-time interface monitoring
    if ! command_exists iftop; then
        echo "📦 Installing iftop..."
        brew install iftop
    else
        echo "✅ iftop is already installed"
    fi
    
    # netcat for network connections
    if ! command_exists nc; then
        echo "📦 Installing netcat..."
        brew install netcat
    else
        echo "✅ netcat is already installed"
    fi
    
    # mtr for network diagnostics
    if ! command_exists mtr; then
        echo "📦 Installing mtr..."
        brew install mtr
    else
        echo "✅ mtr is already installed"
    fi
}

# Install Python packet analysis tools (optional)
install_python_tools() {
    echo "🐍 Installing Python packet analysis tools..."
    
    if command_exists python3; then
        echo "📦 Installing scapy (Python packet manipulation)..."
        pip3 install --user scapy
        
        echo "📦 Installing pyshark (Wireshark Python wrapper)..."
        pip3 install --user pyshark
        
        echo "✅ Python packet tools installed"
    else
        echo "⚠️  Python3 not found, skipping Python tools"
    fi
}

# Set up packet capture permissions
setup_permissions() {
    echo "🔐 Setting up packet capture permissions..."
    
    # Check if user is in admin group
    if groups | grep -q admin; then
        echo "✅ User is in admin group - can use sudo for packet capture"
    else
        echo "⚠️  User is not in admin group - may need additional permissions"
    fi
    
    # Create a script to help with tcpdump permissions
    cat > /tmp/packet-capture-helper.sh << 'EOF'
#!/bin/bash
# Helper script for packet capture with proper permissions
echo "Starting packet capture with admin privileges..."
echo "Interface: $1, Filter: $2"
sudo tcpdump -i "$1" -n -s 65535 -w - "$2"
EOF
    
    chmod +x /tmp/packet-capture-helper.sh
    echo "✅ Created packet capture helper script"
}

# Verify installations
verify_installations() {
    echo ""
    echo "🔍 Verifying installations..."
    echo "============================="
    
    # Check tshark
    if command_exists tshark; then
        echo "✅ tshark: $(which tshark)"
        tshark --version | head -1
    else
        echo "❌ tshark not found"
    fi
    
    # Check dumpcap
    if command_exists dumpcap; then
        echo "✅ dumpcap: $(which dumpcap)"
    else
        echo "❌ dumpcap not found"
    fi
    
    # Check tcpdump (should be built-in)
    if command_exists tcpdump; then
        echo "✅ tcpdump: $(which tcpdump)"
    else
        echo "❌ tcpdump not found"
    fi
    
    # Check other tools
    if command_exists nmap; then
        echo "✅ nmap: $(which nmap)"
    fi
    
    if command_exists iftop; then
        echo "✅ iftop: $(which iftop)"
    fi
    
    echo ""
    echo "📋 Network interfaces available:"
    ifconfig -l
    
    echo ""
    echo "🎯 Testing tshark (5 second capture)..."
    if command_exists tshark; then
        timeout 5s tshark -i en0 -c 5 2>/dev/null && echo "✅ tshark test successful" || echo "⚠️  tshark test failed (may need sudo)"
    fi
}

# Main installation process
main() {
    echo "🚀 Starting installation process..."
    echo ""
    
    # Install Homebrew if needed
    install_with_brew
    
    # Install Wireshark CLI tools
    install_wireshark
    
    # Install additional network tools
    install_network_tools
    
    # Install Python tools (optional)
    read -p "📦 Install Python packet analysis tools? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_python_tools
    fi
    
    # Set up permissions
    setup_permissions
    
    # Verify everything is working
    verify_installations
    
    echo ""
    echo "🎉 Installation complete!"
    echo "========================"
    echo ""
    echo "📱 DonkTool can now use these professional packet capture tools:"
    echo "   🦈 tshark (Wireshark CLI) - Primary engine"
    echo "   📡 dumpcap (Wireshark capture) - Secondary engine"
    echo "   🔧 tcpdump (Unix standard) - Fallback engine"
    echo ""
    echo "💡 Usage tips:"
    echo "   • Enable 'Admin Mode' in DonkTool for full packet access"
    echo "   • Enable 'Promiscuous Mode' to capture all network traffic"
    echo "   • Use BPF filters like 'host 192.168.1.1' for router traffic"
    echo ""
    echo "🔐 Admin privileges will be requested when starting packet capture"
    echo "✅ Ready to capture ALL network traffic to your router!"
}

# Run the installer
main "$@"