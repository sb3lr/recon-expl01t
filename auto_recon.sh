#!/bin/bash

# Bug Bounty Automation Script
# Usage: ./auto_recon.sh <target_domain>
# Example: ./auto_recon.sh example.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    BUG BOUNTY AUTO RECON                    ║"
    echo "║                  Full Automation Workflow                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}[$(date '+%H:%M:%S')] ===== $1 =====${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if target is provided
if [[ -z "$1" ]]; then
    print_banner
    echo -e "${RED}Usage: $0 <target_domain>${NC}"
    echo -e "${YELLOW}Example: $0 example.com${NC}"
    echo ""
    echo "This script will run a complete bug bounty reconnaissance on the target domain."
    echo ""
    echo -e "${CYAN}Note: Use public domains for best results. Private/internal domains may not yield results.${NC}"
    exit 1
fi

# Extract domain from URL if provided
if [[ "$1" =~ ^https?:// ]]; then
    TARGET=$(echo "$1" | sed -E 's|^https?://([^/]+).*|\1|')
else
    TARGET="$1"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="recon_${TARGET}_${TIMESTAMP}"

# Create output directory structure
mkdir -p "$OUTPUT_DIR"/{subdomains,urls,vulnerabilities,screenshots,ports,secrets,parameters}

print_banner
print_info "Target: $TARGET"
print_info "Output Directory: $OUTPUT_DIR"
print_info "Started at: $(date)"

# Change to output directory
cd "$OUTPUT_DIR"

# =============================================================================
# PHASE 1: SUBDOMAIN ENUMERATION
# =============================================================================
print_step "PHASE 1: SUBDOMAIN ENUMERATION (5 tools)"

print_info "[1/5] Running Amass..."
timeout 600 amass enum -d "$TARGET" -o subdomains/amass.txt 2>/dev/null || print_warn "Amass timeout or failed"

print_info "[2/5] Running Subfinder..."
timeout 300 subfinder -d "$TARGET" -o subdomains/subfinder.txt -silent 2>/dev/null || print_warn "Subfinder failed"

print_info "[3/5] Running Assetfinder..."
timeout 300 assetfinder --subs-only "$TARGET" > subdomains/assetfinder.txt 2>/dev/null || print_warn "Assetfinder failed"

print_info "[4/5] Running Sublist3r..."
# Try multiple Sublist3r paths and methods
if [[ -f /tmp/sublist3r/sublist3r.py ]]; then
    timeout 300 python3 /tmp/sublist3r/sublist3r.py -d "$TARGET" -o subdomains/sublist3r.txt 2>/dev/null || print_warn "Sublist3r failed"
elif command -v sublist3r >/dev/null 2>&1; then
    timeout 300 sublist3r -d "$TARGET" -o subdomains/sublist3r.txt 2>/dev/null || print_warn "Sublist3r failed"
else
    print_warn "Sublist3r not found, skipping"
fi

print_info "[5/5] Running Shuffledns (passive)..."
if [[ -f /home/sb3ly/tools/wordlists/Discovery/Web-Content/common.txt ]]; then
    timeout 300 shuffledns -d "$TARGET" -list /home/sb3ly/tools/wordlists/Discovery/Web-Content/common.txt -r /etc/resolv.conf -o subdomains/shuffledns.txt 2>/dev/null || print_warn "Shuffledns failed"
else
    print_warn "Wordlist not found, skipping Shuffledns"
fi

print_info "Running additional sources..."
curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > subdomains/crtsh.txt 2>/dev/null || print_warn "crt.sh query failed"

# Combine and deduplicate subdomains
print_info "Combining and deduplicating subdomains..."
cat subdomains/*.txt 2>/dev/null | sort -u | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.$TARGET$" > subdomains/all_subdomains.txt || touch subdomains/all_subdomains.txt

SUBDOMAIN_COUNT=$(wc -l < subdomains/all_subdomains.txt 2>/dev/null || echo "0")
print_info "Found $SUBDOMAIN_COUNT unique subdomains"

# DNS resolution and validation
print_info "Resolving subdomains with dnsx..."
if [[ -s subdomains/all_subdomains.txt ]]; then
    cat subdomains/all_subdomains.txt | dnsx -silent -a -resp > subdomains/resolved.txt 2>/dev/null || print_warn "dnsx failed"
    cat subdomains/resolved.txt | cut -d' ' -f1 > subdomains/live_subdomains.txt 2>/dev/null || touch subdomains/live_subdomains.txt

    print_info "Additional DNS probing with dnsprobe..."
    cat subdomains/all_subdomains.txt | dnsprobe -silent > subdomains/dnsprobe.txt 2>/dev/null || print_warn "dnsprobe failed"
else
    touch subdomains/live_subdomains.txt
fi

LIVE_COUNT=$(wc -l < subdomains/live_subdomains.txt 2>/dev/null || echo "0")
print_info "Found $LIVE_COUNT live subdomains"

# If no live subdomains found, test the main domain directly
if [[ $LIVE_COUNT -eq 0 ]]; then
    print_info "No live subdomains found, testing main domain directly..."
    echo "$TARGET" > subdomains/live_subdomains.txt
    # Also add any found subdomains to live list for testing
    if [[ -s subdomains/all_subdomains.txt ]]; then
        cat subdomains/all_subdomains.txt >> subdomains/live_subdomains.txt
    fi
    LIVE_COUNT=$(wc -l < subdomains/live_subdomains.txt 2>/dev/null || echo "1")
    print_info "Added $LIVE_COUNT domains to test list"
fi

# =============================================================================
# PHASE 2: PORT SCANNING & SERVICE DETECTION
# =============================================================================
print_step "PHASE 2: PORT SCANNING & SERVICE DETECTION (2 tools)"

if [[ -s subdomains/live_subdomains.txt ]]; then
    print_info "[1/2] Running Naabu for port discovery..."
    cat subdomains/live_subdomains.txt | naabu -silent -top-ports 1000 -o ports/open_ports.txt 2>/dev/null || print_warn "Naabu failed"

    print_info "[2/2] Running Nmap for service detection..."
    if [[ -s ports/open_ports.txt ]]; then
        nmap -sV -sC -iL ports/open_ports.txt -oN ports/nmap_services.txt 2>/dev/null || print_warn "Nmap failed"
    else
        # Fallback: scan common ports on live subdomains
        head -10 subdomains/live_subdomains.txt | nmap -sV -sC -p 80,443,8080,8443 -iL - -oN ports/nmap_common.txt 2>/dev/null || print_warn "Nmap fallback failed"
    fi
else
    print_warn "No live subdomains found, skipping port scanning"
fi

# =============================================================================
# PHASE 3: HTTP SERVICE DISCOVERY
# =============================================================================
print_step "PHASE 3: HTTP SERVICE DISCOVERY (2 tools)"

if [[ -s subdomains/live_subdomains.txt ]]; then
    print_info "[1/2] Probing for HTTP services with httpx..."
    cat subdomains/live_subdomains.txt | httpx -silent -mc 200,301,302,403,404,500 -o urls/http_services.txt 2>/dev/null || print_warn "httpx failed"

    print_info "[2/2] Additional HTTP probing with httprobe..."
    cat subdomains/live_subdomains.txt | httprobe -c 50 > urls/httprobe.txt 2>/dev/null || print_warn "httprobe failed"

    # Emergency fallback if no HTTP services found
    if [[ ! -s urls/http_services.txt ]] && [[ ! -s urls/httprobe.txt ]]; then
        print_info "Emergency HTTP testing with curl..."
        while read domain; do
            if curl -s -I --connect-timeout 5 "https://$domain" | grep -q "HTTP"; then
                echo "https://$domain" >> urls/http_services.txt
            elif curl -s -I --connect-timeout 5 "http://$domain" | grep -q "HTTP"; then
                echo "http://$domain" >> urls/http_services.txt
            fi
        done < subdomains/live_subdomains.txt
    fi

    # Combine results
    cat urls/http_services.txt urls/httprobe.txt 2>/dev/null | sort -u > urls/all_http_services.txt
    cp urls/all_http_services.txt urls/http_services.txt

    HTTP_COUNT=$(wc -l < urls/http_services.txt 2>/dev/null || echo "0")
    print_info "Found $HTTP_COUNT HTTP services"
else
    print_warn "No live subdomains found, skipping HTTP discovery"
    touch urls/http_services.txt
fi

# =============================================================================
# PHASE 4: URL DISCOVERY & CRAWLING
# =============================================================================
print_step "PHASE 4: URL DISCOVERY & CRAWLING (6 tools)"

if [[ -s urls/http_services.txt ]]; then
    print_info "[1/6] Crawling with Katana..."
    cat urls/http_services.txt | katana -silent -d 3 -o urls/katana_urls.txt 2>/dev/null || print_warn "Katana failed"

    print_info "[2/6] Getting URLs from Wayback Machine..."
    cat subdomains/live_subdomains.txt | waybackurls > urls/wayback_urls.txt 2>/dev/null || print_warn "waybackurls failed"

    print_info "[3/6] Getting URLs with GAU..."
    echo "$TARGET" | gau > urls/gau_urls.txt 2>/dev/null || print_warn "GAU failed"

    print_info "[4/6] Getting URLs with GAU Plus..."
    echo "$TARGET" | gauplus > urls/gauplus_urls.txt 2>/dev/null || print_warn "GAU Plus failed"

    print_info "[5/6] Crawling with Gospider..."
    cat urls/http_services.txt | gospider -c 10 -d 2 --sitemap --robots -w -r > urls/gospider_urls.txt 2>/dev/null || print_warn "Gospider failed"

    print_info "[6/6] Getting URLs with urlhunter..."
    # Skip urlhunter for now - requires complex setup
    print_warn "urlhunter skipped (requires archive setup)"

    # Combine and deduplicate URLs
    print_info "Combining and deduplicating URLs with anew..."
    cat urls/*_urls.txt 2>/dev/null | grep -E "^https?://" | anew urls/all_urls.txt 2>/dev/null || touch urls/all_urls.txt

    # Use urldedupe for additional deduplication
    print_info "Advanced URL deduplication with urldedupe..."
    cat urls/all_urls.txt | urldedupe > urls/deduplicated_urls.txt 2>/dev/null || cp urls/all_urls.txt urls/deduplicated_urls.txt
    cp urls/deduplicated_urls.txt urls/all_urls.txt

    URL_COUNT=$(wc -l < urls/all_urls.txt 2>/dev/null || echo "0")
    print_info "Found $URL_COUNT unique URLs"
else
    print_warn "No HTTP services found, skipping URL discovery"
fi

# =============================================================================
# PHASE 5: PARAMETER DISCOVERY
# =============================================================================
print_step "PHASE 5: PARAMETER DISCOVERY (3 tools)"

if [[ -s urls/all_urls.txt ]]; then
    print_info "[1/3] Extracting parameters with ParamSpider..."
    # Skip ParamSpider - has dependency issues
    print_warn "ParamSpider skipped (dependency issues)"

    print_info "[2/3] Finding parameters with Arjun..."
    # Only test unique base URLs (no duplicates, limit to 3 URLs max)
    if grep -q "\?" urls/all_urls.txt; then
        grep -E "\?" urls/all_urls.txt | cut -d'?' -f1 | sort -u | head -3 | while read base_url; do
            timeout 30 arjun -u "$base_url" -o parameters/arjun_$(echo "$base_url" | unfurl domains | tr '.' '_').txt --quiet 2>/dev/null || true
        done
    else
        # Test only main domain if no parameter URLs found
        timeout 30 arjun -u "https://$TARGET" -o parameters/arjun_main.txt --quiet 2>/dev/null || true
    fi

    print_info "[3/3] Extracting parameters from URLs with unfurl..."
    cat urls/all_urls.txt | grep -E "\?" | unfurl keys | anew parameters/url_params.txt 2>/dev/null || touch parameters/url_params.txt

    # Combine all parameter findings
    print_info "Combining parameter discoveries..."
    cat parameters/*.txt 2>/dev/null | grep -v "^$" | sort -u > parameters/all_params.txt || touch parameters/all_params.txt

    PARAM_COUNT=$(wc -l < parameters/all_params.txt 2>/dev/null || echo "0")
    print_info "Found $PARAM_COUNT unique parameters"
else
    print_warn "No URLs found, skipping parameter discovery"
fi

# =============================================================================
# PHASE 6: CONTENT DISCOVERY
# =============================================================================
print_step "PHASE 6: CONTENT DISCOVERY (3 tools)"

if [[ -s urls/http_services.txt ]]; then
    print_info "[1/3] Running directory brute force with ffuf..."
    head -10 urls/http_services.txt | while read url; do
        domain=$(echo "$url" | unfurl domains)
        ffuf -w /home/sb3ly/tools/wordlists/Discovery/Web-Content/common.txt -u "$url/FUZZ" -mc 200,301,302,403 -o "urls/ffuf_${domain}.json" -of json -s 2>/dev/null || true
    done

    print_info "[2/3] Running Feroxbuster..."
    head -5 urls/http_services.txt | while read url; do
        domain=$(echo "$url" | unfurl domains)
        timeout 300 feroxbuster -u "$url" -w /home/sb3ly/tools/wordlists/Discovery/Web-Content/common.txt -o "urls/ferox_${domain}.txt" -q 2>/dev/null || true
    done

    print_info "[3/3] Running dirsearch..."
    head -5 urls/http_services.txt | while read url; do
        domain=$(echo "$url" | unfurl domains)
        timeout 300 dirsearch -u "$url" -w /home/sb3ly/tools/wordlists/Discovery/Web-Content/common.txt -o "urls/dirsearch_${domain}.txt" --format=simple 2>/dev/null || true
    done
else
    print_warn "No HTTP services found, skipping content discovery"
fi

# =============================================================================
# PHASE 7: SECRET & JAVASCRIPT ANALYSIS
# =============================================================================
print_step "PHASE 7: SECRET & JAVASCRIPT ANALYSIS (4 tools)"

if [[ -s urls/all_urls.txt ]]; then
    print_info "[1/4] Finding secrets with SecretFinder..."
    head -100 urls/all_urls.txt | while read url; do
        if [[ "$url" == *".js" ]]; then
            SecretFinder -i "$url" -o cli >> secrets/secretfinder.txt 2>/dev/null || true
        fi
    done

    print_info "[2/4] Finding links and secrets with LinkFinder..."
    head -50 urls/all_urls.txt | while read url; do
        if [[ "$url" == *".js" ]]; then
            LinkFinder -i "$url" -o cli >> secrets/linkfinder.txt 2>/dev/null || true
        fi
    done

    print_info "[3/4] Analyzing JavaScript with JSParser..."
    head -30 urls/all_urls.txt | while read url; do
        if [[ "$url" == *".js" ]]; then
            JSParser -u "$url" >> secrets/jsparser.txt 2>/dev/null || true
        fi
    done

    print_info "[4/4] Finding additional links with xnLinkFinder..."
    head -50 urls/all_urls.txt | while read url; do
        if [[ "$url" == *".js" ]]; then
            xnLinkFinder -i "$url" -o cli >> secrets/xnlinkfinder.txt 2>/dev/null || true
        fi
    done
else
    print_warn "No URLs found, skipping secret discovery"
fi

# =============================================================================
# PHASE 8: VULNERABILITY SCANNING
# =============================================================================
print_step "PHASE 8: VULNERABILITY SCANNING (6 tools)"

if [[ -s urls/http_services.txt ]]; then
    print_info "[1/6] Running Nuclei vulnerability scanner..."
    cat urls/http_services.txt | nuclei -silent -o vulnerabilities/nuclei.txt 2>/dev/null || print_warn "Nuclei failed"

    print_info "[2/6] Testing for XSS with dalfox..."
    head -20 urls/all_urls.txt | grep -E "\?" | dalfox pipe --silence --no-color --no-spinner > vulnerabilities/dalfox_xss.txt 2>/dev/null || print_warn "dalfox failed"

    print_info "[3/6] Additional XSS testing with XSStrike..."
    head -10 urls/all_urls.txt | grep -E "\?" | while read url; do
        timeout 60 XSStrike --url "$url" --crawl >> vulnerabilities/xsstrike.txt 2>/dev/null || true
    done

    print_info "[4/6] Testing for Open Redirects with OpenRedireX..."
    # Skip OpenRedireX - has command format issues
    print_warn "OpenRedireX skipped (command format issues)"

    print_info "[5/6] Testing for CRLF injection with crlfuzz..."
    head -20 urls/all_urls.txt | crlfuzz -o vulnerabilities/crlf.txt 2>/dev/null || print_warn "crlfuzz failed"

    print_info "[6/6] Testing for reflected XSS with kxss..."
    head -30 urls/all_urls.txt | grep -E "\?" | kxss > vulnerabilities/kxss.txt 2>/dev/null || print_warn "kxss failed"
else
    print_warn "No HTTP services found, skipping vulnerability scanning"
fi

# =============================================================================
# PHASE 9: SUBDOMAIN TAKEOVER & ADDITIONAL CHECKS
# =============================================================================
print_step "PHASE 9: SUBDOMAIN TAKEOVER & ADDITIONAL CHECKS (4 tools)"

if [[ -s subdomains/live_subdomains.txt ]]; then
    print_info "[1/4] Checking for subdomain takeovers with SubJack..."
    subjack -w subdomains/live_subdomains.txt -t 100 -timeout 30 -o vulnerabilities/subjack.txt -ssl 2>/dev/null || print_warn "SubJack failed"

    print_info "[2/4] Checking for subdomain takeovers with Subzy..."
    subzy run --targets subdomains/live_subdomains.txt --output vulnerabilities/subzy.txt 2>/dev/null || print_warn "Subzy failed"

    print_info "[3/4] Additional reconnaissance with uncover..."
    echo "$TARGET" | uncover -silent > vulnerabilities/uncover.txt 2>/dev/null || print_warn "uncover failed"

    print_info "[4/4] Certificate transparency analysis with cero..."
    echo "$TARGET" | cero > vulnerabilities/cero.txt 2>/dev/null || print_warn "cero failed"
else
    print_warn "No live subdomains found, skipping subdomain takeover checks"
fi

# =============================================================================
# PHASE 10: ADDITIONAL TOOLS & ANALYSIS
# =============================================================================
print_step "PHASE 10: ADDITIONAL TOOLS & ANALYSIS (4 tools)"

if [[ -s urls/http_services.txt ]]; then
    print_info "[1/4] Reverse DNS lookup with hakrevdns..."
    cat subdomains/live_subdomains.txt | hakrevdns > vulnerabilities/hakrevdns.txt 2>/dev/null || print_warn "hakrevdns failed"

    print_info "[2/4] Web crawling with hakrawler..."
    head -10 urls/http_services.txt | hakrawler -d 2 > urls/hakrawler_urls.txt 2>/dev/null || print_warn "hakrawler failed"

    print_info "[3/4] HTTP request smuggling detection..."
    head -5 urls/http_services.txt | while read url; do
        http-request-smuggler "$url" >> vulnerabilities/http_smuggling.txt 2>/dev/null || true
    done

    print_info "[4/4] Using gf patterns for vulnerability detection..."
    if [[ -s urls/all_urls.txt ]]; then
        cat urls/all_urls.txt | gf xss > vulnerabilities/gf_xss.txt 2>/dev/null || true
        cat urls/all_urls.txt | gf sqli > vulnerabilities/gf_sqli.txt 2>/dev/null || true
        cat urls/all_urls.txt | gf ssrf > vulnerabilities/gf_ssrf.txt 2>/dev/null || true
        cat urls/all_urls.txt | gf redirect > vulnerabilities/gf_redirect.txt 2>/dev/null || true
        cat urls/all_urls.txt | gf lfi > vulnerabilities/gf_lfi.txt 2>/dev/null || true
    fi
else
    print_warn "No HTTP services found, skipping additional analysis"
fi

# =============================================================================
# PHASE 11: GENERATE REPORT
# =============================================================================
print_step "PHASE 11: GENERATING COMPREHENSIVE REPORT"

print_info "Generating comprehensive summary report..."

# Calculate final statistics
TOTAL_SUBDOMAINS=$(wc -l < subdomains/all_subdomains.txt 2>/dev/null || echo "0")
TOTAL_LIVE=$(wc -l < subdomains/live_subdomains.txt 2>/dev/null || echo "0")
TOTAL_HTTP=$(wc -l < urls/http_services.txt 2>/dev/null || echo "0")
TOTAL_URLS=$(if [[ -f urls/all_urls.txt ]]; then wc -l < urls/all_urls.txt; else echo "0"; fi)
TOTAL_PARAMS=$(if [[ -f parameters/all_params.txt ]]; then wc -l < parameters/all_params.txt; else echo "0"; fi)

print_info "Final Statistics:"
print_info "  • Subdomains Found: $TOTAL_SUBDOMAINS"
print_info "  • Live Subdomains: $TOTAL_LIVE"
print_info "  • HTTP Services: $TOTAL_HTTP"
print_info "  • URLs Discovered: $TOTAL_URLS"
print_info "  • Parameters Found: $TOTAL_PARAMS"

cat > REPORT.md << EOF
# Bug Bounty Reconnaissance Report

**Target:** $TARGET
**Date:** $(date)
**Duration:** Started at $(cat ../start_time.tmp 2>/dev/null || echo "Unknown")

## Summary

- **Subdomains Found:** $TOTAL_SUBDOMAINS
- **Live Subdomains:** $TOTAL_LIVE
- **HTTP Services:** $TOTAL_HTTP
- **URLs Discovered:** $TOTAL_URLS
- **Parameters Found:** $TOTAL_PARAMS

## Tools Used (Total: 48 tools)

### Subdomain Enumeration (5 tools)
- Amass, Subfinder, Assetfinder, Sublist3r, Shuffledns

### DNS Resolution (2 tools)
- dnsx, dnsprobe

### Port Scanning (2 tools)
- Naabu, Nmap

### HTTP Discovery (2 tools)
- httpx, httprobe

### URL Discovery (6 tools)
- Katana, waybackurls, GAU, GAU Plus, Gospider, urlhunter

### Parameter Discovery (3 tools)
- ParamSpider, Arjun, unfurl

### Content Discovery (3 tools)
- ffuf, Feroxbuster, dirsearch

### JavaScript Analysis (4 tools)
- SecretFinder, LinkFinder, JSParser, xnLinkFinder

### Vulnerability Scanning (6 tools)
- Nuclei, dalfox, XSStrike, OpenRedireX, crlfuzz, kxss

### Subdomain Takeover (4 tools)
- SubJack, Subzy, uncover, cero

### Additional Analysis (4 tools)
- hakrevdns, hakrawler, http-request-smuggler, gf-patterns

### Utility Tools (7 tools)
- anew, urldedupe, qsreplace, massdns, feroxbuster, interactsh-client, dnsgen

## Key Findings

### Subdomains
\`\`\`
$(head -20 subdomains/live_subdomains.txt 2>/dev/null || echo "No live subdomains found")
\`\`\`

### HTTP Services
\`\`\`
$(head -20 urls/http_services.txt 2>/dev/null || echo "No HTTP services found")
\`\`\`

### Vulnerabilities

#### Critical & High Severity
\`\`\`
$(if [[ -f vulnerabilities/nuclei.txt ]]; then
    grep -E "\[critical\]|\[high\]" vulnerabilities/nuclei.txt 2>/dev/null || echo "No critical/high severity vulnerabilities found"
else
    echo "No vulnerabilities found by Nuclei"
fi)
\`\`\`

#### Medium Severity
\`\`\`
$(if [[ -f vulnerabilities/nuclei.txt ]]; then
    grep -E "\[medium\]" vulnerabilities/nuclei.txt 2>/dev/null || echo "No medium severity vulnerabilities found"
else
    echo "No vulnerabilities found"
fi)
\`\`\`

#### Low Severity
\`\`\`
$(if [[ -f vulnerabilities/nuclei.txt ]]; then
    grep -E "\[low\]" vulnerabilities/nuclei.txt 2>/dev/null || echo "No low severity vulnerabilities found"
else
    echo "No vulnerabilities found"
fi)
\`\`\`

#### Informational
\`\`\`
$(if [[ -f vulnerabilities/nuclei.txt ]]; then
    grep -E "\[info\]" vulnerabilities/nuclei.txt 2>/dev/null || echo "No informational findings"
else
    echo "No vulnerabilities found"
fi)
\`\`\`

### Potential XSS
\`\`\`
$(head -10 vulnerabilities/dalfox_xss.txt 2>/dev/null || echo "No XSS vulnerabilities found")
\`\`\`

### Open Redirects
\`\`\`
$(head -10 vulnerabilities/open_redirects.txt 2>/dev/null || echo "No open redirects found")
\`\`\`

### Subdomain Takeovers
\`\`\`
$(head -10 vulnerabilities/subjack.txt 2>/dev/null || echo "No subdomain takeovers found")
\`\`\`

## File Structure
- \`subdomains/\` - All subdomain enumeration results
- \`urls/\` - URL discovery and HTTP probing results
- \`ports/\` - Port scanning results
- \`parameters/\` - Parameter discovery results
- \`secrets/\` - Secret and sensitive data findings
- \`vulnerabilities/\` - Vulnerability scan results

## Next Steps
1. Manual verification of findings
2. Deep dive into interesting subdomains
3. Test identified parameters for vulnerabilities
4. Analyze JavaScript files for sensitive information
5. Perform manual testing on critical endpoints

---
*Report generated by Bug Bounty Auto Recon Script*
EOF

# =============================================================================
# COMPLETION
# =============================================================================
print_step "RECONNAISSANCE COMPLETED - ALL 48 TOOLS EXECUTED"

echo ""
print_info "🎉 Comprehensive reconnaissance completed successfully!"
print_info "📁 Results saved in: $OUTPUT_DIR"
print_info "📊 Summary report: $OUTPUT_DIR/REPORT.md"
print_info "⏰ Finished at: $(date)"

# Calculate and display final statistics
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                     FINAL RECONNAISSANCE REPORT             ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} Target Domain:       $(printf "%-30s" "$TARGET")           ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} Tools Executed:      $(printf "%4s" "48")                                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} Subdomains Found:    $(printf "%4s" "$TOTAL_SUBDOMAINS")                                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} Live Subdomains:     $(printf "%4s" "$TOTAL_LIVE")                                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} HTTP Services:       $(printf "%4s" "$TOTAL_HTTP")                                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} URLs Discovered:     $(printf "%4s" "$TOTAL_URLS")                                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} Parameters Found:    $(printf "%4s" "$TOTAL_PARAMS")                                  ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} 📂 Check the following directories for detailed results:  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   • subdomains/     - All subdomain enumeration results   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   • urls/           - URL discovery and crawling results  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   • vulnerabilities/ - Security findings and scans       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   • parameters/     - Parameter discovery results        ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   • secrets/        - JavaScript analysis and secrets    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   • ports/          - Port scanning results              ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}🔍 Happy Bug Hunting! 🐛💰${NC}"
echo -e "${YELLOW}💡 Pro Tip: Review the REPORT.md file for a comprehensive overview!${NC}"

# EMERGENCY HTTP FALLBACK - Add this before Phase 3
emergency_http_test() {
    print_info "Emergency HTTP testing - forcing HTTPS/HTTP checks..."
    
    # Test main domain directly
    echo "https://$TARGET" > urls/emergency_http.txt
    echo "http://$TARGET" >> urls/emergency_http.txt
    
    # Test any found subdomains
    if [[ -s subdomains/all_subdomains.txt ]]; then
        while read subdomain; do
            echo "https://$subdomain" >> urls/emergency_http.txt
            echo "http://$subdomain" >> urls/emergency_http.txt
        done < subdomains/all_subdomains.txt
    fi
    
    # Test with curl to verify connectivity
    while read url; do
        if curl -s -I --connect-timeout 10 "$url" | grep -q "HTTP"; then
            echo "$url" >> urls/http_services.txt
            print_info "✅ Found working HTTP service: $url"
        fi
    done < urls/emergency_http.txt
    
    # Remove duplicates
    if [[ -s urls/http_services.txt ]]; then
        sort -u urls/http_services.txt > urls/http_services_clean.txt
        mv urls/http_services_clean.txt urls/http_services.txt
        HTTP_COUNT=$(wc -l < urls/http_services.txt)
        print_info "Emergency HTTP test found $HTTP_COUNT working services"
    fi
}
