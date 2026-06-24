#!/bin/bash
# MODUL 1 : SCANNER DUA DIREKTORI
# File    : 01_scanner.sh
# Author  : Attar (Scanner & Comparator)
# Desc    : Membandingkan dua direktori, menentukan file
#           mana yang lebih baru, lebih lama, atau hilang

# Warna (fallback jika belum didefinisikan)
RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
CYAN=${CYAN:-'\033[0;36m'}
BOLD=${BOLD:-'\033[1m'}
NC=${NC:-'\033[0m'}

# FUNGSI UTAMA: scan_directories
# Parameter  : $1 = direktori sumber, $2 = direktori tujuan
scan_directories() {
    local SRC="$1"
    local DST="$2"

    # Validasi parameter
    if [ -z "$SRC" ] || [ -z "$DST" ]; then
        echo -e "${RED}[SCANNER] ERROR: Path direktori tidak boleh kosong!${NC}"
        return 1
    fi
    if [ ! -d "$SRC" ]; then
        echo -e "${RED}[SCANNER] ERROR: Direktori sumber '$SRC' tidak ditemukan!${NC}"
        return 1
    fi
    if [ ! -d "$DST" ]; then
        echo -e "${YELLOW}[SCANNER] Direktori tujuan '$DST' belum ada.${NC}"
        return 1
    fi

    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          HASIL SCAN DIREKTORI                ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo -e "  ${BLUE}Sumber  : $SRC${NC}"
    echo -e "  ${BLUE}Tujuan  : $DST${NC}"
    echo -e "  ${BLUE}Waktu   : $(date '+%d-%m-%Y %H:%M:%S')${NC}"
    echo ""
