#!/usr/bin/env bash
# ============================================================================
# Nmap Reconnaissance Workflow
# Author: ThawSitt
# Purpose: Sequential TCP discovery, service enumeration, and full-port scan.
# Usage:   sudo ./recon-nmap.sh <IPv4-address>
#
# Use only against systems you own or are explicitly authorized to assess.
# ============================================================================

set -u
set -o pipefail

SCRIPT_NAME="${0##*/}"
TARGET=""
NMAP_PATH=""
OUTPUT_DIR=""
HOST_TIMEOUT="30m"
SCAN_TYPE="-sS"
NMAP_OPTIONS=()

# ------------------------------- Colors ------------------------------------
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'
    RESET=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

info()    { printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()    { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"; }
error()   { printf '%s[-]%s %s\n' "$RED" "$RESET" "$*" >&2; }
section() { printf '\n%s========== %s ==========%s\n' "$BLUE" "$*" "$RESET"; }

usage() {
    cat <<USAGE
Usage:
  sudo ./$SCRIPT_NAME <IPv4-address>

Example:
  sudo ./$SCRIPT_NAME 192.0.2.10

The script performs sequential TCP scans:
  1. Fast scan of common TCP ports
  2. Service/version detection and default scripts on discovered ports
  3. Full TCP port scan (1-65535)
  4. Service/version detection on newly discovered ports

Use only with explicit authorization.
USAGE
}

# ------------------------------- Validation -------------------------------
valid_ipv4() {
    local ip="$1" octet
    local -a parts

    [[ "$ip" =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
    IFS='.' read -r -a parts <<< "$ip"
    [[ ${#parts[@]} -eq 4 ]] || return 1

    for octet in "${parts[@]}"; do
        # Avoid ambiguous octal-looking forms such as 010.
        [[ "$octet" == "0" || ! "$octet" =~ ^0[0-9]+$ ]] || return 1
        (( 10#$octet >= 0 && 10#$octet <= 255 )) || return 1
    done
    return 0
}

valid_positive_number() {
    [[ "$1" =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] &&
        awk -v n="$1" 'BEGIN { exit !(n > 0) }'
}

valid_timeout() {
    [[ "$1" =~ ^[1-9][0-9]*(ms|s|m|h|d)?$ ]]
}

# ------------------------------- Pre-flight --------------------------------
preflight() {
    if (( EUID != 0 )); then
        error "Run this script with root privileges: sudo ./$SCRIPT_NAME <IPv4>"
        return 1
    fi

    NMAP_PATH="$(command -v nmap 2>/dev/null || true)"
    if [[ -z "$NMAP_PATH" ]]; then
        error "Nmap was not found. Install it with: sudo apt install nmap"
        return 1
    fi

    if [[ $# -ne 1 ]]; then
        usage
        return 1
    fi

    TARGET="$1"
    if ! valid_ipv4 "$TARGET"; then
        error "Invalid IPv4 address: $TARGET"
        return 1
    fi

    info "Nmap found: $NMAP_PATH"
    info "Running with root privileges."
    info "Target validation passed: $TARGET"
}

# ------------------------------- Configuration ----------------------------
choose_profile() {
    local choice timing rate parallelism

    section "SCAN CONFIGURATION"
    printf 'Select scanning speed:\n'
    printf '  1) Slow       (-T2)\n'
    printf '  2) Normal     (-T3)\n'
    printf '  3) Fast       (-T4)\n'
    printf '  4) Custom     (choose timing and optional limits)\n'

    while true; do
        read -r -p "Choice [1-4]: " choice
        case "$choice" in
            1) NMAP_OPTIONS=(-T2); break ;;
            2) NMAP_OPTIONS=(-T3); break ;;
            3) NMAP_OPTIONS=(-T4); break ;;
            4)
                printf '\nTiming templates:\n'
                printf '  -T0  Paranoid  - extremely slow\n'
                printf '  -T1  Sneaky    - very slow\n'
                printf '  -T2  Polite    - slower, less network impact\n'
                printf '  -T3  Normal    - Nmap default\n'
                printf '  -T4  Aggressive- faster; assumes a reliable network\n'
                printf '  -T5  Insane    - very aggressive; may reduce accuracy\n'
                while true; do
                    read -r -p "Timing template [0-5 or T0-T5]: " timing
                    timing="${timing,,}"
                    timing="${timing#-t}"
                    timing="${timing#t}"
                    if [[ "$timing" =~ ^[0-5]$ ]]; then
                        NMAP_OPTIONS=("-T$timing")
                        break
                    fi
                    warn "Enter a value from 0 to 5 (for example, T3)."
                done

                while true; do
                    read -r -p "Maximum probe rate (optional, blank to skip): " rate
                    if [[ -z "$rate" ]]; then
                        break
                    elif valid_positive_number "$rate"; then
                        NMAP_OPTIONS+=(--max-rate "$rate")
                        break
                    fi
                    warn "Enter a positive number, such as 100 or 25.5, or leave blank."
                done

                while true; do
                    read -r -p "Maximum parallelism (optional, blank to skip): " parallelism
                    if [[ -z "$parallelism" ]]; then
                        break
                    elif [[ "$parallelism" =~ ^[1-9][0-9]*$ ]]; then
                        NMAP_OPTIONS+=(--max-parallelism "$parallelism")
                        break
                    fi
                    warn "Enter a positive whole number or leave blank."
                done
                break
                ;;
            *) warn "Invalid choice. Select 1, 2, 3, or 4." ;;
        esac
    done

    section "TCP SCANNING TECHNIQUE"
    printf 'Choose the TCP scanning technique:\n'
    printf '  1) SYN scan         (-sS) - sends SYN probes without completing the handshake\n'
    printf '  2) TCP Connect scan (-sT) - completes the TCP connection using the OS connect() call\n'

    while true; do
        read -r -p "Scanning technique [1-2, default: 1]: " choice
        choice="${choice:-1}"
        case "$choice" in
            1) SCAN_TYPE="-sS"; break ;;
            2) SCAN_TYPE="-sT"; break ;;
            *) warn "Invalid choice. Select 1 or 2." ;;
        esac
    done

    while true; do
        read -r -p "Per-host timeout [default: 30m]: " HOST_TIMEOUT
        HOST_TIMEOUT="${HOST_TIMEOUT:-30m}"
        if valid_timeout "$HOST_TIMEOUT"; then
            break
        fi
        warn "Use a positive duration such as 30m, 600s, or 1h."
    done

    NMAP_OPTIONS+=(--host-timeout "$HOST_TIMEOUT")
    info "Nmap options: ${NMAP_OPTIONS[*]}"
    info "Per-host timeout: $HOST_TIMEOUT (applies to each Nmap run, not the whole workflow)"
}

# ------------------------------- Output setup ------------------------------
setup_output_directory() {
    local working_dir output_root timestamp candidate newest_dir newest_mtime
    local choice
    local -a existing_dirs=()

    # Save results beneath the directory from which the user launched the script.
    working_dir="$(pwd -P)" || {
        error "Could not determine the current working directory."
        return 1
    }

    output_root="$working_dir/nmap-scans"
    if ! mkdir -p "$output_root"; then
        error "Could not create output directory: $output_root"
        return 1
    fi

    # Find previous result directories for this exact target.
    for candidate in "$output_root/$TARGET" "$output_root/${TARGET}_"*; do
        if [[ -d "$candidate" ]]; then
            existing_dirs+=("$candidate")
        fi
    done

    if (( ${#existing_dirs[@]} > 0 )); then
        section "EXISTING SCAN RESULTS"
        printf 'Existing result directories for %s were found:\n' "$TARGET"
        printf '  %s\n' "${existing_dirs[@]}"
        printf '\n'
        printf 'Choose what to do:\n'
        printf '  1) Keep    - preserve existing results and create a new directory\n'
        printf '  2) Discard - delete all existing results for this target, then create a new directory\n'
        printf '  3) Override - clear the most recently modified result directory and reuse it\n'
        printf '  4) Cancel  - exit without changing existing results\n'

        while true; do
            read -r -p "Choice [1-4]: " choice
            case "$choice" in
                1)
                    info "Keeping all existing scan results."
                    break
                    ;;
                2)
                    read -r -p "Delete ALL listed result directories for $TARGET? [y/N]: " choice
                    case "$choice" in
                        y|Y|yes|YES)
                            if ! rm -rf -- "${existing_dirs[@]}"; then
                                error "Could not remove the existing result directories."
                                return 1
                            fi
                            info "Existing results discarded."
                            break
                            ;;
                        *)
                            warn "Discard cancelled. Choose an option again."
                            ;;
                    esac
                    ;;
                3)
                    newest_dir=""
                    newest_mtime=-1
                    for candidate in "${existing_dirs[@]}"; do
                        local candidate_mtime
                        candidate_mtime="$(stat -c '%Y' -- "$candidate" 2>/dev/null)" || candidate_mtime=0
                        if (( candidate_mtime > newest_mtime )); then
                            newest_mtime="$candidate_mtime"
                            newest_dir="$candidate"
                        fi
                    done

                    if [[ -z "$newest_dir" ]]; then
                        error "Could not identify an existing result directory to override."
                        return 1
                    fi

                    printf 'The directory to override is:\n  %s\n' "$newest_dir"
                    read -r -p "Delete its contents and reuse it? [y/N]: " choice
                    case "$choice" in
                        y|Y|yes|YES)
                            if ! find "$newest_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; then
                                error "Could not clear the selected result directory."
                                return 1
                            fi
                            OUTPUT_DIR="$newest_dir"
                            info "Selected result directory cleared and will be reused."
                            info "Other existing result directories were preserved."
                            info "Results directory: $OUTPUT_DIR"
                            return 0
                            ;;
                        *)
                            warn "Override cancelled. Choose an option again."
                            ;;
                    esac
                    ;;
                4)
                    info "Scan cancelled. Existing results were not changed."
                    return 1
                    ;;
                *)
                    warn "Invalid choice. Select 1, 2, 3, or 4."
                    ;;
            esac
        done
    fi

    # Create a fresh, unique directory for a new scan (or after discard/keep).
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    OUTPUT_DIR="$(mktemp -d "$output_root/${TARGET}_${timestamp}_XXXXXX")" || {
        error "Could not create a unique scan directory."
        return 1
    }

    info "Results directory: $OUTPUT_DIR"
}

