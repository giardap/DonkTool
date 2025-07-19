#!/bin/bash

# Install Python dependencies for DoS testing tools
# Required for MHDDoS and other Python-based tools

echo "🐍 Installing Python dependencies for DoS testing tools..."
echo "================================================================"

# Check if pip3 is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 not found. Please install Python 3 first."
    exit 1
fi

# Install required Python packages
echo "📦 Installing requests..."
pip3 install requests

echo "📦 Installing urllib3..."
pip3 install urllib3

echo "📦 Installing colorama (for colored output)..."
pip3 install colorama

echo "📦 Installing pysocks (for proxy support)..."
pip3 install pysocks

echo "📦 Installing certifi (for SSL verification)..."
pip3 install certifi

echo "📦 Installing charset-normalizer..."
pip3 install charset-normalizer

echo "📦 Installing idna..."
pip3 install idna

echo "📦 Installing threading support..."
pip3 install threading

echo ""
echo "✅ Python dependencies installation completed!"
echo "================================================================"
echo "MHDDoS and other Python-based DoS tools should now work properly."

# Test imports
echo ""
echo "🧪 Testing imports..."
python3 -c "import requests; print('✅ requests imported successfully')" 2>/dev/null || echo "❌ requests import failed"
python3 -c "import urllib3; print('✅ urllib3 imported successfully')" 2>/dev/null || echo "❌ urllib3 import failed"
python3 -c "import colorama; print('✅ colorama imported successfully')" 2>/dev/null || echo "❌ colorama import failed"

echo ""
echo "🎯 Python dependencies ready for DoS testing tools!"