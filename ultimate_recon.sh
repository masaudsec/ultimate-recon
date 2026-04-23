#!/bin/bash
# ============================================================
#   ULTIMATE BUG BOUNTY RECON SCRIPT
#   By: Deep Recon Automation v3.0
#   Platform: Kali Linux
#   Usage: sudo bash ultimate_recon.sh -d target.com [OPTIONS]
# ============================================================

# ─── COLORS ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ─── BANNER ──────────────────────────────────────────────────
banner() {
echo -e "${CYAN}"
cat << 'EOF'
███╗   ███╗ █████╗ ███████╗ █████╗ ██╗   ██╗██████╗ ███████╗███████╗ ██████╗
████╗ ████║██╔══██╗██╔════╝██╔══██╗██║   ██║██╔══██╗██╔════╝██╔════╝██╔════╝
██╔████╔██║███████║███████╗███████║██║   ██║██║  ██║███████╗█████╗  ██║     
██║╚██╔╝██║██╔══██║╚════██║██╔══██║██║   ██║██║  ██║╚════██║██╔══╝  ██║     
██║ ╚═╝ ██║██║  ██║███████║██║  ██║╚██████╔╝██████╔╝███████║███████╗╚██████╗
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝ ╚═════╝
EOF
echo -e "${NC}"
echo -e "${MAGENTA}${BOLD}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬${NC}"
echo -e "  ${CYAN}${BOLD}masaudsec_recon${NC} ${WHITE}—${NC} ${YELLOW}Deep Recon Automation Tool${NC}"
echo -e "  ${WHITE}🌐 Website  :${NC} ${CYAN}masaudsec.com${NC}"
echo -e "  ${WHITE}🎓 Mission  :${NC} ${GREEN}Master OffSec with MasaudSec${NC}"
echo -e "  ${WHITE}⚡ Version  :${NC} ${YELLOW}v3.0${NC}  ${WHITE}|${NC}  ${WHITE}🐧 Platform :${NC} ${GREEN}Kali Linux${NC}"
echo -e "  ${WHITE}🔍 Mode     :${NC} ${MAGENTA}Deep Level  |  Universal  |  Smart${NC}"
echo -e "${MAGENTA}${BOLD}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬${NC}"
echo -e ""
echo -e "  ${RED}${BOLD}⚠  LEGAL :${NC}  ${WHITE}Only use on authorized Bug Bounty targets within scope.${NC}"
echo -e "  ${YELLOW}💡 TIP    :${NC}  ${WHITE}Enumeration is the key — the more you find, the more you hack.${NC}"
echo -e ""
}

# ─── LOGGING ─────────────────────────────────────────────────
LOG_FILE=""
log() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[-]${NC} $1" | tee -a "$LOG_FILE"; }
info() { echo -e "${BLUE}[*]${NC} $1" | tee -a "$LOG_FILE"; }
section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}${BOLD}║  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
}

# ─── USAGE ───────────────────────────────────────────────────
usage() {
cat << EOF
${BOLD}USAGE:${NC}
    sudo bash ultimate_recon.sh -d target.com [OPTIONS]

${BOLD}OPTIONS:${NC}
    -d  <domain>     Target domain (required)
    -o  <output>     Output directory (default: ./recon_<domain>)
    -t  <threads>    Threads count (default: 50)
    -w  <wordlist>   Custom wordlist path
    --deep           Enable deep scanning (slower but thorough)
    --passive        Passive recon only (no active scanning)
    --install        Only install missing tools then exit
    --fresh          Ignore any previous checkpoint and start from scratch
    -h               Show this help

${BOLD}RESUME / CHECKPOINT:${NC}
    The script auto-saves progress after each phase into ./recon_<domain>/.checkpoint
    If you re-run the same command after an interruption, it will automatically
    resume from the last completed phase and reuse the same output directory.
    Use --fresh to force a clean restart.

${BOLD}EXAMPLES:${NC}
    sudo bash recon.sh -d example.com
    sudo bash recon.sh -d example.com --deep -t 100
    sudo bash recon.sh -d example.com --passive
    sudo bash recon.sh -d example.com --fresh   # force new scan
    sudo bash recon.sh --install

EOF
exit 0
}

# ─── DEFAULT CONFIG ───────────────────────────────────────────
TARGET=""
OUTPUT_DIR=""
THREADS=50
DEEP_SCAN=false
PASSIVE_ONLY=false
INSTALL_ONLY=false
CUSTOM_WORDLIST=""
WORDLIST="/usr/share/wordlists/dirb/common.txt"
DNS_WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"

# ─── CHECKPOINT / RESUME ─────────────────────────────────────
CHECKPOINT_FILE=""   # set after setup_dirs
RESUMING=false       # true when we detected a previous run

# Save completed phase name to checkpoint file
save_checkpoint() {
    echo "$1" >> "$CHECKPOINT_FILE"
    log "[CHECKPOINT] Phase '$1' marked as complete"
}

# Return 0 (true) if a phase was already completed in a previous run
phase_done() {
    [[ -f "$CHECKPOINT_FILE" ]] && grep -qxF "$1" "$CHECKPOINT_FILE"
}

# ─── ARG PARSING ─────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d) TARGET="$2"; shift 2 ;;
            -o) OUTPUT_DIR="$2"; shift 2 ;;
            -t) THREADS="$2"; shift 2 ;;
            -w) CUSTOM_WORDLIST="$2"; WORDLIST="$2"; shift 2 ;;
            --deep) DEEP_SCAN=true; shift ;;
            --passive) PASSIVE_ONLY=true; shift ;;
            --install) INSTALL_ONLY=true; shift ;;
            --fresh) FRESH_START=true; shift ;;   # force fresh start, ignore checkpoint
            -h|--help) usage ;;
            *) err "Unknown option: $1"; usage ;;
        esac
    done
    [[ "$INSTALL_ONLY" == false && -z "$TARGET" ]] && { err "Target domain required! Use -d flag."; usage; }
}
FRESH_START=false

# ─── TOOL INSTALLER ──────────────────────────────────────────
check_and_install() {
    section "🔧 TOOL CHECK & INSTALLATION"

    # Update apt quietly
    info "Updating package lists..."
    apt-get update -qq 2>/dev/null

    # ── System packages ──────────────────────────────────────
    local APT_TOOLS=(
        "nmap" "curl" "wget" "git" "python3" "python3-pip"
        "dnsutils" "whois" "jq" "unzip" "masscan"
        "nikto" "wafw00f" "whatweb" "dirb" "gobuster"
        "chromium" "chromium-driver" "seclists"
    )

    info "Checking system packages..."
    for tool in "${APT_TOOLS[@]}"; do
        if ! dpkg -s "$tool" &>/dev/null; then
            warn "Installing: $tool"
            apt-get install -y -qq "$tool" 2>/dev/null && log "Installed: $tool" || err "Failed: $tool"
        else
            log "Already installed: $tool"
        fi
    done

    # ── Go tools ─────────────────────────────────────────────
    if ! command -v go &>/dev/null; then
        warn "Installing Go..."
        local GO_VER="1.22.3"
        wget -q "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
        rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> /root/.bashrc
        log "Go installed"
    fi
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

    # ── Go-based security tools ───────────────────────────────
    declare -A GO_TOOLS=(
        ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
        ["nuclei"]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        ["dnsx"]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        ["katana"]="github.com/projectdiscovery/katana/cmd/katana@latest"
        ["naabu"]="github.com/projectdiscovery/naabu/cmd/naabu@latest"
        ["ffuf"]="github.com/ffuf/ffuf/v2@latest"
        ["gau"]="github.com/lc/gau/v2/cmd/gau@latest"
        ["assetfinder"]="github.com/tomnomnom/assetfinder@latest"
        ["waybackurls"]="github.com/tomnomnom/waybackurls@latest"
        ["anew"]="github.com/tomnomnom/anew@latest"
        ["uro"]="github.com/s0md3v/uro@latest"
        ["qsreplace"]="github.com/tomnomnom/qsreplace@latest"
        ["notify"]="github.com/projectdiscovery/notify/cmd/notify@latest"
        ["alterx"]="github.com/projectdiscovery/alterx/cmd/alterx@latest"
        ["tlsx"]="github.com/projectdiscovery/tlsx/cmd/tlsx@latest"
        ["hakrawler"]="github.com/hakluke/hakrawler@latest"
        ["puredns"]="github.com/d3mondev/puredns/v2@latest"
    )

    # ── Findomain (binary install) ────────────────────────────
    if ! command -v findomain &>/dev/null; then
        warn "Installing Findomain..."
        local FD_URL="https://github.com/Findomain/Findomain/releases/latest/download/findomain-linux-i386.zip"
        wget -q "$FD_URL" -O /tmp/findomain.zip 2>/dev/null && \
            unzip -q /tmp/findomain.zip -d /tmp/ && \
            mv /tmp/findomain /usr/local/bin/findomain && \
            chmod +x /usr/local/bin/findomain && \
            log "Findomain installed" || err "Findomain install failed"
    else
        log "Already installed: findomain"
    fi

    # ── massdns (for puredns) ─────────────────────────────────
    if ! command -v massdns &>/dev/null; then
        warn "Installing massdns..."
        git clone -q https://github.com/blechschmidt/massdns.git /tmp/massdns 2>/dev/null && \
            make -C /tmp/massdns -s 2>/dev/null && \
            cp /tmp/massdns/bin/massdns /usr/local/bin/ && \
            log "massdns installed" || err "massdns install failed"
    else
        log "Already installed: massdns"
    fi

    info "Checking Go tools..."
    for tool in "${!GO_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            warn "Installing Go tool: $tool"
            GOPATH=$HOME/go go install "${GO_TOOLS[$tool]}" 2>/dev/null && log "Installed: $tool" || err "Failed: $tool"
        else
            log "Already installed: $tool"
        fi
    done

    # ── Python tools ─────────────────────────────────────────
    declare -A PY_TOOLS=(
        ["arjun"]="arjun"
        ["dirsearch"]="dirsearch"
        ["truffleHog"]="trufflehog"
        ["dnsrecon"]="dnsrecon"
    )

    info "Checking Python tools..."
    for tool in "${!PY_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            warn "Installing Python tool: $tool"
            pip3 install "${PY_TOOLS[$tool]}" -q 2>/dev/null && log "Installed: $tool" || err "Failed: $tool"
        else
            log "Already installed: $tool"
        fi
    done

    # ── Git-cloned tools ─────────────────────────────────────
    # LinkFinder
    if [[ ! -f /opt/LinkFinder/linkfinder.py ]]; then
        warn "Installing LinkFinder..."
        git clone -q https://github.com/GerbenJavado/LinkFinder.git /opt/LinkFinder 2>/dev/null
        pip3 install -r /opt/LinkFinder/requirements.txt -q 2>/dev/null
        log "LinkFinder installed"
    fi

    # SecretFinder
    if [[ ! -f /opt/SecretFinder/SecretFinder.py ]]; then
        warn "Installing SecretFinder..."
        git clone -q https://github.com/m4ll0k/SecretFinder.git /opt/SecretFinder 2>/dev/null
        pip3 install -r /opt/SecretFinder/requirements.txt -q 2>/dev/null
        log "SecretFinder installed"
    fi

    # ParamSpider
    if [[ ! -f /opt/ParamSpider/paramspider.py ]]; then
        warn "Installing ParamSpider..."
        git clone -q https://github.com/devanshbatham/ParamSpider.git /opt/ParamSpider 2>/dev/null
        pip3 install -r /opt/ParamSpider/requirements.txt -q 2>/dev/null
        log "ParamSpider installed"
    fi

    # Nuclei templates update
    if command -v nuclei &>/dev/null; then
        info "Updating Nuclei templates..."
        nuclei -update-templates -silent 2>/dev/null && log "Nuclei templates updated"
    fi

    # SecLists check
    if [[ ! -d /usr/share/seclists ]]; then
        warn "Installing SecLists..."
        apt-get install -y -qq seclists 2>/dev/null || {
            git clone -q --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists
        }
        log "SecLists installed"
    fi

    log "\n✅ All tools check complete!\n"
}

