#!/bin/bash

# MODUL 5 : RIWAYAT SINKRONISASI
# File    : 05_history.sh
# Author  : Jelli (History Manager)
# Desc    : Menyimpan dan menampilkan riwayat sinkronisasi

RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
CYAN=${CYAN:-'\033[0;36m'}
BOLD=${BOLD:-'\033[1m'}
NC=${NC:-'\033[0m'}

SCRIPT_DIR_HIST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_ROOT="${LOG_DIR:-$SCRIPT_DIR_HIST/logs}"
HISTORY_FILE="$LOG_ROOT/sync_history.log"
MAX_HISTORY_LINES=1000 #batas maksimal baris sebelum log dirotasi

# FUNGSI UTAMA : log_history
# Desc         : Mencatat satu entri ke file history global,
#                lalu menampilkan pesan berwarna di terminal
# Parameter    : $1 = tipe (START/END/SYNC/ERROR/BACKUP/WARNING/INFO)
#              $2 = isi pesan
#              $3 = file log sesi tambahan(opsional)

log_history() {
    local TYPE="$1"
    local MESSAGE="$2"
    local SESSION_LOG="${3:-}"

    mkdir -p "$LOG_ROOT" #buat folder log kalau belum ada

    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    # Susun satu baris entri log lengkap dengan waktu, PID, tipe, dan pesan
    local LOG_ENTRY="[$TIMESTAMP] [$$] [$TYPE] $MESSAGE"

    echo "$LOG_ENTRY" >> "$HISTORY_FILE" #simpan ke file history utama 

    if [ -n "$SESSION_LOG" ]; then
        echo "$LOG_ENTRY" >> "$SESSION_LOG"
    fi

    rotate_log_if_needed

    case "$TYPE" in
        START)   echo -e "${BOLD}${GREEN}[HISTORY] ▶ $MESSAGE${NC}" ;;
        END)     echo -e "${BOLD}${GREEN}[HISTORY] ■ $MESSAGE${NC}" ;;
        SYNC)    echo -e "${BLUE}[HISTORY] ↔ $MESSAGE${NC}" ;;
        ERROR)   echo -e "${RED}[HISTORY] ✗ $MESSAGE${NC}" ;;
        BACKUP)  echo -e "${CYAN}[HISTORY] ⊞ $MESSAGE${NC}" ;;
        WARNING) echo -e "${YELLOW}[HISTORY] ⚠ $MESSAGE${NC}" ;;
        INFO)    echo -e "${BLUE}[HISTORY] ℹ $MESSAGE${NC}" ;;
        *)       echo -e "${NC}[HISTORY] $MESSAGE${NC}" ;;
    esac
}

# FUNGSI: show_history
# Desc  :menampilkan  Menu untuk melihat riwayat

show_history() {
    mkdir -p "$LOG_ROOT"

    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        RIWAYAT SINKRONISASI LAB              ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${NC}"

    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        echo -e "\n  ${YELLOW}Belum ada riwayat sinkronisasi.${NC}"
        return 0
    fi

    local total
    total=$(wc -l < "$HISTORY_FILE")
    echo -e "  ${BLUE}File log : $HISTORY_FILE${NC}"
    echo -e "  ${BLUE}Total    : $total entri${NC}\n"

    echo -e "  ${BOLD}Pilih tampilan:${NC}"
    echo -e "  ${YELLOW}1.${NC} 20 riwayat terbaru"
    echo -e "  ${YELLOW}2.${NC} 50 riwayat terbaru"
    echo -e "  ${YELLOW}3.${NC} Semua riwayat"
    echo -e "  ${YELLOW}4.${NC} Cari berdasarkan tanggal"
    echo -e "  ${YELLOW}5.${NC} Tampilkan hanya ERROR"
    echo -e "  ${YELLOW}6.${NC} Tampilkan hanya SYNC"
    echo -e "  ${YELLOW}7.${NC} Ekspor ke file teks"
    echo -ne "\n  Pilihan [1-7]: "
    read -r hist_choice

    echo ""
    _print_header

    #jalankan fungsi sesuai pilihan pengguna
    case "$hist_choice" in
        1) show_history_lines 20 ;;
        2) show_history_lines 50 ;;
        3) show_history_lines 0 ;;
        4)
            echo -ne "  Masukkan tanggal (YYYY-MM-DD): "
            read -r search_date
            grep_history "$search_date"
            ;;
        5) grep_history "ERROR" ;;
        6) grep_history "SYNC" ;;
        7) export_history ;;
        *) show_history_lines 20 ;;
    esac
}