# ------------------------------- Scan helpers ------------------------------
run_scan() {
    local label="$1"
    shift
    local base="$OUTPUT_DIR/$label"
    local -a command_args

    command_args=("${NMAP_OPTIONS[@]}" "$SCAN_TYPE" "$@" -oA "$base" "$TARGET")

    section "$label"
    printf '[+] Command: %q ' "$NMAP_PATH"
    printf '%q ' "${command_args[@]}"
    printf '\n'

    "$NMAP_PATH" "${command_args[@]}"
    local status=$?

    if (( status != 0 )); then
        error "Nmap exited with status $status during $label."
        return "$status"
    fi

    if [[ ! -s "$base.gnmap" || ! -s "$base.xml" || ! -s "$base.nmap" ]]; then
        error "One or more Nmap output files are missing or empty for $label."
        return 1
    fi

    # Check that Nmap wrote a normally completed XML document.
    if ! grep -Eq '<finished[^>]*exit="success"' "$base.xml" ||
       ! grep -q '</nmaprun>' "$base.xml"; then
        error "Nmap XML does not show a normally completed scan for $label."
        return 1
    fi

    info "Nmap process completed and output files were validated."
}

# Extract only open TCP ports from Nmap's grepable output.
extract_tcp_ports() {
    local gnmap_file="$1"

    awk '
        /Ports: / {
            line = $0
            sub(/^.*Ports: /, "", line)
            count = split(line, entries, ",")
            for (i = 1; i <= count; i++) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", entries[i])
                split(entries[i], fields, "/")
                if (fields[2] == "open" && fields[3] == "tcp") {
                    print fields[1]
                }
            }
        }
    ' "$gnmap_file" | sort -n -u | paste -sd, -
}