# ─── FOLDER SETUP ────────────────────────────────────────────
setup_dirs() {
    # Use a STABLE directory name (no timestamp) so we can resume across runs.
    # If the user explicitly passes -o, respect that.
    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="./recon_${TARGET}"
    fi

    CHECKPOINT_FILE="$OUTPUT_DIR/.checkpoint"

    # ── Detect previous run ───────────────────────────────────
    if [[ -f "$CHECKPOINT_FILE" && "$FRESH_START" == false ]]; then
        RESUMING=true
        local last_phase
        last_phase=$(tail -1 "$CHECKPOINT_FILE" 2>/dev/null || echo "none")
        echo ""
        echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}${BOLD}║  ⚡ PREVIOUS RUN DETECTED — RESUMING               ║${NC}"
        echo -e "${YELLOW}${BOLD}║  Directory : $OUTPUT_DIR${NC}"
        echo -e "${YELLOW}${BOLD}║  Last done : $last_phase${NC}"
        echo -e "${YELLOW}${BOLD}║  (Use --fresh to start from scratch)               ║${NC}"
        echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
        echo ""
    elif [[ "$FRESH_START" == true && -f "$CHECKPOINT_FILE" ]]; then
        echo -e "${CYAN}[*] --fresh flag: removing old checkpoint and starting over...${NC}"
        rm -f "$CHECKPOINT_FILE"
    fi

    mkdir -p "$OUTPUT_DIR"/{subdomains,ports,tech,endpoints,params,screenshots,vulnerabilities,js_analysis,cloud,dns,waf,secrets,reports}
    LOG_FILE="$OUTPUT_DIR/recon.log"
    touch "$LOG_FILE"
    log "Output directory: $OUTPUT_DIR"
}

# ─── PUBLIC DNS RESOLVERS FILE ───────────────────────────────
# Fast public resolvers - way faster than default system DNS
create_resolvers_file() {
    local RESOLVERS_FILE="$OUTPUT_DIR/resolvers.txt"
    cat > "$RESOLVERS_FILE" << 'RESOLVERS_EOF'
1.1.1.1
1.0.0.1
8.8.8.8
8.8.4.4
9.9.9.9
149.112.112.112
208.67.222.222
208.67.220.220
94.140.14.14
94.140.15.15
185.228.168.9
185.228.169.9
76.76.19.19
76.223.122.150
8.26.56.26
8.20.247.20
64.6.64.6
64.6.65.6
156.154.70.1
156.154.71.1
198.101.242.72
23.253.163.53
77.88.8.8
77.88.8.1
74.82.42.42
109.69.8.51
RESOLVERS_EOF
    echo "$RESOLVERS_FILE"
}

