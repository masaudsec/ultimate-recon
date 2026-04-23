# ultimate_recon.sh

A fully automated bug bounty recon script for Kali Linux. One command maps an entire target's attack surface across 13 sequential phases — subdomain enumeration, port scanning, JS analysis, cloud asset discovery, vulnerability scanning, secrets hunting, and more.

Built and maintained by [masaudsec](https://github.com/masaudsec) | masaudsec.com



# What It Does

The script runs 13 phases against a target domain in sequence.

Phase 1 — Subdomain Enumeration
Pulls from 12 passive sources including Subfinder, Assetfinder, Findomain, crt.sh, AlienVault, Wayback Machine, URLScan, RapidDNS, HackerTarget, BufferOver, CommonCrawl, and OTX. Merges everything, deduplicates, then runs AlterX permutations, active DNS bruteforce via puredns or dnsx, full DNS resolution, and HTTP probing. Outputs separate lists for 200 OK, 401, 403, and redirect hosts.

Phase 2 — DNS Deep Recon
Zone transfer attempts, full record enumeration (A, AAAA, MX, TXT, CNAME, NS, SOA, SRV), SPF and DMARC checks, ASN and IP range discovery via whois and ipinfo, and reverse DNS lookup.

Phase 3 — Port Scanning
Naabu for fast full-port discovery, Nmap for service and version detection with banner grabbing, common interesting port checks, and Shodan InternetDB query for the target IP.

Phase 4 — Technology Fingerprinting
Bulk tech detection via httpx across all live hosts, detailed per-host fingerprinting via WhatWeb, HTTP response header collection, extraction of server and framework headers, and cookie flag analysis.

Phase 5 — WAF Detection
wafw00f against live hosts, header-based WAF fingerprinting, and origin IP discovery attempts via SecurityTrails, Shodan, and common subdomain DNS resolution.

Phase 6 — Endpoint Discovery
URL harvesting from GAU, Wayback Machine, Katana (JS-aware crawling), and Hakrawler. All sources merged and deduplicated with uro. Outputs categorized lists for API endpoints, admin panels, sensitive files, GraphQL endpoints, and parameterized URLs.

Phase 7 — JavaScript Analysis
Extracts all JS file URLs, downloads them, runs LinkFinder for endpoint extraction, runs SecretFinder for secret detection, and runs custom regex patterns hunting for API keys, AWS credentials, hardcoded passwords, private keys, emails, internal URLs, and GraphQL queries.

Phase 8 — Parameter Discovery
Extracts parameters from archived URLs, runs ParamSpider for parameter harvesting, runs Arjun for hidden parameter discovery on dynamic pages, then categorizes everything into SSRF/redirect params, IDOR params, and XSS/SQLi params.

Phase 9 — Cloud Asset Recon
Tests S3, GCS, and Azure Blob naming patterns derived from the target company name. Checks Firebase databases for public access. Documents SSRF metadata endpoints for manual testing.

Phase 10 — Vulnerability Scanning
Nuclei across all live hosts for critical/high/medium severity. Separate Nuclei runs for exposed panels, misconfigurations, and CVEs. Manual checks for 30+ sensitive paths including .git, .env, phpinfo, Swagger, Spring Actuator, and GraphQL. CORS misconfiguration testing. Security header analysis across all live hosts.

Phase 11 — Secrets Hunting
TruffleHog against the target organization on GitHub for verified secrets. Checks every live host for exposed .git directories. Generates a comprehensive Google Dorks list for manual browser recon.

Phase 12 — Screenshots
Headless Chromium screenshots of all live hosts saved as PNG files.

Report Generation
Auto-generated markdown report consolidating all findings with counts, summaries, and raw data sections.

Phase 13 — Feroxbuster Directory Fuzzing
Runs last because it is the most time-intensive. Feroxbuster runs against every single live subdomain using dirb/common.txt. All results are merged into a single all_endpoints_master.txt file alongside GAU, Wayback, Katana, and Hakrawler output.


# Requirements

- Kali Linux or any Debian-based distro
- Go 1.22 or higher
- Python 3
- Root or sudo access
- Active internet connection

All tools are installed automatically. You do not need to manually install anything before running the script.


# Installation

    git clone https://github.com/masaudsec/ultimate_recon.git
    cd ultimate_recon
    chmod +x ultimate_recon.sh
    sudo bash ultimate_recon.sh --install

The --install flag installs all required tools and exits. Run this once before your first scan.


# Usage

Basic scan:

    sudo bash ultimate_recon.sh -d target.com

Available options:

    -d  <domain>     Target domain — required
    -o  <dir>        Output directory — default: ./recon_<domain>
    -t  <threads>    Thread count — default: 50
    -w  <wordlist>   Custom wordlist path
    --deep           Enable deep scan, adds Nikto and extended checks
    --passive        Passive recon only, no active scanning
    --install        Install all tools and exit
    --fresh          Ignore checkpoint, restart from scratch
    -h               Show help


# Examples

Standard scan:

    sudo bash ultimate_recon.sh -d example.com

Deep scan with more threads:

    sudo bash ultimate_recon.sh -d example.com --deep -t 100

Passive only, no active probing:

    sudo bash ultimate_recon.sh -d example.com --passive

Custom output folder and wordlist:

    sudo bash ultimate_recon.sh -d example.com -o /root/results -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt

Force fresh restart, ignore previous checkpoint:

    sudo bash ultimate_recon.sh -d example.com --fresh


# Resume and Checkpoint System

The script saves progress after each completed phase to ./recon_<domain>/.checkpoint

If your scan is interrupted for any reason — network drop, system sleep, manual stop — simply re-run the exact same command. The script detects the previous run, shows which phase was last completed, and resumes from that point. No phases are repeated and no data is lost.

To force a full restart and ignore the checkpoint:

    sudo bash ultimate_recon.sh -d target.com --fresh


# Output Structure

All results are saved to ./recon_<domain>/ by default.

    recon_target.com/
    |
    |-- subdomains/
    |   |-- all_subdomains_raw.txt         All collected subdomains, merged and deduped
    |   |-- resolved_clean.txt             DNS-resolved subdomains only
    |   |-- live_200_only.txt              200 OK hosts
    |   |-- live_urls.txt                  All live hosts (200/301/302/401/403)
    |   |-- live_401_auth_required.txt     Auth-required endpoints
    |   |-- live_403_forbidden.txt         Forbidden endpoints, bypass targets
    |   `-- tls_info.txt                   TLS certificate data
    |
    |-- dns/
    |   |-- A_records.txt
    |   |-- MX_records.txt
    |   |-- TXT_records.txt
    |   |-- NS_records.txt
    |   |-- dnsrecon.json
    |   `-- zone_transfer_*.txt
    |
    |-- ports/
    |   |-- all_ports.txt
    |   |-- nmap_full.*
    |   |-- interesting_ports.txt
    |   `-- shodan_internetdb.json
    |
    |-- tech/
    |   |-- tech_bulk.txt
    |   |-- interesting_headers.txt
    |   `-- cookies.txt
    |
    |-- waf/
    |   |-- waf_summary.txt
    |   `-- origin_ip_discovery.txt
    |
    |-- endpoints/
    |   |-- all_urls_clean.txt             Deduplicated crawled URLs
    |   |-- api_endpoints.txt
    |   |-- admin_panels.txt
    |   |-- sensitive_files.txt
    |   |-- graphql_endpoints.txt
    |   |-- urls_with_params.txt
    |   |-- ferox_all/                     Per-subdomain feroxbuster output
    |   `-- all_endpoints_master.txt       Final merged endpoint list, use this for Burp
    |
    |-- js_analysis/
    |   |-- js_urls.txt
    |   |-- files/                         Downloaded JS files
    |   |-- linkfinder_endpoints.txt
    |   |-- secrets_found.txt
    |   `-- manual_secrets.txt
    |
    |-- params/
    |   |-- all_params.txt
    |   |-- ssrf_redirect_params.txt
    |   |-- idor_params.txt
    |   `-- xss_sqli_params.txt
    |
    |-- cloud/
    |   |-- s3_buckets.txt
    |   |-- gcs_buckets.txt
    |   |-- azure_storage.txt
    |   |-- firebase.txt
    |   `-- ssrf_targets.txt
    |
    |-- vulnerabilities/
    |   |-- nuclei_findings.txt
    |   |-- subdomain_takeovers.txt
    |   |-- cors_issues.txt
    |   |-- sensitive_exposed.txt
    |   |-- missing_security_headers.txt
    |   |-- exposed_panels.txt
    |   |-- misconfigs.txt
    |   `-- cves_found.txt
    |
    |-- secrets/
    |   |-- google_dorks.txt
    |   |-- trufflehog_findings.json
    |   `-- exposed_git.txt
    |
    |-- screenshots/
    |-- reports/
    |   `-- RECON_REPORT_<domain>.md       Final markdown report
    `-- recon.log                          Full scan log


# Key Files to Open After a Scan

These are the highest-value outputs to check first:

    vulnerabilities/nuclei_findings.txt       Automated vulnerability hits
    vulnerabilities/sensitive_exposed.txt     Exposed .env, .git, config files
    vulnerabilities/cors_issues.txt           CORS misconfigurations
    js_analysis/secrets_found.txt             API keys and tokens from JS files
    js_analysis/manual_secrets.txt            Regex-based secret matches
    endpoints/all_endpoints_master.txt        Full endpoint list, import directly into Burp
    params/ssrf_redirect_params.txt           Pre-filtered SSRF and open redirect params
    params/idor_params.txt                    Pre-filtered IDOR params
    params/xss_sqli_params.txt                Pre-filtered injection params
    cloud/s3_buckets.txt                      Public cloud bucket findings
    secrets/exposed_git.txt                   Exposed .git repositories
    subdomains/live_403_forbidden.txt         403 bypass candidates
    subdomains/live_401_auth_required.txt     Auth bypass candidates


# Tools Used

Go-based:
subfinder, httpx, nuclei, dnsx, naabu, katana, gau, assetfinder, waybackurls, anew, uro, qsreplace, alterx, tlsx, hakrawler, puredns, ffuf, notify

System packages:
nmap, masscan, nikto, wafw00f, whatweb, dirb, gobuster, dnsutils, whois, curl, jq, seclists, chromium

Python-based:
arjun, dirsearch, trufflehog, dnsrecon

Compiled or git-cloned:
LinkFinder, SecretFinder, ParamSpider, massdns, findomain, feroxbuster


# Notes

Run as root or with sudo. masscan and raw Nmap scans require root privileges.

The --passive flag skips all active scanning phases including port scanning, feroxbuster, and Nikto. Safe to run without triggering IDS alerts.

Phase 13 runs last intentionally. Feroxbuster against every subdomain is the most time-intensive part of the scan and would block everything else if run earlier.

The all_endpoints_master.txt file is the most useful single output. It consolidates results from GAU, Wayback Machine, Katana, Hakrawler, and Feroxbuster into one deduplicated list ready for Burp Suite import or manual review.

Nuclei templates are updated automatically on every run.


# Legal

This tool is for authorized security testing only. Only use it against targets you have explicit written permission to test, or targets explicitly listed in a bug bounty program scope.

Unauthorized scanning is illegal. The author is not responsible for any misuse.


# Author

masaudsec
GitHub: https://github.com/masaudsec
Website: masaudsec.com


# License

MIT License. See LICENSE file for details.
