#!/bin/bash

echo "🔧 Installing Missing Offensive Security Tools"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install recon-ng properly
echo -e "${YELLOW}Installing recon-ng...${NC}"
if ! command_exists recon-ng; then
    cd /tmp
    if [ ! -d "recon-ng" ]; then
        git clone https://github.com/lanmaster53/recon-ng.git
    fi
    cd recon-ng
    
    # Install dependencies
    pip3 install -r REQUIREMENTS
    
    # Create symlink
    if [ ! -f "/usr/local/bin/recon-ng" ]; then
        sudo ln -sf "$(pwd)/recon-ng" /usr/local/bin/recon-ng
    fi
    
    # Make executable
    chmod +x recon-ng
    
    echo -e "${GREEN}✓ recon-ng installed successfully${NC}"
else
    echo -e "${GREEN}✓ recon-ng already installed${NC}"
fi

# Install wpscan using gem
echo -e "${YELLOW}Installing wpscan...${NC}"
if ! command_exists wpscan; then
    # Install using gem with user directory
    gem install --user-install wpscan
    
    # Add to PATH if needed  
    if ! command_exists wpscan; then
        # Try system gem install with sudo
        echo "Attempting system-wide installation..."
        sudo gem install wpscan
    fi
    
    if command_exists wpscan; then
        echo -e "${GREEN}✓ wpscan installed successfully${NC}"
    else
        echo -e "${RED}✗ wpscan installation failed${NC}"
        echo "You may need to install Ruby development tools: xcode-select --install"
    fi
else
    echo -e "${GREEN}✓ wpscan already installed${NC}"
fi

# Verify bettercap
echo -e "${YELLOW}Checking bettercap...${NC}"
if command_exists bettercap; then
    echo -e "${GREEN}✓ bettercap is available${NC}"
else
    echo -e "${YELLOW}Installing bettercap...${NC}"
    brew install bettercap
fi

# Create improved askpass helper
echo -e "${YELLOW}Setting up improved sudo helper...${NC}"
cat > /tmp/donktool-sudo.sh << 'EOF'
#!/bin/bash
# Enhanced DonkTool sudo helper

# Check if running in terminal
if [ -t 0 ]; then
    # Terminal mode - use standard sudo
    sudo "$@"
else
    # GUI mode - use osascript
    osascript -e "do shell script \"$*\" with administrator privileges"
fi
EOF

chmod +x /tmp/donktool-sudo.sh
echo -e "${GREEN}✓ Enhanced sudo helper created${NC}"

# Install additional tools that might be missing
echo -e "${YELLOW}Installing additional security tools...${NC}"

# Install aircrack-ng suite if not present
if ! command_exists aircrack-ng; then
    brew install aircrack-ng
fi

# Install responder if not present
if [ ! -d "/opt/Responder" ]; then
    sudo mkdir -p /opt
    cd /opt
    sudo git clone https://github.com/SpiderLabs/Responder.git
    sudo chmod +x /opt/Responder/Responder.py
fi

echo -e "\n${GREEN}=== Installation Summary ===${NC}"
echo -e "${YELLOW}Checking tool availability:${NC}"

for tool in recon-ng wpscan bettercap aircrack-ng; do
    if command_exists $tool; then
        echo -e "${GREEN}✓ $tool${NC}"
    else
        echo -e "${RED}✗ $tool${NC}"
    fi
done

# Special check for Responder
if [ -f "/opt/Responder/Responder.py" ]; then
    echo -e "${GREEN}✓ Responder${NC}"
else
    echo -e "${RED}✗ Responder${NC}"
fi

echo -e "\n${GREEN}Installation process complete!${NC}"
echo -e "${YELLOW}Note: Some tools may require additional setup or API keys${NC}"