# ─── PHASE 1: PASSIVE SUBDOMAIN ENUMERATION ──────────────────
phase1_subdomains() {
    section "🌐 PHASE 1: SUBDOMAIN ENUMERATION"
    local SUB_DIR="$OUTPUT_DIR/subdomains"

    # Create fast public resolvers file
    local RESOLVERS
    RESOLVERS=$(create_resolvers_file)
    info "Using $(wc -l < "$RESOLVERS") fast public DNS resolvers"

    # ── TOOL 1: Subfinder (multi-source passive) ──────────────
    info "Running Subfinder (all sources)..."
    subfinder -d "$TARGET" -silent -all \
        -o "$SUB_DIR/subfinder.txt" 2>/dev/null
    log "Subfinder: $(wc -l < "$SUB_DIR/subfinder.txt" 2>/dev/null || echo 0) subdomains"

    # ── TOOL 2: Assetfinder ───────────────────────────────────
    info "Running Assetfinder..."
    assetfinder --subs-only "$TARGET" 2>/dev/null | \
        grep "\.$TARGET$" | sort -u > "$SUB_DIR/assetfinder.txt"
    log "Assetfinder: $(wc -l < "$SUB_DIR/assetfinder.txt") subdomains"

    # ── TOOL 3: Findomain ─────────────────────────────────────
    if command -v findomain &>/dev/null; then
        info "Running Findomain..."
        findomain -t "$TARGET" -u "$SUB_DIR/findomain.txt" -q 2>/dev/null
        log "Findomain: $(wc -l < "$SUB_DIR/findomain.txt" 2>/dev/null || echo 0) subdomains"
    else
        warn "Findomain not found, skipping"
        touch "$SUB_DIR/findomain.txt"
    fi

    # ── TOOL 4: crt.sh (Certificate Transparency) ────────────
    info "Querying crt.sh..."
    curl -s --max-time 30 "https://crt.sh/?q=%25.$TARGET&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | \
        sed 's/\*\.//g' | tr ',' '\n' | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/crtsh.txt"
    log "crt.sh: $(wc -l < "$SUB_DIR/crtsh.txt") subdomains"

    # ── TOOL 5: HackerTarget ──────────────────────────────────
    info "Querying HackerTarget API..."
    curl -s --max-time 20 "https://api.hackertarget.com/hostsearch/?q=$TARGET" 2>/dev/null | \
        grep -v "^API" | cut -d',' -f1 | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/hackertarget.txt"
    log "HackerTarget: $(wc -l < "$SUB_DIR/hackertarget.txt") subdomains"

    # ── TOOL 6: AlienVault OTX ────────────────────────────────
    info "Querying AlienVault OTX..."
    curl -s --max-time 30 "https://otx.alienvault.com/api/v1/indicators/domain/$TARGET/passive_dns" 2>/dev/null | \
        jq -r '.passive_dns[].hostname' 2>/dev/null | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/alienvault.txt"
    log "AlienVault: $(wc -l < "$SUB_DIR/alienvault.txt") subdomains"

    # ── TOOL 7: URLScan.io ────────────────────────────────────
    info "Querying URLScan.io..."
    curl -s --max-time 30 "https://urlscan.io/api/v1/search/?q=domain:$TARGET&size=200" 2>/dev/null | \
        jq -r '.results[].page.domain' 2>/dev/null | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/urlscan.txt"
    log "URLScan: $(wc -l < "$SUB_DIR/urlscan.txt") subdomains"

    # ── TOOL 8: Wayback Machine ───────────────────────────────
    info "Querying Wayback Machine..."
    curl -s --max-time 30 \
        "http://web.archive.org/cdx/search/cdx?url=*.$TARGET&output=text&fl=original&collapse=urlkey&limit=50000" \
        2>/dev/null | grep -oE "[a-zA-Z0-9._-]+\.$TARGET" | sort -u > "$SUB_DIR/wayback_subs.txt"
    log "Wayback: $(wc -l < "$SUB_DIR/wayback_subs.txt") subdomains"

    # ── TOOL 9: ThreatCrowd ───────────────────────────────────
    info "Querying ThreatCrowd..."
    curl -s --max-time 20 \
        "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$TARGET" 2>/dev/null | \
        jq -r '.subdomains[]' 2>/dev/null | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/threatcrowd.txt"
    log "ThreatCrowd: $(wc -l < "$SUB_DIR/threatcrowd.txt") subdomains"

    # ── TOOL 10: RapidDNS ────────────────────────────────────
    info "Querying RapidDNS..."
    curl -s --max-time 20 "https://rapiddns.io/subdomain/$TARGET?full=1" 2>/dev/null | \
        grep -oE "[a-zA-Z0-9._-]+\.$TARGET" | sort -u > "$SUB_DIR/rapiddns.txt"
    log "RapidDNS: $(wc -l < "$SUB_DIR/rapiddns.txt") subdomains"

    # ── TOOL 11: BufferOver ───────────────────────────────────
    info "Querying BufferOver..."
    curl -s --max-time 20 "https://dns.bufferover.run/dns?q=.$TARGET" 2>/dev/null | \
        jq -r '.FDNS_A[],.RDNS[]' 2>/dev/null | cut -d',' -f2 | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/bufferover.txt"
    log "BufferOver: $(wc -l < "$SUB_DIR/bufferover.txt") subdomains"

    # ── TOOL 12: CommonCrawl ──────────────────────────────────
    info "Querying CommonCrawl..."
    curl -s --max-time 30 \
        "http://index.commoncrawl.org/CC-MAIN-2024-10-index?url=*.$TARGET&output=json&limit=5000" \
        2>/dev/null | jq -r '.url' 2>/dev/null | \
        grep -oE "[a-zA-Z0-9._-]+\.$TARGET" | sort -u > "$SUB_DIR/commoncrawl.txt"
    log "CommonCrawl: $(wc -l < "$SUB_DIR/commoncrawl.txt") subdomains"

    # ══════════════════════════════════════════════════════════
    # MERGE ALL SOURCES → single deduplicated list
    # ══════════════════════════════════════════════════════════
    info "Merging all subdomain sources..."
    cat "$SUB_DIR"/subfinder.txt \
        "$SUB_DIR"/assetfinder.txt \
        "$SUB_DIR"/findomain.txt \
        "$SUB_DIR"/crtsh.txt \
        "$SUB_DIR"/hackertarget.txt \
        "$SUB_DIR"/alienvault.txt \
        "$SUB_DIR"/urlscan.txt \
        "$SUB_DIR"/wayback_subs.txt \
        "$SUB_DIR"/threatcrowd.txt \
        "$SUB_DIR"/rapiddns.txt \
        "$SUB_DIR"/bufferover.txt \
        "$SUB_DIR"/commoncrawl.txt \
        2>/dev/null | \
        # Remove wildcards, whitespace, non-matching
        sed 's/\*\.//g' | tr -d '\r' | tr '[:upper:]' '[:lower:]' | \
        grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
        sort -u > "$SUB_DIR/all_subdomains_raw.txt"

    log "Total unique raw subdomains: $(wc -l < "$SUB_DIR/all_subdomains_raw.txt")"

    # ── AlterX permutation attack ─────────────────────────────
    if command -v alterx &>/dev/null; then
        info "Running AlterX smart permutation..."
        head -300 "$SUB_DIR/all_subdomains_raw.txt" | \
            alterx -silent -enrich 2>/dev/null | \
            grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" | \
            sort -u > "$SUB_DIR/alterx_perms.txt"
        cat "$SUB_DIR/alterx_perms.txt" >> "$SUB_DIR/all_subdomains_raw.txt"
        sort -u "$SUB_DIR/all_subdomains_raw.txt" -o "$SUB_DIR/all_subdomains_raw.txt"
        log "AlterX permutations: $(wc -l < "$SUB_DIR/alterx_perms.txt")"
    fi

    # ── Active DNS bruteforce (only if not passive mode) ──────
    if [[ "$PASSIVE_ONLY" == false ]]; then
        info "Active DNS bruteforce (puredns/dnsx with public resolvers)..."
        local dns_wl
        # Pick best available wordlist
        if [[ -f "/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt" ]]; then
            dns_wl="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"
        elif [[ -f "/usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt" ]]; then
            dns_wl="/usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt"
        else
            dns_wl="$DNS_WORDLIST"
        fi

        if [[ -f "$dns_wl" ]]; then
            # puredns is best for bruteforce (uses massdns under hood)
            if command -v puredns &>/dev/null && command -v massdns &>/dev/null; then
                info "  Using puredns (fastest) with $(wc -l < "$dns_wl") words..."
                puredns bruteforce "$dns_wl" "$TARGET" \
                    -r "$RESOLVERS" \
                    --rate-limit 3000 \
                    -q 2>/dev/null | \
                    sort -u >> "$SUB_DIR/all_subdomains_raw.txt"
                log "  puredns bruteforce done"
            else
                # Fallback: dnsx with public resolvers (much faster than default)
                info "  Using dnsx with fast public resolvers..."
                sed "s/$/.${TARGET}/" "$dns_wl" | \
                    dnsx -silent \
                        -r "$RESOLVERS" \
                        -t 200 \
                        -retry 1 \
                        2>/dev/null | \
                    awk '{print $1}' | \
                    sort -u >> "$SUB_DIR/all_subdomains_raw.txt"
                log "  dnsx bruteforce done"
            fi
        fi
        sort -u "$SUB_DIR/all_subdomains_raw.txt" -o "$SUB_DIR/all_subdomains_raw.txt"
        log "After bruteforce total: $(wc -l < "$SUB_DIR/all_subdomains_raw.txt")"
    fi

    # ══════════════════════════════════════════════════════════
    # STEP A: DNS RESOLUTION (fast — public resolvers)
    # ══════════════════════════════════════════════════════════
    info "Resolving subdomains (fast public resolvers, threads=200)..."
    dnsx -l "$SUB_DIR/all_subdomains_raw.txt" \
        -r "$RESOLVERS" \
        -t 200 \
        -retry 1 \
        -silent \
        -a -cname \
        -o "$SUB_DIR/resolved_full.txt" 2>/dev/null

    # Extract just hostnames (first column), deduplicate
    awk '{print $1}' "$SUB_DIR/resolved_full.txt" 2>/dev/null | \
        sort -u > "$SUB_DIR/resolved_clean.txt"
    log "DNS-resolved subdomains: $(wc -l < "$SUB_DIR/resolved_clean.txt")"

    # ══════════════════════════════════════════════════════════
    # STEP B: HTTP PROBE → ALL live hosts (any status)
    # ══════════════════════════════════════════════════════════
    info "HTTP probing all resolved hosts..."
    httpx -l "$SUB_DIR/resolved_clean.txt" \
        -silent \
        -threads "$THREADS" \
        -follow-redirects \
        -random-agent \
        -status-code \
        -title \
        -tech-detect \
        -web-server \
        -content-length \
        -o "$SUB_DIR/live_hosts_all.txt" 2>/dev/null
    log "All responding hosts: $(wc -l < "$SUB_DIR/live_hosts_all.txt")"

    # ══════════════════════════════════════════════════════════
    # STEP C: FILTER 200 OK ONLY → truly live domains
    # ══════════════════════════════════════════════════════════
    info "Filtering 200 OK (truly live) domains..."
    grep "\[200\]" "$SUB_DIR/live_hosts_all.txt" 2>/dev/null | \
        awk '{print $1}' | sort -u > "$SUB_DIR/live_200_only.txt"
    log "🟢 200 OK (truly live): $(wc -l < "$SUB_DIR/live_200_only.txt")"

    # Also keep 200+301+302 for broader attack surface
    grep -E "\[(200|201|204|301|302|307|401|403)\]" "$SUB_DIR/live_hosts_all.txt" 2>/dev/null | \
        awk '{print $1}' | sort -u > "$SUB_DIR/live_urls.txt"
    log "🔵 All live (200-403): $(wc -l < "$SUB_DIR/live_urls.txt")"

    # Separate by interesting status codes
    grep "\[401\]" "$SUB_DIR/live_hosts_all.txt" | awk '{print $1}' | sort -u > "$SUB_DIR/live_401_auth_required.txt"
    grep "\[403\]" "$SUB_DIR/live_hosts_all.txt" | awk '{print $1}' | sort -u > "$SUB_DIR/live_403_forbidden.txt"
    grep -E "\[301\]|\[302\]" "$SUB_DIR/live_hosts_all.txt" | awk '{print $1}' | sort -u > "$SUB_DIR/live_redirects.txt"

    log "  401 (Auth required): $(wc -l < "$SUB_DIR/live_401_auth_required.txt") — potential login bypass targets"
    log "  403 (Forbidden): $(wc -l < "$SUB_DIR/live_403_forbidden.txt") — potential bypass targets"
    log "  Redirects: $(wc -l < "$SUB_DIR/live_redirects.txt")"

    # ══════════════════════════════════════════════════════════
    # STEP D: TLS CERT INFO on live hosts
    # ══════════════════════════════════════════════════════════
    info "Gathering TLS certificate data..."
    tlsx -l "$SUB_DIR/resolved_clean.txt" \
        -silent -o "$SUB_DIR/tls_info.txt" 2>/dev/null
    log "TLS info gathered"

    # ══════════════════════════════════════════════════════════
    # STEP E: SUBDOMAIN TAKEOVER CHECK
    # ══════════════════════════════════════════════════════════
    info "Checking for subdomain takeovers..."
    nuclei -l "$SUB_DIR/live_urls.txt" \
        -t ~/nuclei-templates/http/takeovers/ \
        -severity critical,high,medium \
        -silent \
        -o "$OUTPUT_DIR/vulnerabilities/subdomain_takeovers.txt" 2>/dev/null
    log "Takeover check: $(wc -l < "$OUTPUT_DIR/vulnerabilities/subdomain_takeovers.txt" 2>/dev/null || echo 0) potential"

    # ── Print summary ─────────────────────────────────────────
    echo ""
    echo -e "${CYAN}${BOLD}┌─── SUBDOMAIN SUMMARY ───────────────────────┐${NC}"
    echo -e "${CYAN}│  Raw subdomains collected : $(wc -l < "$SUB_DIR/all_subdomains_raw.txt")${NC}"
    echo -e "${CYAN}│  DNS resolved             : $(wc -l < "$SUB_DIR/resolved_clean.txt")${NC}"
    echo -e "${CYAN}│  🟢 200 OK (truly live)   : $(wc -l < "$SUB_DIR/live_200_only.txt")${NC}"
    echo -e "${CYAN}│  🔵 All live (200-403)    : $(wc -l < "$SUB_DIR/live_urls.txt")${NC}"
    echo -e "${CYAN}│  🔴 401 Auth Required     : $(wc -l < "$SUB_DIR/live_401_auth_required.txt")${NC}"
    echo -e "${CYAN}│  🟡 403 Forbidden         : $(wc -l < "$SUB_DIR/live_403_forbidden.txt")${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────┘${NC}"
    save_checkpoint "phase1"
}

