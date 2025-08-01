#!/bin/bash

tools=(
  "amass"
  "subfinder"
  "assetfinder"
  "sublist3r"
  "shuffledns"
  "massdns"
  "dnsgen"
  "httprobe"
  "httpx"
  "naabu"
  "nmap"
  "dnsx"
  "dnsprobe"
  "waybackurls"
  "gau"
  "gauplus"
  "urlhunter"
  "JSParser"
  "LinkFinder"
  "xnLinkFinder"
  "paramspider"
  "arjun"
  "kxss"
  "dalfox"
  "XSStrike"
  "gf"
  "OpenRedireX"
  "SecretFinder"
  "http-request-smuggler"
  "interactsh-client"
  "nuclei"
  "ffuf"
  "dirsearch"
  "feroxbuster"
  "katana"
  "qsreplace"
  "subzy"
  "unfurl"
  "subjack"
  "anew"
  "urldedupe"
  "hakrevdns"
  "hakrawler"
  "uncover"
  "gospider"
  "crlfuzz"
  "cero"
)

echo "Checking tools installation status..."
echo "================================================"

installed_count=0
total_count=${#tools[@]}

for tool in "${tools[@]}"
do
  # Check if command exists in PATH
  if command -v "$tool" >/dev/null 2>&1; then
    echo "[✔] $tool is installed"
    ((installed_count++))
  else
    echo "[✘] $tool is NOT installed or not in PATH"
  fi
done

# Check for gf-patterns separately
echo ""
echo "Checking additional components..."
if [[ -d "$HOME/.gf" ]] && [[ -n "$(ls -A $HOME/.gf 2>/dev/null)" ]]; then
  echo "[✔] gf-patterns is installed"
  ((installed_count++))
  ((total_count++))
else
  echo "[✘] gf-patterns is NOT installed"
  ((total_count++))
fi

# Check Go version
echo ""
echo "Checking Go version..."
if command -v go >/dev/null 2>&1; then
  go_version=$(go version)
  echo "[✔] Go is installed: $go_version"
else
  echo "[✘] Go is NOT installed"
fi

# Check Python version
echo ""
echo "Checking Python version..."
if command -v python3 >/dev/null 2>&1; then
  python_version=$(python3 --version)
  echo "[✔] Python3 is installed: $python_version"
else
  echo "[✘] Python3 is NOT installed"
fi

echo ""
echo "================================================"
echo "Installation Summary:"
echo "Installed: $installed_count/$total_count tools"
echo "Success Rate: $(( installed_count * 100 / total_count ))%"

if [[ $installed_count -eq $total_count ]]; then
  echo "🎉 All tools are successfully installed!"
else
  echo "⚠️  Some tools are missing. Run 'sudo ./install_tools.sh' to install missing tools."
fi
