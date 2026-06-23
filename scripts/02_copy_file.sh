#!/bin/bash

# MODUL 2: SALIN FILE YANG BELUM TERSEDIA / LEBIH BARU
# File: 02_copy_file.sh
# Autho: Nabilah (File Copier)
# Desc: Menyalin file yang belum ada di tujuan atau memperbarui file yang lebih baru dari sumber

RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
CYAN=${CYAN:-'\033[0;36m'}
BOLD=${BOLD:-'\033[1m'}
NC=${NC:-'\033[0m'}

# copy_missing_files
# Parameter: $1 = direktori sumber, $2 = direktori tujuan
# Desc: Menyalin file yang hilang ATAU lebih baru
copy_missing_files() {
    local SRC="$1"
    local DST="$2"

    if [ -z "$SRC" ] || [ -z "$DST" ]; then
        echo -e "${RED}[COPY] ERROR: Path tidak boleh kosong!${NC}"
        return 1
    fi
    if [ ! -d "$SRC" ]; then
        echo -e "${RED}[COPY] ERROR: Direktori sumber '$SRC' tidak ditemukan!${NC}"
        return 1
    fi

    # Buat direktori tujuan jika belum ada
    mkdir -p "$DST"

    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        PROSES PENYALINAN FILE                ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo -e "  ${BLUE}Sumber : $(basename "$SRC")${NC}"
    echo -e "  ${BLUE}Tujuan : $(basename "$DST")${NC}"
    echo ""

    local count_copied=0
    local count_updated=0
    local count_skipped=0
    local count_failed=0
    local total_bytes=0

    # Iterasi semua file di direktori sumber (rekursif)
    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#$SRC/}"
        local dst_file="$DST/$rel_path"
        local dst_subdir
        dst_subdir="$(dirname "$dst_file")"

        # Pastikan subdirektori tujuan ada
        if [ ! -d "$dst_subdir" ]; then
            mkdir -p "$dst_subdir"
        fi

        local action=""
        local should_copy=false

        # Tentukan apakah file perlu disalin
        if [ ! -f "$dst_file" ]; then
            action="SALIN BARU"
            should_copy=true
        else
            local src_mtime dst_mtime
            src_mtime=$(stat -c%Y "$src_file" 2>/dev/null || echo "0")
            dst_mtime=$(stat -c%Y "$dst_file" 2>/dev/null || echo "0")

            if [ "$src_mtime" -gt "$dst_mtime" ]; then
                action="PERBARUI"
                should_copy=true
            else
                action="LEWATI"
                should_copy=false
            fi
        fi

        if [ "$should_copy" = true ]; then
            local file_size
            file_size=$(stat -c%s "$src_file" 2>/dev/null || echo "0")

            # Lakukan penyalinan
            if cp -p "$src_file" "$dst_file" 2>/dev/null; then
                # Preservasi timestamp sumber
                touch -r "$src_file" "$dst_file" 2>/dev/null

                total_bytes=$(( total_bytes + file_size ))

                # Format ukuran file
                local size_hr
                if [ "$file_size" -gt 1048576 ]; then
                    size_hr="$(( file_size / 1048576 ))MB"
                elif [ "$file_size" -gt 1024 ]; then
                    size_hr="$(( file_size / 1024 ))KB"
                else
                    size_hr="${file_size}B"
                fi

                if [ "$action" = "SALIN BARU" ]; then
                    echo -e "  ${GREEN}[✓ BARU   ]${NC} $(printf '%-45s' "$rel_path") ${CYAN}$size_hr${NC}"
                    ((count_copied++))
                else
                    echo -e "  ${YELLOW}[↑ UPDATE ]${NC} $(printf '%-45s' "$rel_path") ${CYAN}$size_hr${NC}"
                    ((count_updated++))
                fi
            else
                echo -e "  ${RED}[✗ GAGAL  ]${NC} $rel_path"
                ((count_failed++))
            fi
        else
            echo -e "  ${BLUE}[- SKIP   ]${NC} $rel_path"
            ((count_skipped++))
        fi

    done < <(find "$SRC" -type f -print0 | sort -z)

    # Format total bytes
    local total_hr
    if [ "$total_bytes" -gt 1048576 ]; then
        total_hr="$(( total_bytes / 1048576 ))MB"
    elif [ "$total_bytes" -gt 1024 ]; then
        total_hr="$(( total_bytes / 1024 ))KB"
    else
        total_hr="${total_bytes}B"
    fi

    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════ HASIL PENYALINAN ══════════╗${NC}"
    echo -e "  ${GREEN}  ✓ File baru disalin   : $count_copied${NC}"
    echo -e "  ${YELLOW}  ↑ File diperbarui     : $count_updated${NC}"
    echo -e "  ${BLUE}  - File dilewati       : $count_skipped${NC}"
    echo -e "  ${RED}  ✗ Gagal disalin       : $count_failed${NC}"
    echo -e "  ${CYAN}  ↕ Total data disalin  : $total_hr${NC}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${NC}"

    if [ "$count_failed" -gt 0 ]; then
        echo -e "\n${RED}[PERINGATAN] Ada $count_failed file yang gagal disalin!${NC}"
        return 1
    fi

    return 0
}

# Salin satu file dengan verifikasi
copy_single_file() {
    local src_file="$1"
    local dst_file="$2"

    if [ ! -f "$src_file" ]; then
        echo -e "${RED}[COPY] File sumber tidak ditemukan: $src_file${NC}"
        return 1
    fi

    local dst_dir
    dst_dir="$(dirname "$dst_file")"
    mkdir -p "$dst_dir"

    if cp -p "$src_file" "$dst_file"; then
        touch -r "$src_file" "$dst_file" 2>/dev/null
        echo -e "${GREEN}[COPY] Berhasil: $src_file → $dst_file${NC}"
        return 0
    else
        echo -e "${RED}[COPY] Gagal menyalin: $src_file${NC}"
        return 1
    fi
}

# Salin direktori rekursif dengan konfirmasi
copy_directory_interactive() {
    local SRC="$1"
    local DST="$2"

    echo -e "\n${YELLOW}[COPY] Akan menyalin seluruh isi:${NC}"
    echo -e "       Dari : $SRC"
    echo -e "       Ke   : $DST"
    echo -ne "  Lanjutkan? [y/N]: "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        copy_missing_files "$SRC" "$DST"
    else
        echo -e "${YELLOW}Penyalinan dibatalkan.${NC}"
    fi
}