# ─── PHASE 2: DNS DEEP DIVE ───────────────────────────────────
phase2_dns() {
    section "🔍 PHASE 2: DNS DEEP RECON"
    local DNS_DIR="$OUTPUT_DIR/dns"

    info "Running DNSRecon..."
    dnsrecon -d "$TARGET" -t std,brt,axfr -o "$DNS_DIR/dnsrecon.json" 2>/dev/null

    info "Gathering DNS records (A, MX, TXT, CNAME, NS, SOA)..."
    for record in A AAAA MX TXT CNAME NS SOA SRV; do
        dig "$TARGET" "$record" +short 2>/dev/null > "$DNS_DIR/${record}_records.txt"
        log "$record records: $(cat "$DNS_DIR/${record}_records.txt")"
    done

    # Zone transfer attempt
    info "Attempting DNS zone transfer..."
    NS_SERVERS=$(dig NS "$TARGET" +short 2>/dev/null)
    while IFS= read -r ns; do
        dig axfr "$TARGET" @"$ns" 2>/dev/null > "$DNS_DIR/zone_transfer_${ns}.txt"
        if grep -q "IN" "$DNS_DIR/zone_transfer_${ns}.txt" 2>/dev/null; then
            warn "⚠️  Zone transfer SUCCESSFUL from $ns!"
        fi
    done <<< "$NS_SERVERS"

    # SPF, DMARC, DKIM analysis
    info "Checking email security records (SPF/DMARC/DKIM)..."
    dig TXT "_dmarc.$TARGET" +short > "$DNS_DIR/dmarc.txt" 2>/dev/null
    dig TXT "default._domainkey.$TARGET" +short > "$DNS_DIR/dkim.txt" 2>/dev/null

    # ASN & IP range discovery
    info "Finding ASN information..."
    TARGET_IP=$(dig +short "$TARGET" A | head -1)
    if [[ -n "$TARGET_IP" ]]; then
        whois "$TARGET_IP" 2>/dev/null > "$DNS_DIR/whois_ip.txt"
        curl -s "https://ipinfo.io/$TARGET_IP/json" 2>/dev/null > "$DNS_DIR/ipinfo.json"
        log "Target IP: $TARGET_IP"
        log "ASN: $(jq -r '.org' "$DNS_DIR/ipinfo.json" 2>/dev/null)"
    fi

    # Reverse DNS / PTR
    info "Reverse DNS lookup..."
    dig -x "$TARGET_IP" +short > "$DNS_DIR/reverse_dns.txt" 2>/dev/null

    log "✅ DNS recon complete"
    save_checkpoint "phase2"
}

# ─── PHASE 3: PORT & SERVICE SCAN ────────────────────────────
phase3_ports() {
    [[ "$PASSIVE_ONLY" == true ]] && return
    section "🔌 PHASE 3: PORT & SERVICE SCANNING"
    local PORT_DIR="$OUTPUT_DIR/ports"

    TARGET_IP=$(dig +short "$TARGET" A | head -1)
    [[ -z "$TARGET_IP" ]] && { err "Could not resolve IP for $TARGET"; return; }

    # Naabu - fast port scanner
    info "Fast port scan with Naabu..."
    naabu -host "$TARGET" -p - -silent -rate 1000 \
        -o "$PORT_DIR/all_ports.txt" 2>/dev/null
    log "Open ports found: $(wc -l < "$PORT_DIR/all_ports.txt")"

    # Nmap - service version detection
    info "Service detection with Nmap..."
    PORTS=$(cat "$PORT_DIR/all_ports.txt" 2>/dev/null | grep -oE ':[0-9]+' | tr -d ':' | paste -sd',' -)
    if [[ -n "$PORTS" ]]; then
        nmap -sV -sC -O --script=banner,http-headers,ssl-cert \
            -p "$PORTS" "$TARGET_IP" \
            -oA "$PORT_DIR/nmap_full" 2>/dev/null
        log "Nmap service scan complete"
    fi

    # Interesting ports check
    info "Checking interesting/common ports..."
    for port in 21 22 23 25 53 80 110 143 443 445 1433 1521 3000 3306 3389 4443 5432 5900 6379 7070 8080 8443 8888 9000 9090 9200 27017; do
        timeout 3 bash -c "echo > /dev/tcp/$TARGET_IP/$port" 2>/dev/null && \
            echo "$TARGET_IP:$port OPEN" >> "$PORT_DIR/interesting_ports.txt"
    done
    log "Interesting ports checked"

    # Shodan-like check via public APIs
    info "Querying Shodan (public) for $TARGET_IP..."
    curl -s "https://internetdb.shodan.io/$TARGET_IP" 2>/dev/null | \
        jq . > "$PORT_DIR/shodan_internetdb.json" 2>/dev/null

    log "✅ Port scan complete"
    save_checkpoint "phase3"
}

# ─── PHASE 4: TECHNOLOGY FINGERPRINTING ──────────────────────
phase4_tech() {
    section "🛠️  PHASE 4: TECHNOLOGY FINGERPRINTING"
    local TECH_DIR="$OUTPUT_DIR/tech"

    # httpx tech detection (bulk)
    info "Bulk tech detection with httpx..."
    httpx -l "$OUTPUT_DIR/subdomains/live_urls.txt" \
        -tech-detect -status-code -title -web-server \
        -content-length -response-time -follow-redirects \
        -silent -threads "$THREADS" \
        -o "$TECH_DIR/tech_bulk.txt" 2>/dev/null
    log "Tech detection done: $(wc -l < "$TECH_DIR/tech_bulk.txt") hosts"

    # WhatWeb - detailed per-host
    info "Detailed tech fingerprint with WhatWeb..."
    while IFS= read -r url; do
        whatweb -a 3 --log-json="$TECH_DIR/whatweb_$(echo "$url" | sed 's|https\?://||; s|/|_|g').json" \
            "$url" 2>/dev/null
    done < <(head -50 "$OUTPUT_DIR/subdomains/live_urls.txt")
    log "WhatWeb complete"

    # Response header analysis
    info "Collecting and analyzing HTTP response headers..."
    while IFS= read -r url; do
        domain=$(echo "$url" | sed 's|https\?://||; s|/.*||')
        curl -sI -L --max-time 10 --random-agent "$url" 2>/dev/null > "$TECH_DIR/headers_${domain}.txt"
    done < <(head -30 "$OUTPUT_DIR/subdomains/live_urls.txt")

    # Extract all unique headers
    grep -hE "^(Server|X-Powered-By|X-Generator|X-Application|X-Framework|X-Runtime|Via|X-CDN|CF-Ray|X-Drupal|X-WordPress)" \
        "$TECH_DIR"/headers_*.txt 2>/dev/null | sort -u > "$TECH_DIR/interesting_headers.txt"
    log "Interesting headers: $(wc -l < "$TECH_DIR/interesting_headers.txt")"

    # Cookie analysis
    grep -hi "set-cookie" "$TECH_DIR"/headers_*.txt 2>/dev/null | sort -u > "$TECH_DIR/cookies.txt"
    grep -i "httponly\|secure\|samesite" "$TECH_DIR/cookies.txt" 2>/dev/null > "$TECH_DIR/cookie_flags.txt"

    log "✅ Tech fingerprinting complete"
    save_checkpoint "phase4"
}

# ─── PHASE 5: WAF DETECTION ───────────────────────────────────
phase5_waf() {
    section "🔥 PHASE 5: WAF / CDN DETECTION"
    local WAF_DIR="$OUTPUT_DIR/waf"

    info "WAF detection with wafw00f..."
    while IFS= read -r url; do
        domain=$(echo "$url" | sed 's|https\?://||; s|/.*||')
        wafw00f "$url" -o "$WAF_DIR/wafw00f_${domain}.txt" 2>/dev/null
    done < <(head -20 "$OUTPUT_DIR/subdomains/live_urls.txt")

    # Custom WAF detection from headers
    info "Custom WAF detection from response headers..."
    {
    echo "=== WAF Fingerprints from Headers ==="
    grep -rl "cloudflare\|akamai\|incapsula\|sucuri\|modsecurity\|barracuda\|imperva\|f5\|fastly\|aws-waf\|azure" \
        "$OUTPUT_DIR/tech"/headers_*.txt 2>/dev/null | while read -r f; do
        echo "  WAF detected in: $f"
        grep -iE "cloudflare|akamai|incapsula|sucuri|modsecurity|cf-ray|x-sucuri|x-iinfo" "$f"
    done
    } > "$WAF_DIR/waf_summary.txt"

    # Try to find origin IP (bypass WAF)
    info "Attempting to find real origin IP..."
    {
    echo "=== Origin IP Discovery Attempts ==="
    # Old DNS records
    curl -s "https://securitytrails.com/list/apex_domain/$TARGET" 2>/dev/null | \
        grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u | \
        head -20

    # Shodan internet DB
    curl -s "https://internetdb.shodan.io/$(dig +short $TARGET A | head -1)" 2>/dev/null | jq -r '.hostnames[]' 2>/dev/null

    # Common subdomains that may reveal origin
    for sub in direct origin mail smtp ftp cpanel whm ssh staging dev beta; do
        ip=$(dig +short "$sub.$TARGET" A 2>/dev/null | head -1)
        [[ -n "$ip" ]] && echo "  $sub.$TARGET -> $ip"
    done
    } > "$WAF_DIR/origin_ip_discovery.txt"
    log "WAF analysis complete"

    log "✅ WAF detection complete"
    save_checkpoint "phase5"
}