# FUNGSI INTERNAL: _print_header
# Desc : Cetak header tabel log

_print_header() {
    echo -e "  ${BOLD}$(printf '%-21s %-7s %-10s %s' 'WAKTU' 'PID' 'TIPE' 'PESAN')${NC}"
    echo -e "  $(printf '%.0s─' {1..72})"
}

# FUNGSI: show_history_lines
# desc     : Menampilkan N baris terakhir dari file history
# Parameter : $1 = jumlah baris (0 = semua)

show_history_lines() {
    local N="$1"
    local lines

    if [ "$N" -eq 0 ]; then
        lines=$(cat "$HISTORY_FILE")
    else
        lines=$(tail -n "$N" "$HISTORY_FILE")
    fi

    local count=0
    while IFS= read -r line; do
        _format_line "$line"
        ((count++))
    done <<< "$lines"

    echo ""
    echo -e "  ${BLUE}Ditampilkan: $count entri${NC}"
}

# FUNGSI     : grep_history
# Desc       : Mencari dan menampilkan baris log yang cocok
#             dengan kata kunci tertentu
# Parameter  : $1 = kata kunci penjarian

grep_history() {
    local KEYWORD="$1"

    if [ ! -f "$HISTORY_FILE" ]; then
        echo -e "  ${YELLOW}Belum ada history.${NC}"
        return 0
    fi

    echo -e "  ${YELLOW}Mencari: '$KEYWORD'...${NC}\n"
    _print_header

    local count=0
    while IFS= read -r line; do
        if echo "$line" | grep -qi "$KEYWORD"; then
            _format_line "$line"
            ((count++))
        fi
    done < "$HISTORY_FILE"

    echo ""
    echo -e "  ${BLUE}Ditemukan: $count hasil${NC}"
}

# FUNGSI: export_history
# Desc  : Ekspor history ke file teks

export_history() {
    local EXPORT_FILE="$LOG_ROOT/history_export_$(date '+%Y%m%d_%H%M%S').txt"

    if cp "$HISTORY_FILE" "$EXPORT_FILE" 2>/dev/null; then
        echo -e "\n  ${GREEN}✓ History berhasil diekspor${NC}"
        echo -e "  ${BLUE}File : $EXPORT_FILE${NC}"
    else
        echo -e "\n  ${RED}✗ Gagal mengekspor history${NC}"
        return 1
    fi
}

# FUNGSI: rotate_log_if_needed
# Desc  : Mengarsipkan log lama dan memotong file history
#         kalau jumlah barisnya sudah melebihi batas

rotate_log_if_needed() {
    [ ! -f "$HISTORY_FILE" ] && return 0

    local line_count
    line_count=$(wc -l < "$HISTORY_FILE")

    if [ "$line_count" -gt "$MAX_HISTORY_LINES" ]; then
        local ARCHIVE="$LOG_ROOT/history_$(date '+%Y%m%d_%H%M%S').log.bak"
        cp "$HISTORY_FILE" "$ARCHIVE"

        local keep=$(( MAX_HISTORY_LINES / 2 ))
        tail -n "$keep" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
        mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$$] [INFO] Log dirotasi. Arsip: $(basename "$ARCHIVE")" >> "$HISTORY_FILE"
    fi
}

# FUNGSI INTERNAL: _format_line
# Desc  : Warnai satu baris log untuk ditampilkan

_format_line() {
    local LINE="$1"

    # Format log: [YYYY-MM-DD HH:MM:SS] [PID] [TYPE] message
    local timestamp pid type message

    timestamp=$(echo "$LINE" | cut -d']' -f1 | tr -d '[')
    pid=$(echo "$LINE" | cut -d']' -f2 | tr -d ' [')
    type=$(echo "$LINE" | cut -d']' -f3 | tr -d ' [')
    message=$(echo "$LINE" | cut -d']' -f4- | sed 's/^ //')

    local color
    case "$type" in
        START|END)   color="$GREEN" ;;
        SYNC)        color="$BLUE" ;;
        ERROR)       color="$RED" ;;
        BACKUP)      color="$CYAN" ;;
        WARNING)     color="$YELLOW" ;;
        *)           color="$NC" ;;
    esac

    printf "  ${color}%-21s %-7s %-10s %s${NC}\n" "$timestamp" "$pid" "$type" "$message"
}