host_is_up() {
    local xml_file="$1"
    # Nmap XML represents host status as a status element with state="up".
    grep -Eq '<status[[:space:]][^>]*state="up"' "$xml_file"
}

# ------------------------------- Workflow ----------------------------------
main() {
    local initial_ports full_ports new_ports initial_xml
    local -a full_array initial_array

    preflight "$@" || return 1
    choose_profile
    setup_output_directory || return 1
    initial_xml="$OUTPUT_DIR/01-initial-scan.xml"

    section "STAGE 1 - INITIAL TCP SCAN"
    if ! run_scan "01-initial-scan" -F; then
        error "Initial scan failed. Stopping workflow."
        return 1
    fi

    if ! host_is_up "$initial_xml"; then
        error "Nmap did not identify the target as up during host discovery."
        warn "This does not prove the target is offline; host discovery may be filtered."
        warn "If authorized, rerun with -Pn added to the scan options to skip host discovery."
        return 1
    fi
    info "Target is up."

    initial_ports="$(extract_tcp_ports "$OUTPUT_DIR/01-initial-scan.gnmap")"
    if [[ -n "$initial_ports" ]]; then
        info "Open TCP ports from initial scan: $initial_ports"
        section "STAGE 2 - SERVICE ENUMERATION (INITIAL PORTS)"
        if ! run_scan "02-initial-services" -sV -sC -p "$initial_ports"; then
            error "Initial service enumeration failed. Stopping workflow."
            return 1
        fi
    else
        warn "No open TCP ports were found in the initial scan."
    fi

    section "STAGE 3 - FULL TCP PORT SCAN"
    if ! run_scan "03-full-tcp-scan" -p-; then
        error "Full TCP scan failed. Stopping workflow."
        return 1
    fi

    full_ports="$(extract_tcp_ports "$OUTPUT_DIR/03-full-tcp-scan.gnmap")"
    if [[ -z "$full_ports" ]]; then
        warn "The full TCP scan did not report any open TCP ports."
        full_ports=""
    fi

    # Compare comma-separated port lists without relying on grep patterns.
    new_ports=""
    if [[ -n "$full_ports" ]]; then
        local port
        IFS=',' read -r -a full_array <<< "$full_ports"
        IFS=',' read -r -a initial_array <<< "$initial_ports"
        for port in "${full_array[@]}"; do
            if [[ ",$initial_ports," != *",$port,"* ]]; then
                if [[ -n "$new_ports" ]]; then
                    new_ports+="," 
                fi
                new_ports+="$port"
            fi
        done
    fi

    if [[ -n "$new_ports" ]]; then
        info "New TCP ports found by full scan: $new_ports"
        section "STAGE 4 - SERVICE ENUMERATION (NEW PORTS)"
        if ! run_scan "04-new-port-services" -sV -sC -p "$new_ports"; then
            error "New-port service enumeration failed."
            return 1
        fi
    else
        info "No additional TCP ports were discovered beyond the initial scan."
    fi

    section "SCAN SUMMARY"
    printf 'Target:                  %s\n' "$TARGET"
    printf 'Initial open TCP ports:  %s\n' "${initial_ports:-None found}"
    printf 'Full-scan open TCP ports:%s\n' " ${full_ports:-None found}"
    printf 'New TCP ports:           %s\n' "${new_ports:-None}"
    printf 'Results directory:       %s\n' "$OUTPUT_DIR"
    printf '\nOutput formats:\n'
    printf '  *.nmap   Human-readable output\n'
    printf '  *.gnmap  Grepable output (used to extract ports)\n'
    printf '  *.xml    Structured output (used to validate host status)\n'
    warn "This workflow scans TCP only; it does not scan UDP ports."
    warn "A successful Nmap exit does not guarantee every probe received a response."
    info "Workflow completed."
}

main "$@"