# ─── PHASE 6: ENDPOINT DISCOVERY ─────────────────────────────
phase6_endpoints() {
    section "🔗 PHASE 6: ENDPOINT DISCOVERY"
    local EP_DIR="$OUTPUT_DIR/endpoints"

    # GAU - Get All URLs from archives
    info "Fetching URLs from web archives (GAU)..."
    gau "$TARGET" --subs --threads "$THREADS" 2>/dev/null | \
        sort -u > "$EP_DIR/gau_urls.txt"
    log "GAU URLs: $(wc -l < "$EP_DIR/gau_urls.txt")"

    # Wayback URLs
    info "Fetching Wayback Machine URLs..."
    waybackurls "$TARGET" 2>/dev/null | sort -u > "$EP_DIR/wayback_urls.txt"
    log "Wayback URLs: $(wc -l < "$EP_DIR/wayback_urls.txt")"

    # Katana - modern JS-aware crawler
    info "Deep crawling with Katana (JS-aware)..."
    katana -list "$OUTPUT_DIR/subdomains/live_urls.txt" \
        -d 5 -jc -kf all -silent \
        -c "$THREADS" \
        -o "$EP_DIR/katana_urls.txt" 2>/dev/null
    log "Katana URLs: $(wc -l < "$EP_DIR/katana_urls.txt")"

    # Hakrawler
    info "Crawling with Hakrawler..."
    cat "$OUTPUT_DIR/subdomains/live_urls.txt" | \
        hakrawler -d 3 -insecure 2>/dev/null | \
        sort -u > "$EP_DIR/hakrawler_urls.txt"
    log "Hakrawler URLs: $(wc -l < "$EP_DIR/hakrawler_urls.txt")"

    # Merge all URLs
    info "Merging and deduplicating all URLs..."
    cat "$EP_DIR"/{gau_urls,wayback_urls,katana_urls,hakrawler_urls}.txt 2>/dev/null | \
        sort -u > "$EP_DIR/all_urls_raw.txt"
    log "Total raw URLs: $(wc -l < "$EP_DIR/all_urls_raw.txt")"

    # URO - deduplicate smart
    info "Smart deduplication with URO..."
    uro -i "$EP_DIR/all_urls_raw.txt" -o "$EP_DIR/all_urls_clean.txt" 2>/dev/null
    log "Deduplicated URLs: $(wc -l < "$EP_DIR/all_urls_clean.txt")"

    # Categorize URLs
    info "Categorizing endpoints..."
    grep -iE "\.(php|asp|aspx|jsp|cgi|pl)" "$EP_DIR/all_urls_clean.txt" > "$EP_DIR/dynamic_pages.txt"
    grep -iE "/api/" "$EP_DIR/all_urls_clean.txt" > "$EP_DIR/api_endpoints.txt"
    grep -iE "/admin|/dashboard|/panel|/manager|/backend|/wp-admin|/cpanel" "$EP_DIR/all_urls_clean.txt" > "$EP_DIR/admin_panels.txt"
    grep -iE "\.(json|xml|yaml|yml|conf|config|env|bak|backup|sql|log)" "$EP_DIR/all_urls_clean.txt" > "$EP_DIR/sensitive_files.txt"
    grep -iE "/graphql|/gql" "$EP_DIR/all_urls_clean.txt" > "$EP_DIR/graphql_endpoints.txt"
    grep -iE "=" "$EP_DIR/all_urls_clean.txt" > "$EP_DIR/urls_with_params.txt"

    log "Dynamic pages: $(wc -l < "$EP_DIR/dynamic_pages.txt")"
    log "API endpoints: $(wc -l < "$EP_DIR/api_endpoints.txt")"
    log "Admin panels: $(wc -l < "$EP_DIR/admin_panels.txt")"
    log "Sensitive files: $(wc -l < "$EP_DIR/sensitive_files.txt")"
    log "GraphQL: $(wc -l < "$EP_DIR/graphql_endpoints.txt")"

    log "✅ Endpoint discovery complete (Feroxbuster dir-fuzz runs at end as final phase)"
    save_checkpoint "phase6"
}

# ─── PHASE 7: JAVASCRIPT ANALYSIS ────────────────────────────
phase7_js() {
    section "📜 PHASE 7: JAVASCRIPT ANALYSIS"
    local JS_DIR="$OUTPUT_DIR/js_analysis"

    # Extract all JS file URLs
    info "Extracting JavaScript file URLs..."
    grep -iE "\.js(\?|$)" "$OUTPUT_DIR/endpoints/all_urls_clean.txt" 2>/dev/null | \
        sort -u > "$JS_DIR/js_urls.txt"
    log "JS files found: $(wc -l < "$JS_DIR/js_urls.txt")"

    # Download and analyze JS files
    info "Downloading and analyzing JS files..."
    mkdir -p "$JS_DIR/files"
    head -100 "$JS_DIR/js_urls.txt" | while IFS= read -r jsurl; do
        filename=$(echo "$jsurl" | md5sum | cut -d' ' -f1)
        curl -s -L --max-time 15 "$jsurl" -o "$JS_DIR/files/${filename}.js" 2>/dev/null
    done

    # LinkFinder - extract endpoints from JS
    info "Extracting endpoints with LinkFinder..."
    for jsfile in "$JS_DIR/files"/*.js; do
        [[ -f "$jsfile" ]] || continue
        python3 /opt/LinkFinder/linkfinder.py -i "$jsfile" -o cli 2>/dev/null
    done | sort -u > "$JS_DIR/linkfinder_endpoints.txt"
    log "LinkFinder endpoints: $(wc -l < "$JS_DIR/linkfinder_endpoints.txt")"

    # SecretFinder - find secrets in JS
    info "Hunting secrets with SecretFinder..."
    for jsfile in "$JS_DIR/files"/*.js; do
        [[ -f "$jsfile" ]] || continue
        python3 /opt/SecretFinder/SecretFinder.py -i "$jsfile" -o cli 2>/dev/null
    done | sort -u > "$JS_DIR/secrets_found.txt"
    log "Secrets found: $(wc -l < "$JS_DIR/secrets_found.txt")"

    # Manual regex pattern search in JS files
    info "Pattern-based secret hunting in JS..."
    {
    echo "=== API Keys & Tokens ==="
    grep -rEo "(api[_-]?key|apikey|api[_-]?secret|access[_-]?token|auth[_-]?token|bearer)['\"\s:=]+['\"]?[a-zA-Z0-9_\-]{16,}" \
        "$JS_DIR/files/" 2>/dev/null | head -50

    echo -e "\n=== AWS Credentials ==="
    grep -rEo "AKIA[0-9A-Z]{16}" "$JS_DIR/files/" 2>/dev/null | head -20
    grep -rEo "(aws[_-]?secret|aws[_-]?access)['\"\s:=]+['\"]?[a-zA-Z0-9/+]{40}" "$JS_DIR/files/" 2>/dev/null | head -20

    echo -e "\n=== Hardcoded Passwords ==="
    grep -rEio "(password|passwd|pwd)['\"\s:=]+['\"]?[a-zA-Z0-9@#$%^&*!_\-]{6,}" \
        "$JS_DIR/files/" 2>/dev/null | grep -v "placeholder\|example\|your_password" | head -30

    echo -e "\n=== Private Keys ==="
    grep -rl "BEGIN.*PRIVATE KEY\|BEGIN RSA\|BEGIN EC" "$JS_DIR/files/" 2>/dev/null

    echo -e "\n=== Emails ==="
    grep -rEo "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$JS_DIR/files/" 2>/dev/null | \
        grep -v "example\|test\|placeholder" | sort -u | head -30

    echo -e "\n=== Internal URLs / IPs ==="
    grep -rEo "(https?://[a-zA-Z0-9._\-]+\.[a-zA-Z]{2,}[^\s\"']*|http://(?:10|172\.16|192\.168)\.[0-9.]+)" \
        "$JS_DIR/files/" 2>/dev/null | grep -v "$TARGET" | sort -u | head -30

    echo -e "\n=== GraphQL Queries ==="
    grep -rEi "query\s*{\|mutation\s*{\|subscription\s*{" "$JS_DIR/files/" 2>/dev/null | head -20
    } > "$JS_DIR/manual_secrets.txt"
    log "Manual pattern search complete"

    log "✅ JavaScript analysis complete"
    save_checkpoint "phase7"
}

# ─── PHASE 8: PARAMETER DISCOVERY ────────────────────────────
phase8_params() {
    section "⚙️  PHASE 8: PARAMETER DISCOVERY"
    local PARAM_DIR="$OUTPUT_DIR/params"

    # Extract params from archived URLs
    info "Extracting parameters from archived URLs..."
    grep "?" "$OUTPUT_DIR/endpoints/all_urls_clean.txt" 2>/dev/null | \
        grep -oE "[?&][a-zA-Z0-9_\-]+=?" | \
        tr -d '?&=' | sort -u > "$PARAM_DIR/params_from_urls.txt"
    log "Params from URLs: $(wc -l < "$PARAM_DIR/params_from_urls.txt")"

    # ParamSpider
    if [[ -f /opt/ParamSpider/paramspider.py ]]; then
        info "Running ParamSpider..."
        python3 /opt/ParamSpider/paramspider.py -d "$TARGET" \
            -o "$PARAM_DIR/paramspider_output.txt" 2>/dev/null
        log "ParamSpider done: $(wc -l < "$PARAM_DIR/paramspider_output.txt" 2>/dev/null || echo 0) URLs"
    fi

    # Arjun - hidden parameter finder
    info "Running Arjun for hidden parameters..."
    while IFS= read -r url; do
        arjun -u "$url" --stable \
            -oJ "$PARAM_DIR/arjun_$(echo "$url" | md5sum | cut -d' ' -f1).json" \
            2>/dev/null
    done < <(head -20 "$OUTPUT_DIR/endpoints/dynamic_pages.txt")

    # Merge all parameter findings
    info "Compiling all discovered parameters..."
    {
    cat "$PARAM_DIR/params_from_urls.txt" 2>/dev/null
    grep -rh "param\|query\|key" "$PARAM_DIR"/arjun_*.json 2>/dev/null | \
        jq -r '.params[]?' 2>/dev/null
    } | sort -u > "$PARAM_DIR/all_params.txt"
    log "Total unique params: $(wc -l < "$PARAM_DIR/all_params.txt")"

    # Categorize interesting params
    info "Categorizing high-value parameters..."
    grep -iE "^(url|redirect|next|redir|return|dest|destination|goto|link|target|ref|referer|source|src|callback|continue|img|image|path|file|dir|doc|load|open|get|data|page|view|show|read|fetch|request|host|site|to|from|out)" \
        "$PARAM_DIR/all_params.txt" > "$PARAM_DIR/ssrf_redirect_params.txt"
    grep -iE "^(id|user|userid|uid|account|num|no|order|pid|item|product|cat|category|article|page|post|object|ref)" \
        "$PARAM_DIR/all_params.txt" > "$PARAM_DIR/idor_params.txt"
    grep -iE "^(q|query|search|s|find|keyword|term|input|text|name|email|phone|message|comment|content|body|desc)" \
        "$PARAM_DIR/all_params.txt" > "$PARAM_DIR/xss_sqli_params.txt"

    log "SSRF/Redirect params: $(wc -l < "$PARAM_DIR/ssrf_redirect_params.txt")"
    log "IDOR params: $(wc -l < "$PARAM_DIR/idor_params.txt")"
    log "XSS/SQLi params: $(wc -l < "$PARAM_DIR/xss_sqli_params.txt")"
    log "✅ Parameter discovery complete"
    save_checkpoint "phase8"
}

# ─── PHASE 9: CLOUD ASSET RECON ──────────────────────────────
phase9_cloud() {
    section "☁️  PHASE 9: CLOUD & INFRASTRUCTURE RECON"
    local CLOUD_DIR="$OUTPUT_DIR/cloud"

    # Pre-create cloud output files
    touch "$CLOUD_DIR/s3_buckets.txt" \
          "$CLOUD_DIR/gcs_buckets.txt" \
          "$CLOUD_DIR/azure_storage.txt" \
          "$CLOUD_DIR/firebase.txt"

    # S3 bucket naming patterns
    info "Hunting for S3 buckets..."
    local COMPANY_NAME
    COMPANY_NAME=$(echo "$TARGET" | sed 's/\..*//')
    local S3_PATTERNS=(
        "$COMPANY_NAME"
        "${TARGET//./-}"
        "www-${TARGET//./-}"
        "dev-${COMPANY_NAME}"
        "staging-${COMPANY_NAME}"
        "assets-${COMPANY_NAME}"
        "static-${COMPANY_NAME}"
        "backup-${COMPANY_NAME}"
        "data-${COMPANY_NAME}"
        "files-${COMPANY_NAME}"
        "uploads-${COMPANY_NAME}"
        "media-${COMPANY_NAME}"
        "images-${COMPANY_NAME}"
        "logs-${COMPANY_NAME}"
        "cdn-${COMPANY_NAME}"
        "storage-${COMPANY_NAME}"
        "${COMPANY_NAME}-prod"
        "${COMPANY_NAME}-dev"
        "${COMPANY_NAME}-backup"
    )

    local s3_found=0 s3_private=0
    for bucket_clean in "${S3_PATTERNS[@]}"; do
        # AWS S3
        status=$(curl -s -o /dev/null -w "%{http_code}" \
            "https://${bucket_clean}.s3.amazonaws.com" --max-time 8 2>/dev/null)
        case "$status" in
            200) warn "⚠️  PUBLIC S3: ${bucket_clean}.s3.amazonaws.com"
                 echo "${bucket_clean} - AWS S3 PUBLIC" >> "$CLOUD_DIR/s3_buckets.txt"
                 ((s3_found++)) ;;
            403) echo "${bucket_clean} - AWS S3 EXISTS(private)" >> "$CLOUD_DIR/s3_buckets.txt"
                 ((s3_private++)) ;;
        esac

        # GCS
        gcs_status=$(curl -s -o /dev/null -w "%{http_code}" \
            "https://storage.googleapis.com/${bucket_clean}" --max-time 8 2>/dev/null)
        case "$gcs_status" in
            200) warn "⚠️  PUBLIC GCS: ${bucket_clean}"
                 echo "${bucket_clean} - GCS PUBLIC" >> "$CLOUD_DIR/gcs_buckets.txt" ;;
            403) echo "${bucket_clean} - GCS EXISTS(private)" >> "$CLOUD_DIR/gcs_buckets.txt" ;;
        esac

        # Azure Blob
        az_status=$(curl -s -o /dev/null -w "%{http_code}" \
            "https://${bucket_clean}.blob.core.windows.net" --max-time 8 2>/dev/null)
        [[ "$az_status" == "400" || "$az_status" == "200" ]] && \
            echo "${bucket_clean} - Azure Blob exists" >> "$CLOUD_DIR/azure_storage.txt"
    done
    log "S3 check done: ${s3_found} public, ${s3_private} private buckets found"

    # Firebase detection
    info "Checking Firebase..."
    local fb_found=0
    for fb in "$COMPANY_NAME" "${COMPANY_NAME}-default" "${COMPANY_NAME}-prod" "${COMPANY_NAME}-dev"; do
        status=$(curl -s -o /dev/null -w "%{http_code}" \
            "https://${fb}.firebaseio.com/.json" --max-time 8 2>/dev/null)
        case "$status" in
            200) warn "⚠️  PUBLIC Firebase: ${fb}.firebaseio.com"
                 echo "${fb}.firebaseio.com - PUBLIC" >> "$CLOUD_DIR/firebase.txt"
                 ((fb_found++)) ;;
            401) echo "${fb}.firebaseio.com - EXISTS(auth required)" >> "$CLOUD_DIR/firebase.txt" ;;
        esac
    done
    log "Firebase check done: ${fb_found} public databases found"

    # SSRF metadata endpoint test
    info "Documenting SSRF metadata endpoints for testing..."
    cat > "$CLOUD_DIR/ssrf_targets.txt" << 'SSRF_EOF'
