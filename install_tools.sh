#!/bin/bash

# Bug Bounty Tools Installation Script
# Installs all tools to /usr/local/bin

set -e

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_status() {
    echo -e "${BLUE}[STATUS] $1${NC}"
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script needs to be run with sudo privileges to install to /usr/local/bin"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Check if tool is already installed
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Install Go if not present
install_go() {
    # Check if Go 1.23.9 is already installed
    if [[ -f "/usr/local/go/bin/go" ]]; then
        local current_version=$(/usr/local/go/bin/go version 2>/dev/null | grep -o 'go1\.[0-9]*\.[0-9]*')
        if [[ "$current_version" == "go1.23.9" ]]; then
            print_status "Go 1.23.9 is already installed"
            export PATH=/usr/local/go/bin:$PATH
            export GOPATH=/tmp/go-install
            export PATH=/usr/local/go/bin:$GOPATH/bin:$PATH
            return
        fi
    fi
    
    # Remove old Go installation if it exists
    if [[ -d "/usr/lib/go-1.19" ]] || [[ -d "/usr/local/go" ]]; then
        print_info "Removing old Go installation..."
        rm -rf /usr/lib/go-1.19 /usr/local/go
        # Remove old Go from PATH in profile
        sed -i '/\/usr\/lib\/go-1.19/d' /etc/profile
        sed -i '/\/usr\/local\/go/d' /etc/profile
    fi
    
    print_info "Installing Go 1.23.9..."
    wget -q https://go.dev/dl/go1.23.9.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.23.9.linux-amd64.tar.gz
    rm go1.23.9.linux-amd64.tar.gz
    
    # Ensure new Go is in PATH
    export PATH=/usr/local/go/bin:$PATH
    echo 'export PATH=/usr/local/go/bin:$PATH' >> /etc/profile
    
    # Verify Go version
    /usr/local/go/bin/go version
    
    export GOPATH=/tmp/go-install
    export PATH=/usr/local/go/bin:$GOPATH/bin:$PATH
}

# Install Python3 and pip if not present
install_python_deps() {
    if ! command -v python3 >/dev/null 2>&1; then
        print_info "Installing Python3..."
        apt-get update && apt-get install -y python3 python3-pip python3-venv python3-full
    fi
    if ! command -v pip3 >/dev/null 2>&1; then
        print_info "Installing pip3..."
        apt-get install -y python3-pip python3-venv python3-full
    fi
    # Install pipx for better Python package management
    if ! command -v pipx >/dev/null 2>&1; then
        print_info "Installing pipx..."
        apt-get install -y pipx || pip3 install --user pipx --break-system-packages
    fi
}

# Install system dependencies
install_system_deps() {
    print_info "Installing system dependencies..."
    apt-get update
    apt-get install -y wget curl git build-essential cmake libssl-dev pkg-config
}

# Install Go-based tools
install_go_tool() {
    local tool_name="$1"
    local go_package="$2"
    local fallback_version="$3"
    
    if is_installed "$tool_name"; then
        print_status "$tool_name is already installed"
        return
    fi
    
    print_info "Installing $tool_name..."
    
    # Try latest version first
    if GOPATH=/tmp/go-install PATH=/usr/local/go/bin:$PATH /usr/local/go/bin/go install "$go_package@latest" 2>/tmp/go_error.log; then
        cp "/tmp/go-install/bin/$tool_name" /usr/local/bin/
        chmod +x "/usr/local/bin/$tool_name"
        print_info "$tool_name installed successfully"
    elif [[ -n "$fallback_version" ]]; then
        # Try fallback version if latest fails
        print_warn "Latest version failed, trying fallback version $fallback_version"
        print_warn "Error: $(cat /tmp/go_error.log)"
        if GOPATH=/tmp/go-install PATH=/usr/local/go/bin:$PATH /usr/local/go/bin/go install "$go_package@$fallback_version" 2>/tmp/go_error.log; then
            cp "/tmp/go-install/bin/$tool_name" /usr/local/bin/
            chmod +x "/usr/local/bin/$tool_name"
            print_info "$tool_name installed successfully with fallback version"
        else
            print_error "Failed to install $tool_name with fallback version"
            print_error "Error: $(cat /tmp/go_error.log)"
        fi
    else
        print_error "Failed to install $tool_name"
        print_error "Error: $(cat /tmp/go_error.log)"
    fi
}

# Install Python-based tools
install_python_tool() {
    local tool_name="$1"
    local repo_url="$2"
    local install_cmd="$3"
    
    if is_installed "$tool_name"; then
        print_status "$tool_name is already installed"
        return
    fi
    
    print_info "Installing $tool_name..."
    cd /tmp
    rm -rf "$tool_name"
    git clone "$repo_url" "$tool_name"
    cd "$tool_name"
    
    # Create virtual environment for the tool
    python3 -m venv venv
    source venv/bin/activate
    
    if [[ -n "$install_cmd" ]]; then
        # Replace pip3 with pip in install commands and add --break-system-packages if needed
        local modified_cmd="${install_cmd//pip3/pip}"
        eval "$modified_cmd"
    else
        if [[ -f "requirements.txt" ]]; then
            pip install -r requirements.txt
        fi
        if [[ -f "setup.py" ]]; then
            pip install .
        fi
    fi
    
    # Create wrapper script that activates venv and runs the tool
    local main_script=""
    if [[ -f "${tool_name}.py" ]]; then
        main_script="${tool_name}.py"
    elif [[ -f "$tool_name" ]]; then
        cp "$tool_name" "/usr/local/bin/"
        chmod +x "/usr/local/bin/$tool_name"
        deactivate
        print_info "$tool_name installed successfully"
        return
    elif [[ -f "venv/bin/$tool_name" ]]; then
        cat > "/usr/local/bin/$tool_name" << EOF
#!/bin/bash
cd /tmp/$tool_name
source venv/bin/activate
$tool_name "\$@"
EOF
        chmod +x "/usr/local/bin/$tool_name"
        deactivate
        print_info "$tool_name installed successfully"
        return
    else
        # Find the main Python script
        main_script=$(find . -maxdepth 1 -name "*.py" -type f | head -1 | sed 's|^\./||')
    fi
    
    if [[ -n "$main_script" ]]; then
        cat > "/usr/local/bin/$tool_name" << EOF
#!/bin/bash
cd /tmp/$tool_name
source venv/bin/activate
python $main_script "\$@"
EOF
        chmod +x "/usr/local/bin/$tool_name"
    fi
    
    deactivate
    print_info "$tool_name installed successfully"
}

# Install compiled tools
install_compiled_tool() {
    local tool_name="$1"
    local repo_url="$2"
    local build_cmd="$3"
    
    if is_installed "$tool_name"; then
        print_status "$tool_name is already installed"
        return
    fi
    
    print_info "Installing $tool_name..."
    cd /tmp
    rm -rf "$tool_name"
    git clone "$repo_url" "$tool_name"
    cd "$tool_name"
    
    eval "$build_cmd"
    
    if [[ -f "$tool_name" ]]; then
        cp "$tool_name" "/usr/local/bin/"
        chmod +x "/usr/local/bin/$tool_name"
        print_info "$tool_name installed successfully"
    else
        print_error "Failed to build $tool_name"
    fi
}

# Install Rust-based tools
install_rust_tool() {
    local tool_name="$1"
    local repo_url="$2"
    
    if is_installed "$tool_name"; then
        print_status "$tool_name is already installed"
        return
    fi
    
    # Install Rust if not present
    if ! command -v cargo >/dev/null 2>&1; then
        print_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    fi
    
    print_info "Installing $tool_name..."
    cargo install --git "$repo_url" --root /usr/local
    print_info "$tool_name installed successfully"
}

# Main installation function
main() {
    print_info "Starting Bug Bounty Tools Installation..."
    
    check_permissions
    install_system_deps
    install_go
    install_python_deps
    
    # Go-based tools
    install_go_tool "amass" "github.com/owasp-amass/amass/v4/..."
    install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder" "v2.6.6"
    install_go_tool "assetfinder" "github.com/tomnomnom/assetfinder"
    install_go_tool "shuffledns" "github.com/projectdiscovery/shuffledns/cmd/shuffledns"
    # Install dnsgen using pipx (alternative approach)
    if ! is_installed "dnsgen"; then
        print_info "Installing dnsgen via pipx..."
        if command -v pipx >/dev/null 2>&1; then
            pipx install dnsgen || print_warn "Failed to install dnsgen via pipx, skipping..."
        else
            print_warn "pipx not available, skipping dnsgen installation"
        fi
    fi
    install_go_tool "httprobe" "github.com/tomnomnom/httprobe"
    install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx" "v1.3.7"
    install_go_tool "naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu" "v2.1.9"
    install_go_tool "dnsx" "github.com/projectdiscovery/dnsx/cmd/dnsx" "v1.1.6"
    install_go_tool "dnsprobe" "github.com/projectdiscovery/dnsprobe"
    install_go_tool "waybackurls" "github.com/tomnomnom/waybackurls"
    install_go_tool "gau" "github.com/lc/gau/v2/cmd/gau"
    install_go_tool "gauplus" "github.com/bp0lr/gauplus"
    install_go_tool "urlhunter" "github.com/utkusen/urlhunter"
    install_go_tool "kxss" "github.com/Emoe/kxss"
    install_go_tool "gf" "github.com/tomnomnom/gf"
    install_go_tool "interactsh-client" "github.com/projectdiscovery/interactsh/cmd/interactsh-client" "v1.1.8"
    install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v3/cmd/nuclei" "v3.1.0"
    install_go_tool "ffuf" "github.com/ffuf/ffuf/v2"
    install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana" "v1.0.5"
    install_go_tool "qsreplace" "github.com/tomnomnom/qsreplace"
    install_go_tool "subzy" "github.com/PentestPad/subzy"
    install_go_tool "unfurl" "github.com/tomnomnom/unfurl"
    install_go_tool "subjack" "github.com/haccer/subjack"
    install_go_tool "anew" "github.com/tomnomnom/anew"
    install_go_tool "hakrevdns" "github.com/hakluke/hakrevdns"
    install_go_tool "hakrawler" "github.com/hakluke/hakrawler"
    install_go_tool "uncover" "github.com/projectdiscovery/uncover/cmd/uncover" "v1.0.7"
    install_go_tool "gospider" "github.com/jaeles-project/gospider"
    install_go_tool "crlfuzz" "github.com/dwisiswant0/crlfuzz/cmd/crlfuzz"
    install_go_tool "cero" "github.com/glebarez/cero"
    
    # Additional tools from your list
    install_go_tool "gauplus" "github.com/bp0lr/gauplus"
    
    # Compiled tools
    install_compiled_tool "massdns" "https://github.com/blechschmidt/massdns" "make"
    install_compiled_tool "urldedupe" "https://github.com/ameenmaali/urldedupe" "cmake . && make"
    
    # Rust-based tools
    install_rust_tool "feroxbuster" "https://github.com/epi052/feroxbuster"
    
    # Python-based tools
    install_python_tool "sublist3r" "https://github.com/aboul3la/Sublist3r" "pip3 install -r requirements.txt"
    install_python_tool "JSParser" "https://github.com/nahamsec/JSParser" "pip3 install -r requirements.txt"
    install_python_tool "xnLinkFinder" "https://github.com/xnl-h4ck3r/xnLinkFinder" "python3 setup.py install"
    install_python_tool "paramspider" "https://github.com/devanshbatham/ParamSpider" "pip3 install ."
    install_python_tool "arjun" "https://github.com/s0md3v/Arjun" "pip3 install arjun"
    install_python_tool "dalfox" "https://github.com/hahwul/dalfox" ""
    install_python_tool "XSStrike" "https://github.com/s0md3v/XSStrike" "pip3 install -r requirements.txt"
    install_python_tool "OpenRedireX" "https://github.com/devanshbatham/OpenRedireX" "pip install aiohttp tqdm"
    install_python_tool "dirsearch" "https://github.com/maurosoria/dirsearch" "pip3 install -r requirements.txt"
    install_python_tool "LinkFinder" "https://github.com/GerbenJavado/LinkFinder" "pip3 install -r requirements.txt"
    install_python_tool "SecretFinder" "https://github.com/m4ll0k/SecretFinder" "pip3 install -r requirements.txt"
    
    # Special installations
    if ! is_installed "gf-patterns"; then
        print_info "Installing gf-patterns..."
        cd /tmp
        rm -rf Gf-Patterns
        git clone https://github.com/1ndianl33t/Gf-Patterns
        mkdir -p ~/.gf
        cp Gf-Patterns/*.json ~/.gf/
        print_info "gf-patterns installed successfully"
    fi
    
    if ! is_installed "nmap"; then
        print_info "Installing nmap..."
        apt-get install -y nmap
    fi
    
    if ! is_installed "http-request-smuggler"; then
        print_info "Installing http-request-smuggler..."
        cd /tmp
        rm -rf http-request-smuggler
        git clone https://github.com/portswigger/http-request-smuggler
        cd http-request-smuggler
        
        # Find the main Python script
        main_script=""
        if [[ -f "http-request-smuggler.py" ]]; then
            main_script="http-request-smuggler.py"
        elif [[ -f "smuggler.py" ]]; then
            main_script="smuggler.py"
        else
            main_script=$(find . -name "*.py" -type f | head -1 | sed 's|^\./||')
        fi
        
        if [[ -n "$main_script" ]]; then
            cat > "/usr/local/bin/http-request-smuggler" << EOF
#!/bin/bash
cd /tmp/http-request-smuggler
python3 $main_script "\$@"
EOF
            chmod +x /usr/local/bin/http-request-smuggler
            print_info "http-request-smuggler installed successfully"
        else
            print_error "Could not find main script for http-request-smuggler"
        fi
    fi
    
    print_info "Installation completed!"
    print_info "All tools have been installed to /usr/local/bin"
    print_info "You may need to restart your shell or run 'source ~/.bashrc' to use the tools"
    
    # Run scan to verify installations
    print_info "Running verification scan..."
    if [[ -f "./scan.sh" ]]; then
        ./scan.sh
    elif [[ -f "$PWD/scan.sh" ]]; then
        "$PWD/scan.sh"
    else
        print_warn "scan.sh not found in current directory, skipping verification scan"
        print_info "You can manually run './scan.sh' to verify installations"
    fi
}

main "$@"