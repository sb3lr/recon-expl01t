# recon-expl01t

# Bug Bounty Tools Collection

<div align="center">
  <h1>🔍 Complete Bug Bounty Automation Suite</h1>
  <p><em>A comprehensive collection of 50+ security tools for automated reconnaissance and vulnerability discovery</em></p>
  
  ![Tools](https://img.shields.io/badge/Tools-50+-blue)
  ![Languages](https://img.shields.io/badge/Languages-Go%20%7C%20Python%20%7C%20Rust%20%7C%20C++-green)
  ![License](https://img.shields.io/badge/License-Various-red)
  ![Automation](https://img.shields.io/badge/Automation-Full%20Workflow-orange)
</div>

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Tools Included](#tools-included)
- [Automation Workflow](#automation-workflow)
- [Output Structure](#output-structure)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This repository contains a complete bug bounty automation suite with **50+ carefully selected security tools** organized into a streamlined workflow. The collection includes everything from subdomain enumeration to vulnerability scanning, all automated through intelligent scripts.

### Key Features

- **🚀 Full Automation**: Complete reconnaissance workflow with a single command
- **📊 Comprehensive Coverage**: 50+ tools across 11 different categories
- **⚡ Optimized Performance**: Parallel execution and intelligent timeouts
- **📁 Organized Output**: Structured results with detailed reporting
- **🔧 Easy Installation**: Automated setup for all tools and dependencies
- **🎨 Beautiful Reporting**: HTML and markdown reports with clear findings

### What Makes This Different

- **Intelligent Workflow**: Tools are executed in logical order with dependency management
- **Error Handling**: Robust error handling with fallbacks and alternative approaches
- **Resource Management**: Optimized for performance with configurable timeouts
- **Real-world Tested**: Used in actual bug bounty programs with proven results

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd bug-bounty-tools

# Install all tools (requires sudo)
sudo ./install_tools.sh

# Verify installation
./scan.sh

# Run full reconnaissance on a target
./auto_recon.sh example.com
```

## 📦 Installation

### Prerequisites

- **Operating System**: Linux (Ubuntu/Debian recommended)
- **Go**: Version 1.19 or higher
- **Python**: Version 3.9 or higher
- **Git**: For cloning repositories
- **Sudo Access**: Required for tool installation

### Automated Installation

```bash
# Make scripts executable
chmod +x install_tools.sh scan.sh auto_recon.sh

# Install all tools and dependencies
sudo ./install_tools.sh

# Verify installation status
./scan.sh
```

### Manual Installation

If you prefer to install tools individually, check the `bugbounty-tools/` directory where each tool has its own installation instructions.

## 🎮 Usage

### Basic Reconnaissance

```bash
# Run full reconnaissance on a domain
./auto_recon.sh target.com

# Run with URL (automatically extracts domain)
./auto_recon.sh https://target.com
```

### Check Tool Status

```bash
# Check which tools are installed
./scan.sh

# View detailed installation status
./scan.sh | grep -E "\[✔\]|\[✘\]"
```

### Individual Tool Usage

Each tool in the `bugbounty-tools/` directory can be used independently. Refer to their respective README files for specific usage instructions.

## 🛠️ Tools Included

### 🔍 Subdomain Enumeration (5 tools)
- **[Amass](bugbounty-tools/amass/)** - In-depth DNS enumeration and network mapping
- **[Subfinder](bugbounty-tools/subfinder/)** - Fast passive subdomain discovery
- **[Assetfinder](bugbounty-tools/assetfinder/)** - Find domains and subdomains related to a given domain
- **[Sublist3r](bugbounty-tools/Sublist3r/)** - Python tool for enumerating subdomains using OSINT
- **[Shuffledns](bugbounty-tools/shuffledns/)** - Wrapper around massdns for DNS resolution

### 🌐 DNS Resolution & Analysis (3 tools)
- **[dnsx](bugbounty-tools/dnsx/)** - Fast and multi-purpose DNS toolkit
- **[dnsprobe](bugbounty-tools/dnsprobe/)** - Tool for DNS resolution and discovery
- **[massdns](bugbounty-tools/massdns/)** - High-performance DNS stub resolver
- **[dnsgen](bugbounty-tools/dnsgen/)** - Generate DNS subdomain permutations

### 🔌 Port Scanning (2 tools)
- **[Naabu](https://github.com/projectdiscovery/naabu)** - Fast port scanner written in Go
- **[Nmap](https://nmap.org/)** - Network discovery and security auditing

### 🌍 HTTP Discovery (2 tools)
- **[httpx](https://github.com/projectdiscovery/httpx)** - Fast and multi-purpose HTTP toolkit
- **[httprobe](https://github.com/tomnomnom/httprobe)** - Take a list of domains and probe for working HTTP services

### 🔗 URL Discovery (6 tools)
- **[Katana](https://github.com/projectdiscovery/katana)** - Next-generation crawling and spidering framework
- **[waybackurls](https://github.com/tomnomnom/waybackurls)** - Fetch all URLs from the Wayback Machine
- **[GAU](https://github.com/lc/gau)** - Fetch known URLs from various sources
- **[GAU Plus](https://github.com/bp0lr/gauplus)** - Enhanced version of GAU
- **[Gospider](https://github.com/jaeles-project/gospider)** - Fast web spider written in Go
- **[urlhunter](https://github.com/utkusen/urlhunter)** - Recon tool for URLs

### 🔍 Parameter Discovery (3 tools)
- **[ParamSpider](bugbounty-tools/ParamSpider/)** - Mining parameters from dark corners of Web Archives
- **[Arjun](bugbounty-tools/Arjun/)** - HTTP parameter discovery suite
- **[unfurl](https://github.com/tomnomnom/unfurl)** - Pull out bits of URLs provided on stdin

### 📁 Content Discovery (3 tools)
- **[ffuf](https://github.com/ffuf/ffuf)** - Fast web fuzzer written in Go
- **[Feroxbuster](bugbounty-tools/feroxbuster/)** - Simple, fast, recursive content discovery tool
- **[dirsearch](bugbounty-tools/dirsearch/)** - Web path discovery tool

### 📜 JavaScript Analysis (4 tools)
- **[SecretFinder](bugbounty-tools/SecretFinder/)** - Tool for finding secrets in JavaScript files
- **[LinkFinder](bugbounty-tools/LinkFinder/)** - Discover endpoints and parameters in JavaScript files
- **[JSParser](bugbounty-tools/JSParser/)** - Parse JavaScript files for sensitive information
- **[xnLinkFinder](bugbounty-tools/xnLinkFinder/)** - Tool for discovering endpoints in JavaScript files

### 🚨 Vulnerability Scanning (6 tools)
- **[Nuclei](https://github.com/projectdiscovery/nuclei)** - Fast and customizable vulnerability scanner
- **[dalfox](bugbounty-tools/dalfox/)** - Advanced XSS detection and parameter analysis tool
- **[XSStrike](bugbounty-tools/XSStrike/)** - Advanced XSS detection suite
- **[OpenRedireX](bugbounty-tools/OpenRedireX/)** - Open redirect vulnerability scanner
- **[crlfuzz](https://github.com/dwisiswant0/crlfuzz)** - Fast tool to scan CRLF vulnerability
- **[kxss](https://github.com/Emoe/kxss)** - Tool for detecting XSS vulnerabilities

### 🎯 Subdomain Takeover (4 tools)
- **[SubJack](bugbounty-tools/subjack/)** - Subdomain takeover tool written in Go
- **[Subzy](https://github.com/PentestPad/subzy)** - Subdomain takeover vulnerability checker
- **[uncover](https://github.com/projectdiscovery/uncover)** - Quickly discover exposed hosts on the internet
- **[cero](https://github.com/glebarez/cero)** - Scrape domain names from SSL certificates

### 🔧 Additional Analysis (4 tools)
- **[hakrevdns](https://github.com/hakluke/hakrevdns)** - Reverse DNS lookups
- **[hakrawler](https://github.com/hakluke/hakrawler)** - Simple, fast web crawler
- **[http-request-smuggler](https://github.com/defparam/smuggler)** - HTTP request smuggling detection
- **[gf-patterns](bugbounty-tools/Gf-Patterns/)** - Collection of grep patterns for gf tool

### 🛠️ Utility Tools (7 tools)
- **[anew](https://github.com/tomnomnom/anew)** - Tool for adding new lines to files
- **[urldedupe](bugbounty-tools/urldedupe/)** - Remove duplicate URLs
- **[qsreplace](https://github.com/tomnomnom/qsreplace)** - Replace query string values
- **[gf](https://github.com/tomnomnom/gf)** - Wrapper around grep for easier pattern matching
- **[interactsh-client](https://github.com/projectdiscovery/interactsh)** - OOB interaction gathering server and client
- **[feroxbuster](bugbounty-tools/feroxbuster/)** - Fast, simple, recursive content discovery tool

## 🔄 Automation Workflow

The `auto_recon.sh` script executes tools in a carefully orchestrated workflow:

### Phase 1: Subdomain Enumeration
1. **Amass** - Comprehensive DNS enumeration (10 min timeout)
2. **Subfinder** - Fast passive discovery (5 min timeout)
3. **Assetfinder** - Related domain discovery (5 min timeout)
4. **Sublist3r** - OSINT-based enumeration (5 min timeout)
5. **Shuffledns** - DNS resolution validation (5 min timeout)
6. **crt.sh** - Certificate transparency logs

### Phase 2: DNS Resolution & Validation
1. **dnsx** - Resolve all discovered subdomains
2. **dnsprobe** - Validate DNS responses
3. **httpx** - Identify live HTTP services
4. **httprobe** - Probe for working web services

### Phase 3: Port & Service Discovery
1. **Naabu** - Fast port scanning on live hosts
2. **Nmap** - Detailed service enumeration on open ports

### Phase 4: URL & Content Discovery
1. **Katana** - Modern web crawling
2. **waybackurls** - Historical URL discovery
3. **GAU/GAU Plus** - Archive URL collection
4. **Gospider** - Fast web spidering
5. **ffuf** - Directory and file fuzzing
6. **Feroxbuster** - Recursive content discovery
7. **dirsearch** - Web path discovery

### Phase 5: Parameter & Endpoint Analysis
1. **ParamSpider** - Parameter mining from archives
2. **Arjun** - HTTP parameter discovery
3. **LinkFinder** - JavaScript endpoint extraction
4. **JSParser** - JavaScript analysis
5. **SecretFinder** - Secret discovery in JS files
6. **xnLinkFinder** - Advanced endpoint discovery

### Phase 6: Vulnerability Scanning
1. **Nuclei** - Comprehensive vulnerability scanning
2. **dalfox** - XSS detection and analysis
3. **XSStrike** - Advanced XSS testing
4. **OpenRedireX** - Open redirect detection
5. **crlfuzz** - CRLF injection testing
6. **kxss** - XSS vulnerability detection

### Phase 7: Subdomain Takeover & Additional Checks
1. **SubJack** - Subdomain takeover detection
2. **Subzy** - Takeover vulnerability checking
3. **hakrevdns** - Reverse DNS analysis
4. **http-request-smuggler** - HTTP smuggling detection

## 📊 Output Structure

Results are organized in a timestamped directory:

```
recon_target.com_20240119_143022/
├── REPORT.md                    # Comprehensive markdown report
├── subdomains/                  # Subdomain enumeration results
│   ├── all_subdomains.txt      # Deduplicated subdomain list
│   ├── live_subdomains.txt     # Resolved subdomains
│   ├── amass.txt               # Amass results
│   ├── subfinder.txt           # Subfinder results
│   └── ...                     # Individual tool outputs
├── urls/                        # URL discovery results
│   ├── all_urls.txt            # All discovered URLs
│   ├── deduplicated_urls.txt   # Cleaned URL list
│   ├── http_services.txt       # Live HTTP services
│   └── ...                     # Tool-specific outputs
├── ports/                       # Port scanning results
│   ├── open_ports.txt          # All open ports
│   └── nmap_common.txt         # Nmap scan results
├── parameters/                  # Parameter discovery
│   ├── all_params.txt          # All found parameters
│   └── url_params.txt          # URL-based parameters
├── secrets/                     # Secret discovery
│   ├── secretfinder.txt        # SecretFinder results
│   ├── linkfinder.txt          # LinkFinder endpoints
│   └── ...                     # JS analysis results
└── vulnerabilities/             # Vulnerability scan results
    ├── nuclei.txt              # Nuclei findings
    ├── dalfox_xss.txt          # XSS vulnerabilities
    ├── open_redirects.txt      # Open redirect findings
    └── ...                     # Other vulnerability results
```

## 📈 Examples

### Example 1: Basic Domain Reconnaissance

```bash
./auto_recon.sh example.com
```

**Expected Output:**
- 50+ subdomains discovered
- 200+ URLs found
- 10+ open ports identified
- 5+ potential vulnerabilities
- Complete HTML report generated

### Example 2: Large Organization Scan

```bash
./auto_recon.sh bigcorp.com
```

**Typical Results:**
- 500+ subdomains
- 5000+ URLs
- 100+ services
- 20+ security findings

### Example 3: Checking Tool Status

```bash
./scan.sh
```

**Output:**
```
Checking tools installation status...
================================================
[✔] amass is installed
[✔] subfinder is installed
[✔] assetfinder is installed
...
================================================
Installation Summary:
Installed: 48/50 tools
Success Rate: 96%
```

## 🔧 Configuration

### Timeout Settings
Default timeouts can be modified in `auto_recon.sh`:
- Amass: 600 seconds (10 minutes)
- Other tools: 300 seconds (5 minutes)

### Wordlists
The script looks for wordlists in common locations:
- `/home/sb3lr/tools/wordlists/`
- `/usr/share/wordlists/`
- Tool-specific wordlists

### Custom Payloads
Many tools support custom payloads and configurations:
- **dalfox**: Custom XSS payloads
- **ffuf**: Custom wordlists
- **nuclei**: Custom templates

## 🚨 Important Notes

### Legal and Ethical Usage
- **Only test domains you own or have explicit permission to test**
- Respect rate limits and don't overload target servers
- Follow responsible disclosure practices
- Comply with local laws and regulations

### Performance Considerations
- The full workflow can take 30-60 minutes depending on target size
- Adjust timeouts based on your needs and target responsiveness
- Consider running on a VPS for better performance and stability

### Rate Limiting
- Tools include built-in rate limiting where appropriate
- Some tools may trigger WAF/IPS systems - use responsibly
- Consider using proxies or VPNs for large scans

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Add New Tools**: Submit PRs with new security tools
2. **Improve Automation**: Enhance the workflow scripts
3. **Fix Bugs**: Report and fix issues
4. **Documentation**: Improve tool documentation
5. **Testing**: Test on different environments

### Adding a New Tool

1. Create a directory in `bugbounty-tools/`
2. Add installation instructions to `install_tools.sh`
3. Update the tool list in `scan.sh`
4. Integrate into `auto_recon.sh` workflow
5. Update this README

## 📄 License

This collection includes tools with various licenses:
- **MIT License**: Most Go-based tools
- **GPL License**: Some Python tools
- **Apache License**: Various tools
- **Custom Licenses**: Check individual tool directories

Please respect the individual licenses of each tool.

## 🙏 Acknowledgments

Special thanks to all the security researchers and developers who created these amazing tools:

- **ProjectDiscovery Team** - For nuclei, subfinder, httpx, and many others
- **Tom Hudson (@tomnomnom)** - For numerous Go security tools
- **s0md3v** - For XSStrike, Arjun, and other Python tools
- **OWASP Amass Team** - For the comprehensive Amass framework
- **All contributors** - To the individual tools and this collection

## 📞 Support

- **Issues**: Report bugs and feature requests via GitHub Issues
- **Documentation**: Check individual tool READMEs for specific usage
---

<div align="center">
  <p><strong>⚡ Happy Bug Hunting! ⚡</strong></p>
  <p><em>Remember: With great power comes great responsibility</em></p>
</div>