# AWS Instance Metadata
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/user-data/
http://[::ffff:169.254.169.254]/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Google Cloud Metadata
http://metadata.google.internal/computeMetadata/v1/
http://169.254.169.254/computeMetadata/v1/

# Azure Metadata
http://169.254.169.254/metadata/instance?api-version=2021-02-01

# DigitalOcean Metadata
http://169.254.169.254/metadata/v1/

# Common SSRF bypasses
http://localtest.me/
http://spoofed.burpcollaborator.net/
http://[::1]
http://0177.1 (octal)
SSRF_EOF

    log "✅ Cloud recon complete"
    save_checkpoint "phase9"
}

# ─── PHASE 10: VULNERABILITY SCANNING ────────────────────────
phase10_vulns() {
    [[ "$PASSIVE_ONLY" == true ]] && return
    section "🎯 PHASE 10: AUTOMATED VULNERABILITY SCANNING"
    local VULN_DIR="$OUTPUT_DIR/vulnerabilities"

    # Pre-create output files to avoid wc -l errors
    touch "$VULN_DIR/sensitive_exposed.txt" \
          "$VULN_DIR/protected_sensitive.txt" \
          "$VULN_DIR/cors_issues.txt" \
          "$VULN_DIR/missing_security_headers.txt" \
          "$VULN_DIR/nuclei_findings.txt" \
          "$VULN_DIR/exposed_panels.txt" \
          "$VULN_DIR/misconfigs.txt" \
          "$VULN_DIR/cves_found.txt"

    # User-Agent to rotate (curl does not support --random-agent)
    UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    # Nuclei - comprehensive template scan
    info "Running Nuclei (critical/high/medium templates)..."
    nuclei -l "$OUTPUT_DIR/subdomains/live_urls.txt" \
        -t ~/nuclei-templates \
        -severity critical,high,medium \
        -silent -rate-limit 50 \
        -stats \
        -o "$VULN_DIR/nuclei_findings.txt" 2>/dev/null
    log "Nuclei findings: $(wc -l < "$VULN_DIR/nuclei_findings.txt")"

    # Nuclei specific checks
    info "Nuclei: Checking for exposed panels..."
    nuclei -l "$OUTPUT_DIR/subdomains/live_urls.txt" \
        -t ~/nuclei-templates/http/exposed-panels/ \
        -severity critical,high,medium \
        -silent -o "$VULN_DIR/exposed_panels.txt" 2>/dev/null

    info "Nuclei: Checking for misconfigurations..."
    nuclei -l "$OUTPUT_DIR/subdomains/live_urls.txt" \
        -t ~/nuclei-templates/http/misconfiguration/ \
        -severity critical,high,medium \
        -silent -o "$VULN_DIR/misconfigs.txt" 2>/dev/null

    info "Nuclei: Checking for CVEs..."
    nuclei -l "$OUTPUT_DIR/subdomains/live_urls.txt" \
        -t ~/nuclei-templates/http/cves/ \
        -severity critical,high \
        -silent -o "$VULN_DIR/cves_found.txt" 2>/dev/null

    # Check for common sensitive paths
    info "Checking common sensitive paths..."
    SENSITIVE_PATHS=(
        "/.git/HEAD" "/.git/config" "/.env" "/.env.local" "/.env.prod"
        "/config.php" "/config.json" "/wp-config.php" "/database.yml"
        "/.htaccess" "/server-status" "/server-info" "/phpinfo.php"
        "/admin" "/admin/login" "/administrator" "/wp-admin"
        "/api/swagger.json" "/swagger-ui.html" "/api-docs"
        "/actuator" "/actuator/env" "/actuator/mappings"
        "/.well-known/security.txt" "/security.txt"
        "/crossdomain.xml" "/sitemap.xml" "/robots.txt"
        "/backup.zip" "/backup.sql" "/dump.sql"
        "/graphql" "/graphiql" "/__graphql"
    )

    while IFS= read -r baseurl; do
        for path in "${SENSITIVE_PATHS[@]}"; do
            full_url="${baseurl%/}${path}"
            status=$(curl -s -o /dev/null -w "%{http_code}" \
                -L --max-time 8 \
                -H "User-Agent: $UA" \
                "$full_url" 2>/dev/null)
            case "$status" in
                200|206) warn "EXPOSED: $full_url [$status]"
                         echo "$full_url [$status]" >> "$VULN_DIR/sensitive_exposed.txt" ;;
                401|403) echo "$full_url [$status PROTECTED]" >> "$VULN_DIR/protected_sensitive.txt" ;;
            esac
        done
    done < <(head -10 "$OUTPUT_DIR/subdomains/live_urls.txt")
    log "Sensitive paths: $(wc -l < "$VULN_DIR/sensitive_exposed.txt") exposed"

    # CORS misconfiguration check
    info "Checking CORS misconfigurations..."
    while IFS= read -r url; do
        cors=$(curl -s -I \
            -H "Origin: https://evil.com" \
            -H "User-Agent: $UA" \
            --max-time 8 "$url" 2>/dev/null | \
            grep -i "access-control-allow-origin")
        if echo "$cors" | grep -qi "evil.com\|\*"; then
            warn "CORS issue: $url -> $cors"
            echo "$url -> $cors" >> "$VULN_DIR/cors_issues.txt"
        fi
    done < <(head -30 "$OUTPUT_DIR/subdomains/live_urls.txt")
    log "CORS check done: $(wc -l < "$VULN_DIR/cors_issues.txt") issues"

    # Security headers check
    info "Checking security headers..."
    while IFS= read -r url; do
        headers=$(curl -sI \
            -H "User-Agent: $UA" \
            --max-time 8 "$url" 2>/dev/null)
        missing=""
        echo "$headers" | grep -qi "content-security-policy" || missing+="CSP "
        echo "$headers" | grep -qi "x-frame-options"         || missing+="X-Frame "
        echo "$headers" | grep -qi "x-content-type"          || missing+="X-Content-Type "
        echo "$headers" | grep -qi "strict-transport"        || missing+="HSTS "
        echo "$headers" | grep -qi "referrer-policy"         || missing+="Referrer-Policy "
        [[ -n "$missing" ]] && echo "$url | Missing: $missing" >> "$VULN_DIR/missing_security_headers.txt"
    done < <(head -20 "$OUTPUT_DIR/subdomains/live_urls.txt")
    log "Security headers checked: $(wc -l < "$VULN_DIR/missing_security_headers.txt") hosts with missing headers"

    if [[ "$DEEP_SCAN" == true ]]; then
        # Nikto - comprehensive web server scan
        info "Running Nikto deep scan (this takes time)..."
        nikto -h "https://$TARGET" -o "$VULN_DIR/nikto_main.txt" \
            -Format txt -timeout 10 2>/dev/null
        log "Nikto scan complete"
    fi

    log "✅ Vulnerability scanning complete"
    save_checkpoint "phase10"
}

