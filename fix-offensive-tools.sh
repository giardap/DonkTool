#!/bin/bash

echo "🔧 Fixing Offensive Security Tools Installation"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install recon-ng
echo -e "${YELLOW}Installing recon-ng...${NC}"
if ! command_exists recon-ng; then
    # Install via pip3
    pip3 install recon-ng
    
    # If that doesn't work, try git clone method
    if ! command_exists recon-ng; then
        echo -e "${YELLOW}Installing recon-ng from source...${NC}"
        cd /tmp
        git clone https://github.com/lanmaster53/recon-ng.git
        cd recon-ng
        pip3 install -r REQUIREMENTS
        sudo ln -s $(pwd)/recon-ng /usr/local/bin/recon-ng
        cd -
    fi
else
    echo -e "${GREEN}✓ recon-ng already installed${NC}"
fi

# Install wpscan
echo -e "${YELLOW}Installing wpscan...${NC}"
if ! command_exists wpscan; then
    # Install Ruby first if needed
    if ! command_exists ruby; then
        brew install ruby
    fi
    
    # Install wpscan
    gem install wpscan
    
    # If gem install fails, try homebrew
    if ! command_exists wpscan; then
        brew install wpscan
    fi
else
    echo -e "${GREEN}✓ wpscan already installed${NC}"
fi

# Install bettercap dependencies
echo -e "${YELLOW}Installing bettercap dependencies...${NC}"
if ! command_exists bettercap; then
    brew install bettercap
else
    echo -e "${GREEN}✓ bettercap already installed${NC}"
fi

# Setup askpass for sudo operations
echo -e "${YELLOW}Setting up sudo askpass...${NC}"
cat > /tmp/donktool-askpass.sh << 'EOF'
#!/bin/bash
# DonkTool sudo askpass helper
osascript -e 'display dialog "DonkTool requires administrator privileges to run this security tool." default answer "" with title "Authentication Required" with icon caution with hidden answer' -e 'text returned of result' 2>/dev/null
EOF

chmod +x /tmp/donktool-askpass.sh
echo -e "${GREEN}✓ Askpass helper created${NC}"

# Verify installations
echo -e "\n${YELLOW}Verification:${NC}"
for tool in recon-ng wpscan bettercap; do
    if command_exists $tool; then
        echo -e "${GREEN}✓ $tool installed successfully${NC}"
        $tool --version 2>/dev/null || echo "   Version check not available"
    else
        echo -e "${RED}✗ $tool installation failed${NC}"
    fi
done

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Note: Tools requiring sudo (like bettercap) will prompt for password when executed.${NC}"