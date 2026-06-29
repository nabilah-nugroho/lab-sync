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

 # Hitung statistik
    local count_missing=0
    local count_newer=0
    local count_older=0
    local count_same=0
    local count_dst_only=0

    # Cek file di direktori SUMBER
    echo -e "${BOLD}  [A] FILE DI SUMBER ($(basename "$SRC"))${NC}"
    echo -e "  $(printf '%-40s %-12s %-12s %s' 'Nama File' 'Ukuran' 'Dimodif.' 'Status')"
    echo -e "  $(printf '%.0s─' {1..75})"

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#$SRC/}"
        local dst_file="$DST/$rel_path"
        local src_size src_mtime status color

        src_size=$(stat -c%s "$src_file" 2>/dev/null || echo "0")
        src_mtime=$(stat -c%Y "$src_file" 2>/dev/null || echo "0")
        local src_mtime_hr
        src_mtime_hr=$(stat -c%y "$src_file" 2>/dev/null | cut -d'.' -f1 || echo "-")

        if [ ! -f "$dst_file" ]; then
            status="[HILANG di Tujuan]"
            color="$RED"
            ((count_missing++))
        else
            local dst_mtime
            dst_mtime=$(stat -c%Y "$dst_file" 2>/dev/null || echo "0")

            if [ "$src_mtime" -gt "$dst_mtime" ]; then
                status="[SUMBER LEBIH BARU]"
                color="$GREEN"
                ((count_newer++))
            elif [ "$src_mtime" -lt "$dst_mtime" ]; then
                status="[TUJUAN LEBIH BARU]"
                color="$YELLOW"
                ((count_older++))
            else
                status="[IDENTIK]"
                color="$BLUE"
                ((count_same++))
            fi
        fi

        local size_hr
        if [ "$src_size" -gt 1048576 ]; then
            size_hr="$(( src_size / 1048576 ))MB"
        elif [ "$src_size" -gt 1024 ]; then
            size_hr="$(( src_size / 1024 ))KB"
        else
            size_hr="${src_size}B"
        fi

        echo -e "  ${color}$(printf '%-40s %-12s %-22s %s' "$rel_path" "$size_hr" "$src_mtime_hr" "$status")${NC}"

    done < <(find "$SRC" -type f -print0 | sort -z)

 # Cek file yang ADA di tujuan tapi TIDAK di sumber
    echo ""
    echo -e "${BOLD}  [B] FILE HANYA ADA DI TUJUAN ($(basename "$DST"))${NC}"
    echo -e "  $(printf '%-40s %-12s %s' 'Nama File' 'Ukuran' 'Status')"
    echo -e "  $(printf '%.0s─' {1..60})"

    while IFS= read -r -d '' dst_file; do
        local rel_path="${dst_file#$DST/}"
        local src_check="$SRC/$rel_path"

        if [ ! -f "$src_check" ]; then
            local dst_size
            dst_size=$(stat -c%s "$dst_file" 2>/dev/null || echo "0")
            local size_hr
            if [ "$dst_size" -gt 1048576 ]; then
                size_hr="$(( dst_size / 1048576 ))MB"
            elif [ "$dst_size" -gt 1024 ]; then
                size_hr="$(( dst_size / 1024 ))KB"
            else
                size_hr="${dst_size}B"
            fi
            echo -e "  ${YELLOW}$(printf '%-40s %-12s %s' "$rel_path" "$size_hr" "[HANYA DI TUJUAN]")${NC}"
            ((count_dst_only++))
        fi
    done < <(find "$DST" -type f -print0 | sort -z)

    if [ "$count_dst_only" -eq 0 ]; then
        echo -e "  ${BLUE}(tidak ada file eksklusif di tujuan)${NC}"
    fi

    # Ringkasan
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════ RINGKASAN SCAN ════════════╗${NC}"
    echo -e "  ${GREEN}  ✓ File identik          : $count_same${NC}"
    echo -e "  ${GREEN}  ↑ Sumber lebih baru     : $count_newer${NC}"
    echo -e "  ${YELLOW}  ↓ Tujuan lebih baru     : $count_older${NC}"
    echo -e "  ${RED}  ✗ File hilang di tujuan : $count_missing${NC}"
    echo -e "  ${YELLOW}  ? Hanya ada di tujuan   : $count_dst_only${NC}"
    echo -e "  ${BLUE}  Total file di sumber    : $(find "$SRC" -type f | wc -l)${NC}"
    echo -e "  ${BLUE}  Total file di tujuan    : $(find "$DST" -type f | wc -l)${NC}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${NC}"

    # Simpan hasil ke variabel global untuk digunakan modul lain
    SCAN_MISSING=$count_missing
    SCAN_NEWER=$count_newer

    return 0
}

# FUNGSI: Cek apakah file sumber lebih baru dari tujuan
# Return : 0 jika lebih baru, 1 jika tidak
is_source_newer() {
    local src_file="$1"
    local dst_file="$2"

    if [ ! -f "$dst_file" ]; then
        return 0  # File tujuan tidak ada → anggap perlu disalin
    fi

    local src_mtime dst_mtime
    src_mtime=$(stat -c%Y "$src_file" 2>/dev/null || echo "0")
    dst_mtime=$(stat -c%Y "$dst_file" 2>/dev/null || echo "0")

    [ "$src_mtime" -gt "$dst_mtime" ]
}

# FUNGSI: Dapatkan daftar file yang perlu disinkronisasi
get_files_to_sync() {
    local SRC="$1"
    local DST="$2"
    local -a files_to_copy=()

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#$SRC/}"
        local dst_file="$DST/$rel_path"

        if [ ! -f "$dst_file" ] || is_source_newer "$src_file" "$dst_file"; then
            files_to_copy+=("$rel_path")
        fi
    done < <(find "$SRC" -type f -print0)

    printf '%s\n' "${files_to_copy[@]}"
}