# ─── PHASE 11: GITHUB & SECRETS HUNTING ──────────────────────
phase11_secrets() {
    section "🔐 PHASE 11: SECRETS & LEAKED DATA HUNTING"
    local SEC_DIR="$OUTPUT_DIR/secrets"
    local COMPANY_NAME
    COMPANY_NAME=$(echo "$TARGET" | sed 's/\..*//')

    touch "$SEC_DIR/exposed_git.txt" "$SEC_DIR/trufflehog_findings.json"

    # Google dorks for exposed files (document for manual use)
    info "Generating Google Dork queries..."
    cat > "$SEC_DIR/google_dorks.txt" << DORKS_EOF
=== GOOGLE DORKS FOR $TARGET ===
(Use these manually in browser)

--- Sensitive Files ---
site:$TARGET filetype:pdf
site:$TARGET filetype:xlsx OR filetype:csv
site:$TARGET filetype:sql
site:$TARGET ext:php intitle:"phpinfo()"
site:$TARGET ext:log
site:$TARGET ext:bak
site:$TARGET ext:conf OR ext:config
site:$TARGET ext:env

--- Login & Admin ---
site:$TARGET inurl:admin
site:$TARGET inurl:login
site:$TARGET intitle:"dashboard"
site:$TARGET inurl:panel

--- Credentials ---
site:$TARGET "password" filetype:txt
site:$TARGET "secret" filetype:json
site:$TARGET "api_key" OR "apikey" OR "api-key"

--- GitHub & Pastebin ---
site:github.com "$TARGET"
site:github.com "$COMPANY_NAME" password
site:pastebin.com "$TARGET"
site:trello.com "$TARGET"
site:jira.$TARGET
site:confluence.$TARGET

--- Error Pages ---
site:$TARGET "Fatal error"
site:$TARGET "Warning: mysql"
site:$TARGET "ORA-"
site:$TARGET "syntax error"

--- AWS/Cloud ---
site:$TARGET s3.amazonaws.com
"$TARGET" site:s3.amazonaws.com
DORKS_EOF
    log "Dorks generated"

    # TruffleHog on public repos
    if command -v trufflehog &>/dev/null; then
        info "Hunting secrets with TruffleHog..."
        trufflehog github --org="$COMPANY_NAME" \
            --only-verified \
            --json 2>/dev/null | \
            head -100 > "$SEC_DIR/trufflehog_findings.json" 2>/dev/null
        log "TruffleHog: $(wc -l < "$SEC_DIR/trufflehog_findings.json") findings"
    else
        warn "TruffleHog not installed, skipping GitHub secret scan"
        warn "Install: pip3 install trufflehog OR go install github.com/trufflesecurity/trufflehog/v3@latest"
    fi

    # Check for exposed .git
    info "Checking for exposed .git repositories..."
    while IFS= read -r url; do
        git_status=$(curl -s -o /dev/null -w "%{http_code}" \
            "${url%/}/.git/HEAD" --max-time 5)
        [[ "$git_status" == "200" ]] && \
            warn "⚠️  Exposed .git: ${url}/.git/" && \
            echo "${url}/.git/" >> "$SEC_DIR/exposed_git.txt"
    done < <(cat "$OUTPUT_DIR/subdomains/live_urls.txt")

    log "✅ Secrets hunting complete"
    save_checkpoint "phase11"
}

# ─── PHASE 12: SCREENSHOTS ───────────────────────────────────
phase12_screenshots() {
    section "📸 PHASE 12: SCREENSHOTS"
    local SS_DIR="$OUTPUT_DIR/screenshots"

    if command -v chromium &>/dev/null || command -v chromium-browser &>/dev/null; then
        CHROME=$(command -v chromium || command -v chromium-browser)
        info "Taking screenshots of live hosts..."
        while IFS= read -r url; do
            filename=$(echo "$url" | sed 's|https\?://||; s|[/:]|_|g')
            timeout 30 "$CHROME" \
                --headless --disable-gpu \
                --no-sandbox --disable-dev-shm-usage \
                --screenshot="$SS_DIR/${filename}.png" \
                --window-size=1920,1080 \
                "$url" 2>/dev/null
        done < <(head -30 "$OUTPUT_DIR/subdomains/live_urls.txt")
        log "Screenshots: $(ls "$SS_DIR"/*.png 2>/dev/null | wc -l) taken"
    else
        warn "Chromium not found, skipping screenshots"
    fi
    save_checkpoint "phase12"
}

