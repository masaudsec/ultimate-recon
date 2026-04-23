# ultimate_recon.sh

A fully automated bug bounty recon script for Kali Linux. One command maps an entire target's attack surface — subdomain enumeration, port scanning, JS analysis, cloud asset discovery, vulnerability scanning, and more — across 13 sequential phases with checkpoint/resume support.

Built and maintained by [masaudsec](https://github.com/masaudsec).



## What it does

The script runs 13 phases against a target domain:

| Phase | Name | Description |
|-||-|
| 1 | Subdomain Enumeration | 12 passive sources + active DNS bruteforce + HTTP probing |
| 2 | DNS Deep Recon | Zone transfers, SPF/DMARC, ASN lookup, reverse DNS |
| 3 | Port Scanning | Naabu fast scan + Nmap service detection + Shodan API |
| 4 | Tech Fingerprinting | httpx bulk detection + WhatWeb + response header analysis |
| 5 | WAF Detection | wafw00f + header-based fingerprinting + origin IP discovery |
| 6 | Endpoint Discovery | GAU, Wayback, Katana, Hakrawler — merged and deduplicated |
| 7 | JavaScript Analysis | LinkFinder + SecretFinder + custom regex for keys/tokens |
| 8 | Parameter Discovery | Arjun + ParamSpider + SSRF/IDOR/XSS param categorization |
| 9 | Cloud Recon | S3, GCS, Azure Blob, Firebase — public access checks |
| 10 | Vulnerability Scanning | Nuclei CVEs + CORS + exposed paths + security headers |
| 11 | Secrets Hunting | TruffleHog on GitHub + exposed .git + Google Dorks |
| 12 | Screenshots | Headless Chromium on all live hosts |
| — | Report | Auto-generated markdown report with all findings |
| 13 | Feroxbuster | Directory fuzzing on every live subdomain (runs last) |



## Requirements

- Kali Linux (recommended) or any Debian-based distro
- Go 1.22+
- Python 3
- Root or sudo access
- Internet connection for tool installation and OSINT sources

The script handles all tool installation automatically via the --install flag. You do not need to manually install anything.



## Installation

Clone the repository:

git clone https://github.com/masaudsec/ultimate_recon.git
cd ultimate_recon
chmod +x ultimate_recon.sh


Install all required tools (run once):

sudo bash ultimate_recon.sh --install


This installs: subfinder, httpx, nuclei, dnsx, katana, naabu, ffuf, gau, assetfinder, waybackurls, alterx, tlsx, hakrawler, puredns, massdns, findomain, feroxbuster, arjun, dirsearch, trufflehog, dnsrecon, LinkFinder, SecretFinder, ParamSpider, nmap, masscan, nikto, wafw00f, whatweb, gobuster, dirb, seclists, and more.



## Usage

Basic scan:

sudo bash ultimate_recon.sh -d target.com


Full options:

sudo bash ultimate_recon.sh -d target.com [OPTIONS]


| Flag | Description | Default |
||-||
| -d <domain> | Target domain (required) | — |
| -o <dir> | Output directory | ./recon_<domain> |
| -t <threads> | Thread count | 50 |
| -w <wordlist> | Custom wordlist path | dirb/common.txt |
| --deep | Enable deep scan (Nikto + extended) | off |
| --passive | Passive recon only, no active scanning | off |
| --install | Install all tools and exit | — |
| --fresh | Ignore checkpoint, start from scratch | off |
| -h | Show help | — |



## Examples

Standard scan:

sudo bash ultimate_recon.sh -d example.com

Deep scan with more threads:

sudo bash ultimate_recon.sh -d example.com --deep -t 100


Passive only (no active probing):

sudo bash ultimate_recon.sh -d example.com --passive

Custom output directory and wordlist:

sudo bash ultimate_recon.sh -d example.com -o /root/results -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt

Force fresh restart (ignore previous checkpoint):

sudo bash ultimate_recon.sh -d example.com --fresh



## Resume / Checkpoint System

The script saves progress after each completed phase to ./recon_<domain>/.checkpoint. If your scan is interrupted (network drop, system sleep, manual Ctrl+C), simply re-run the same command:


sudo bash ultimate_recon.sh -d target.com


It will detect the previous run, display which phase was last completed, and resume from where it left off. Existing output files are reused — no data is lost and no phases are repeated.

To ignore the checkpoint and restart from scratch:


sudo bash ultimate_recon.sh -d target.com --fresh




## Output Structure

All results are saved to ./recon_<domain>/ by default:


recon_target.com/
├── subdomains/
│   ├── all_subdomains_raw.txt       # All collected subdomains (merged, deduped)
│   ├── resolved_clean.txt           # DNS-resolved subdomains
│   ├── live_200_only.txt            # 200 OK hosts only
│   ├── live_urls.txt                # All live hosts (200/301/302/401/403)
│   ├── live_401_auth_required.txt   # Auth-required endpoints
│   ├── live_403_forbidden.txt       # Forbidden endpoints (bypass targets)
│   └── tls_info.txt                 # TLS certificate data
├── dns/
│   ├── A_records.txt
│   ├── MX_records.txt
│   ├── TXT_records.txt
│   ├── NS_records.txt
│   ├── dnsrecon.json
│   └── zone_transfer_*.txt
├── ports/
│   ├── all_ports.txt
│   ├── nmap_full.*
│   ├── interesting_ports.txt
│   └── shodan_internetdb.json
├── tech/
│   ├── tech_bulk.txt
│   ├── interesting_headers.txt
│   └── cookies.txt
├── waf/
│   ├── waf_summary.txt
│   └── origin_ip_discovery.txt
├── endpoints/
│   ├── all_urls_clean.txt           # Deduplicated crawled URLs
│   ├── api_endpoints.txt
│   ├── admin_panels.txt
│   ├── sensitive_files.txt
│   ├── graphql_endpoints.txt
│   ├── urls_with_params.txt
│   ├── ferox_all/                   # Per-subdomain feroxbuster output
│   └── all_endpoints_master.txt     # Final merged endpoint list
├── js_analysis/
│   ├── js_urls.txt
│   ├── files/                       # Downloaded JS files
│   ├── linkfinder_endpoints.txt
│   ├── secrets_found.txt
│   └── manual_secrets.txt
├── params/
│   ├── all_params.txt
│   ├── ssrf_redirect_params.txt
│   ├── idor_params.txt
│   └── xss_sqli_params.txt
├── cloud/
│   ├── s3_buckets.txt
│   ├── gcs_buckets.txt
│   ├── azure_storage.txt
│   ├── firebase.txt
│   └── ssrf_targets.txt
├── vulnerabilities/
│   ├── nuclei_findings.txt
│   ├── subdomain_takeovers.txt
│   ├── cors_issues.txt
│   ├── sensitive_exposed.txt
│   ├── missing_security_headers.txt
│   ├── exposed_panels.txt
│   ├── misconfigs.txt
│   └── cves_found.txt
├── secrets/
│   ├── google_dorks.txt
│   ├── trufflehog_findings.json
│   └── exposed_git.txt
├── screenshots/
├── reports/
│   └── RECON_REPORT_<domain>.md     # Final report
└── recon.log                        # Full scan log




## Key Files for Manual Testing

After the scan completes, these are the files you want to open first:

- vulnerabilities/nuclei_findings.txt — automated vulnerability hits
- vulnerabilities/sensitive_exposed.txt — exposed .env, .git, config files
- vulnerabilities/cors_issues.txt — CORS misconfigurations
- js_analysis/secrets_found.txt — API keys, tokens found in JS
- js_analysis/manual_secrets.txt — regex-based secret matches
- endpoints/all_endpoints_master.txt — full endpoint list for Burp import
- params/ssrf_redirect_params.txt — pre-filtered SSRF/redirect params
- params/idor_params.txt — pre-filtered IDOR params
- cloud/s3_buckets.txt — public cloud bucket findings
- secrets/exposed_git.txt — exposed .git repositories
- subdomains/live_403_forbidden.txt — 403 bypass candidates
- subdomains/live_401_auth_required.txt — authentication bypass candidates



## Tools Used

Go-based:
subfinder, httpx, nuclei, dnsx, naabu, katana, gau, assetfinder, waybackurls, anew, uro, qsreplace, alterx, tlsx, hakrawler, puredns, ffuf, notify

System packages:
nmap, masscan, nikto, wafw00f, whatweb, dirb, gobuster, dnsutils, whois, curl, jq, seclists, chromium

Python-based:
arjun, dirsearch, trufflehog, dnsrecon

Git-cloned:
LinkFinder, SecretFinder, ParamSpider, massdns, findomain, feroxbuster



## Notes

- Run as root or with sudo. Several tools (masscan, nmap raw scans) require root privileges.
- The --passive mode skips all active scanning phases (ports, feroxbuster, nikto) and is safe to run without risk of triggering IDS alerts.
- Phase 13 (Feroxbuster) is intentionally placed last because it runs against every live subdomain and is the most time-intensive part of the scan.
- The all_endpoints_master.txt file is the single most useful output — it consolidates GAU, Wayback, Katana, Hakrawler, and Feroxbuster results into one deduplicated list, ready for Burp Suite import.
- Nuclei templates are updated automatically during each run.



## Legal

This tool is for authorized security testing only. Only use it against targets you have explicit written permission to test, or targets within the scope of a legitimate bug bounty program.

Unauthorized scanning is illegal in most jurisdictions. The author takes no responsibility for misuse.



## Author

masaudsec
- GitHub: [github.com/masaudsec](https://github.com/masaudsec)
- Website: masaudsec.com



## License

MIT License. See [LICENSE](LICENSE) for details.