# ─── FINAL REPORT GENERATOR ──────────────────────────────────
generate_report() {
    section "📋 GENERATING FINAL REPORT"
    local REPORT="$OUTPUT_DIR/reports/RECON_REPORT_${TARGET}.md"
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$REPORT" << REPORT_EOF
# 🎯 Bug Bounty Recon Report
**Target:** $TARGET  
**Date:** $TIMESTAMP  
**Mode:** $([ "$PASSIVE_ONLY" = true ] && echo "Passive Only" || echo "Full Scan")  
**Deep Scan:** $DEEP_SCAN  

---

## 📊 Summary Statistics

| Category | Count |
|----------|-------|
| Total Raw Subdomains | $(wc -l < "$OUTPUT_DIR/subdomains/all_subdomains_raw.txt" 2>/dev/null || echo 0) |
| DNS Resolved Subdomains | $(wc -l < "$OUTPUT_DIR/subdomains/resolved_clean.txt" 2>/dev/null || echo 0) |
| 🟢 200 OK Live Hosts | $(wc -l < "$OUTPUT_DIR/subdomains/live_200_only.txt" 2>/dev/null || echo 0) |
| 🔵 All Live Hosts (200-403) | $(wc -l < "$OUTPUT_DIR/subdomains/live_urls.txt" 2>/dev/null || echo 0) |
| Total URLs Found | $(wc -l < "$OUTPUT_DIR/endpoints/all_urls_raw.txt" 2>/dev/null || echo 0) |
| Unique URLs (deduped) | $(wc -l < "$OUTPUT_DIR/endpoints/all_urls_clean.txt" 2>/dev/null || echo 0) |
| API Endpoints | $(wc -l < "$OUTPUT_DIR/endpoints/api_endpoints.txt" 2>/dev/null || echo 0) |
| Admin Panels | $(wc -l < "$OUTPUT_DIR/endpoints/admin_panels.txt" 2>/dev/null || echo 0) |
| Unique Parameters | $(wc -l < "$OUTPUT_DIR/params/all_params.txt" 2>/dev/null || echo 0) |
| JS Files Analyzed | $(ls "$OUTPUT_DIR/js_analysis/files/"*.js 2>/dev/null | wc -l || echo 0) |
| Nuclei Findings | $(wc -l < "$OUTPUT_DIR/vulnerabilities/nuclei_findings.txt" 2>/dev/null || echo 0) |
| CORS Issues | $(wc -l < "$OUTPUT_DIR/vulnerabilities/cors_issues.txt" 2>/dev/null || echo 0) |
| Exposed Sensitive Files | $(wc -l < "$OUTPUT_DIR/vulnerabilities/sensitive_exposed.txt" 2>/dev/null || echo 0) |
| Exposed .git repos | $(wc -l < "$OUTPUT_DIR/secrets/exposed_git.txt" 2>/dev/null || echo 0) |

---

## 🌐 Live Hosts — 200 OK Only (Truly Live)
\`\`\`
$(head -50 "$OUTPUT_DIR/subdomains/live_200_only.txt" 2>/dev/null || echo "None")
\`\`\`

## 🔵 All Live Hosts (200/301/302/401/403)
\`\`\`
$(head -50 "$OUTPUT_DIR/subdomains/live_hosts_all.txt" 2>/dev/null)
\`\`\`

## 🔥 Critical Findings

### Subdomain Takeovers
\`\`\`
$(cat "$OUTPUT_DIR/vulnerabilities/subdomain_takeovers.txt" 2>/dev/null || echo "None found")
\`\`\`

### Exposed Sensitive Files
\`\`\`
$(cat "$OUTPUT_DIR/vulnerabilities/sensitive_exposed.txt" 2>/dev/null || echo "None found")
\`\`\`

### CORS Misconfigurations
\`\`\`
$(cat "$OUTPUT_DIR/vulnerabilities/cors_issues.txt" 2>/dev/null || echo "None found")
\`\`\`

### Cloud Buckets (Public)
\`\`\`
$(cat "$OUTPUT_DIR/cloud/s3_buckets.txt" 2>/dev/null | grep PUBLIC || echo "None found")
$(cat "$OUTPUT_DIR/cloud/gcs_buckets.txt" 2>/dev/null | grep PUBLIC || echo "")
\`\`\`

### Nuclei Findings
\`\`\`
$(head -30 "$OUTPUT_DIR/vulnerabilities/nuclei_findings.txt" 2>/dev/null || echo "None found")
\`\`\`

### Exposed .git Repos
\`\`\`
$(cat "$OUTPUT_DIR/secrets/exposed_git.txt" 2>/dev/null || echo "None found")
\`\`\`

### Secrets in JS Files
\`\`\`
$(head -30 "$OUTPUT_DIR/js_analysis/secrets_found.txt" 2>/dev/null || echo "None found")
\`\`\`

## 🔌 Open Ports
\`\`\`
$(cat "$OUTPUT_DIR/ports/interesting_ports.txt" 2>/dev/null || echo "Not scanned")
\`\`\`

## 🛠️ Technologies Detected
\`\`\`
$(head -30 "$OUTPUT_DIR/tech/tech_bulk.txt" 2>/dev/null)
\`\`\`

## 🔗 API Endpoints
\`\`\`
$(head -50 "$OUTPUT_DIR/endpoints/api_endpoints.txt" 2>/dev/null || echo "None")
\`\`\`

## ⚙️ High-Value Parameters

### SSRF/Redirect Params
\`\`\`
$(cat "$OUTPUT_DIR/params/ssrf_redirect_params.txt" 2>/dev/null)
\`\`\`

### IDOR Params
\`\`\`
$(cat "$OUTPUT_DIR/params/idor_params.txt" 2>/dev/null)
\`\`\`

### XSS/SQLi Params
\`\`\`
$(cat "$OUTPUT_DIR/params/xss_sqli_params.txt" 2>/dev/null)
\`\`\`

## 🔍 WAF Info
\`\`\`
$(cat "$OUTPUT_DIR/waf/waf_summary.txt" 2>/dev/null)
\`\`\`

## 📌 DNS Records
\`\`\`
A:    $(cat "$OUTPUT_DIR/dns/A_records.txt" 2>/dev/null)
MX:   $(cat "$OUTPUT_DIR/dns/MX_records.txt" 2>/dev/null)
TXT:  $(cat "$OUTPUT_DIR/dns/TXT_records.txt" 2>/dev/null | head -5)
NS:   $(cat "$OUTPUT_DIR/dns/NS_records.txt" 2>/dev/null)
\`\`\`

## 📁 Output Directory Structure
\`\`\`
$OUTPUT_DIR/
├── subdomains/    - All subdomain data
├── dns/           - DNS records & analysis
├── ports/         - Port scan results
├── tech/          - Technology fingerprints
├── endpoints/     - URLs & API paths
├── js_analysis/   - JavaScript file analysis
├── params/        - HTTP parameters
├── waf/           - WAF/Firewall info
├── cloud/         - Cloud asset recon
├── vulnerabilities/ - Vulnerability findings
├── secrets/       - Leaked data & secrets
├── screenshots/   - Visual captures
└── reports/       - This report
\`\`\`

---
*Generated by Ultimate Bug Bounty Recon Script v3.0*  
*⚠️ Only use on authorized targets in scope of bug bounty programs*
REPORT_EOF

    log "✅ Report saved: $REPORT"
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║       RECON COMPLETE! 🎯                     ║${NC}"
    echo -e "${GREEN}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}${BOLD}║  Output: $OUTPUT_DIR${NC}"
    echo -e "${GREEN}${BOLD}║  Report: $REPORT${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
}

# ─── PHASE 13: FEROXBUSTER ALL SUBDOMAINS (LAST — time-intensive) ────────────
# Runs on EVERY live subdomain using ONLY common.txt (fast, broad coverage)
# All found paths are merged into all_endpoints_master.txt for manual analysis
phase_ferox_all() {
    [[ "$PASSIVE_ONLY" == true ]] && return
    section "🔍 PHASE 13: FEROXBUSTER — ALL SUBDOMAINS (common.txt only)"
    local EP_DIR="$OUTPUT_DIR/endpoints"
    local FEROX_DIR="$OUTPUT_DIR/endpoints/ferox_all"
    mkdir -p "$FEROX_DIR"

    # ── Install feroxbuster if missing ───────────────────────
    if ! command -v feroxbuster &>/dev/null; then
        warn "Installing feroxbuster..."
        curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
            | bash -s -- /usr/local/bin 2>/dev/null && \
            log "feroxbuster installed" || { err "feroxbuster install failed"; return; }
    fi

    # ── Wordlist: common.txt ONLY (as requested) ─────────────
    local WL_COMMON="/usr/share/wordlists/dirb/common.txt"
    [[ ! -f "$WL_COMMON" ]] && WL_COMMON="/usr/share/dirb/wordlists/common.txt"
    [[ ! -f "$WL_COMMON" ]] && { err "common.txt not found — install dirb"; return; }
    log "Wordlist: $WL_COMMON ($(wc -l < "$WL_COMMON") words)"

    # ── Build target list: main domain + ALL live subdomains ──
    local TARGETS_LIST="$FEROX_DIR/targets.txt"
    {
        # Main target first
        echo "https://$TARGET"
        # All live subdomains (200+301+302+401+403)
        cat "$OUTPUT_DIR/subdomains/live_urls.txt" 2>/dev/null
    } | sort -u > "$TARGETS_LIST"
    local TOTAL=$(wc -l < "$TARGETS_LIST")
    log "Feroxbuster targets: $TOTAL hosts"

    # ── Run feroxbuster on each host ─────────────────────────
    local COUNT=0
    while IFS= read -r target_url; do
        COUNT=$((COUNT + 1))
        local subdomain
        subdomain=$(echo "$target_url" | sed 's|https\?://||; s|[:/].*||')
        info "[$COUNT/$TOTAL] Fuzzing: $target_url"

        feroxbuster \
            --url "$target_url" \
            --wordlist "$WL_COMMON" \
            --threads 40 \
            --depth 1 \
            --no-recursion \
            --status-codes 200,201,204,301,302,307,401,403,405 \
            --timeout 10 \
            --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" \
            --auto-tune \
            --output "$FEROX_DIR/ferox_${subdomain}.txt" \
            --insecure \
            --quiet \
            2>/dev/null

        local found
        found=$(grep -oE 'https?://[^ ]+' "$FEROX_DIR/ferox_${subdomain}.txt" 2>/dev/null | wc -l)
        log "  ✓ $subdomain — $found paths found"
    done < "$TARGETS_LIST"

    # ── Merge ALL ferox results into master file ──────────────
    info "Merging all ferox results into endpoints master file..."
    grep -rhoE 'https?://[^ ]+' "$FEROX_DIR"/ 2>/dev/null | sort -u \
        > "$FEROX_DIR/ferox_all_found.txt"
    log "Total ferox paths found (all hosts): $(wc -l < "$FEROX_DIR/ferox_all_found.txt")"

    # ── Build all_endpoints_master.txt  ──────────────────────
    # Consolidates: GAU + Wayback + Katana + Hakrawler + Ferox (all subdomains)
    # This is the ONE file ultimate_masaudsec_hack.sh and manual analysis uses
    local MASTER="$OUTPUT_DIR/endpoints/all_endpoints_master.txt"
    cat \
        "$EP_DIR/all_urls_clean.txt" \
        "$EP_DIR/api_endpoints.txt" \
        "$EP_DIR/urls_with_params.txt" \
        "$FEROX_DIR/ferox_all_found.txt" \
        2>/dev/null | sort -u > "$MASTER"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "📋 ALL ENDPOINTS MASTER: $MASTER"
    log "   Total unique endpoints: $(wc -l < "$MASTER")"
    log "   (Use this for manual analysis & ultimate_masaudsec_hack.sh)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✅ Feroxbuster all-subdomains phase complete"
    save_checkpoint "phase13"
}

# ─── MAIN ─────────────────────────────────────────────────────
main() {
    banner
    parse_args "$@"

    # Root check
    [[ $EUID -ne 0 ]] && warn "Some tools work best as root. Consider running with sudo."

    # Install only mode
    if [[ "$INSTALL_ONLY" == true ]]; then
        check_and_install
        log "All tools installed. Run recon with: sudo bash newrecon.sh -d target.com"
        exit 0
    fi

    # Pre-detect resume state BEFORE setup_dirs sets OUTPUT_DIR
    # We need to know if a checkpoint exists to show the right prompt
    local EXPECTED_DIR
    EXPECTED_DIR="${OUTPUT_DIR:-./recon_${TARGET}}"
    local EXPECTED_CKPT="$EXPECTED_DIR/.checkpoint"

    # Confirmation — skip prompt when auto-resuming (no need to ask again)
    if [[ -f "$EXPECTED_CKPT" && "$FRESH_START" == false ]]; then
        echo -e "${YELLOW}${BOLD}[!] Resuming scan for: $TARGET${NC}"
    else
        echo -e "${YELLOW}${BOLD}[!] Target: $TARGET${NC}"
        echo -e "${YELLOW}[!] Ensure this domain is in your bug bounty program's scope!${NC}"
        read -rp "Continue? (y/N): " confirm
        [[ "${confirm,,}" != "y" ]] && { info "Aborted."; exit 0; }
    fi

    setup_dirs
    check_and_install

    local START=$(date +%s)

    # ── Resume-aware phase execution ──────────────────────────
    # Each phase is skipped if it was already completed in a
    # previous run (detected via the .checkpoint file).
    # Use --fresh to restart from scratch.

    if phase_done "phase1"; then
        log "[SKIP] Phase 1 already completed — skipping subdomain enum"
    else
        phase1_subdomains
    fi

    if phase_done "phase2"; then
        log "[SKIP] Phase 2 already completed — skipping DNS recon"
    else
        phase2_dns
    fi

    if phase_done "phase3"; then
        log "[SKIP] Phase 3 already completed — skipping port scan"
    else
        phase3_ports
    fi

    if phase_done "phase4"; then
        log "[SKIP] Phase 4 already completed — skipping tech fingerprint"
    else
        phase4_tech
    fi

    if phase_done "phase5"; then
        log "[SKIP] Phase 5 already completed — skipping WAF detection"
    else
        phase5_waf
    fi

    if phase_done "phase6"; then
        log "[SKIP] Phase 6 already completed — skipping endpoint discovery"
    else
        phase6_endpoints
    fi

    if phase_done "phase7"; then
        log "[SKIP] Phase 7 already completed — skipping JS analysis"
    else
        phase7_js
    fi

    if phase_done "phase8"; then
        log "[SKIP] Phase 8 already completed — skipping param discovery"
    else
        phase8_params
    fi

    if phase_done "phase9"; then
        log "[SKIP] Phase 9 already completed — skipping cloud recon"
    else
        phase9_cloud
    fi

    if phase_done "phase10"; then
        log "[SKIP] Phase 10 already completed — skipping vuln scan"
    else
        phase10_vulns
    fi

    if phase_done "phase11"; then
        log "[SKIP] Phase 11 already completed — skipping secrets hunt"
    else
        phase11_secrets
    fi

    if phase_done "phase12"; then
        log "[SKIP] Phase 12 already completed — skipping screenshots"
    else
        phase12_screenshots
    fi

    # Report is always regenerated (idempotent, uses existing data)
    generate_report

    if phase_done "phase13"; then
        log "[SKIP] Phase 13 already completed — skipping feroxbuster"
    else
        phase_ferox_all   # ← LAST: time-intensive, runs on ALL subdomains
    fi

    local END=$(date +%s)
    local ELAPSED=$((END - START))
    log "Total time: $((ELAPSED/60))m $((ELAPSED%60))s"
}

main "$@"
