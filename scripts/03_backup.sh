#!/bin/bash
# ============================================================
# MODUL 3 : BACKUP SEBELUM SINKRONISASI
# File    : 03_backup.sh
# Author  : Dewo (Backup Manager)
# Desc    : Membuat backup direktori ke folder cadangan
#           sebelum proses sinkronisasi dijalankan
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR_BACKUP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="${BACKUP_DIR:-$SCRIPT_DIR_BACKUP/backup}"
MAX_BACKUP_KEEP=7

# ============================================================
# FUNGSI UTAMA : BACKUP
# ============================================================
do_backup() {
    local SRC="$1"
    local LABEL="${2:-backup}"

    if [ -z "$SRC" ]; then
        echo -e "${RED}[BACKUP] ERROR: Path direktori kosong!${NC}"
        return 1
    fi

    if [ ! -d "$SRC" ]; then
        echo -e "${RED}[BACKUP] ERROR: Direktori '$SRC' tidak ditemukan!${NC}"
        return 1
    fi

    local TIMESTAMP
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

    local BACKUP_NAME="${LABEL}_${TIMESTAMP}"
    local BACKUP_PATH="$BACKUP_ROOT/$BACKUP_NAME"

    echo -e "\n${CYAN}==============================================${NC}"
    echo -e "${CYAN}          PROSES BACKUP DIMULAI               ${NC}"
    echo -e "${CYAN}==============================================${NC}"

    echo -e "${BLUE}Sumber :${NC} $SRC"
    echo -e "${BLUE}Tujuan :${NC} $BACKUP_PATH"
    echo -e "${BLUE}Waktu  :${NC} $(date '+%d-%m-%Y %H:%M:%S')"
    echo ""

    mkdir -p "$BACKUP_ROOT"
    mkdir -p "$BACKUP_PATH"

    echo -e "${YELLOW}[BACKUP] Menyalin file...${NC}"

    if rsync -a "$SRC/" "$BACKUP_PATH/" >/dev/null 2>&1; then

        local FILE_COUNT
        local SIZE_TOTAL

        FILE_COUNT=$(find "$BACKUP_PATH" -type f | wc -l)
        SIZE_TOTAL=$(du -sh "$BACKUP_PATH" | cut -f1)

        save_backup_metadata \
            "$BACKUP_PATH" \
            "$SRC" \
            "$LABEL" \
            "$TIMESTAMP" \
            "$FILE_COUNT" \
            "$SIZE_TOTAL"

        cleanup_old_backups "$LABEL"

        echo -e "${GREEN}[✓] Backup berhasil dibuat${NC}"
        echo -e "${BLUE}Jumlah File :${NC} $FILE_COUNT"
        echo -e "${BLUE}Ukuran      :${NC} $SIZE_TOTAL"
        echo -e "${BLUE}Lokasi      :${NC} $BACKUP_PATH"

        return 0

    else
        echo -e "${RED}[✗] Backup gagal!${NC}"
        return 1
    fi
}

# ============================================================
# SIMPAN METADATA BACKUP
# ============================================================
save_backup_metadata() {

    local BACKUP_PATH="$1"
    local ORIGINAL_SRC="$2"
    local LABEL="$3"
    local TIMESTAMP="$4"
    local FILE_COUNT="$5"
    local SIZE="$6"

    local META_FILE="$BACKUP_PATH/.backup_info"

    cat > "$META_FILE" << EOF
BACKUP_LABEL=$LABEL
BACKUP_TIMESTAMP=$TIMESTAMP
BACKUP_DATE=$(date '+%d-%m-%Y %H:%M:%S')
ORIGINAL_SOURCE=$ORIGINAL_SRC
FILE_COUNT=$FILE_COUNT
TOTAL_SIZE=$SIZE
CREATED_BY=$(whoami)
HOSTNAME=$(hostname)
EOF
}

# ============================================================
# HAPUS BACKUP LAMA
# ============================================================
cleanup_old_backups() {

    local LABEL="$1"

    local BACKUP_COUNT
    BACKUP_COUNT=$(find "$BACKUP_ROOT" \
        -maxdepth 1 \
        -type d \
        -name "${LABEL}_*" | wc -l)

    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUP_KEEP" ]; then

        local DELETE_COUNT
        DELETE_COUNT=$((BACKUP_COUNT - MAX_BACKUP_KEEP))

        echo -e "${YELLOW}[BACKUP] Membersihkan backup lama...${NC}"

        find "$BACKUP_ROOT" \
            -maxdepth 1 \
            -type d \
            -name "${LABEL}_*" \
            | sort \
            | head -n "$DELETE_COUNT" \
            | while read -r OLD_BACKUP
            do
                echo -e "${YELLOW}Menghapus : $(basename "$OLD_BACKUP")${NC}"
                rm -rf "$OLD_BACKUP"
            done
    fi
}

# ============================================================
# TAMPILKAN DAFTAR BACKUP
# ============================================================
list_backups() {

    echo -e "\n${CYAN}========== DAFTAR BACKUP ==========${NC}"

    local FOUND=0

    while IFS= read -r -d '' DIR
    do
        FOUND=1

        local NAME
        NAME=$(basename "$DIR")

        echo -e "\n${GREEN}$NAME${NC}"

        if [ -f "$DIR/.backup_info" ]; then
            cat "$DIR/.backup_info"
        fi

    done < <(find "$BACKUP_ROOT" \
        -maxdepth 1 \
        -mindepth 1 \
        -type d \
        -print0)

    if [ "$FOUND" -eq 0 ]; then
        echo -e "${YELLOW}Belum ada backup.${NC}"
    fi
}

# ============================================================
# RESTORE BACKUP
# ============================================================
restore_backup() {

    echo -e "\n${CYAN}========== RESTORE BACKUP ==========${NC}"

    mapfile -t BACKUPS < <(
        find "$BACKUP_ROOT" \
        -maxdepth 1 \
        -mindepth 1 \
        -type d | sort -r
    )

    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${YELLOW}Tidak ada backup tersedia.${NC}"
        return 1
    fi

    local i=1

    for BK in "${BACKUPS[@]}"
    do
        echo "$i. $(basename "$BK")"
        ((i++))
    done

    echo ""
    read -p "Pilih backup : " CHOICE

    local INDEX=$((CHOICE - 1))

    if [ "$INDEX" -lt 0 ] || [ "$INDEX" -ge "${#BACKUPS[@]}" ]; then
        echo -e "${RED}Pilihan tidak valid!${NC}"
        return 1
    fi

    read -p "Direktori tujuan restore : " DEST

    mkdir -p "$DEST"

    if rsync -a "${BACKUPS[$INDEX]}/" "$DEST/" >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] Restore berhasil${NC}"
    else
        echo -e "${RED}[✗] Restore gagal${NC}"
    fi
}

# ============================================================
# MENU TEST
# ============================================================
show_menu() {

    while true
    do
        echo ""
        echo "====================================="
        echo "       MODUL BACKUP SINKRONISASI"
        echo "====================================="
        echo "1. Buat Backup"
        echo "2. List Backup"
        echo "3. Restore Backup"
        echo "4. Keluar"
        echo ""

        read -p "Pilih menu: " MENU

        case $MENU in

            1)
                read -p "Direktori sumber: " SRC
                read -p "Label backup: " LABEL
                do_backup "$SRC" "$LABEL"
                ;;

            2)
                list_backups
                ;;

            3)
                restore_backup
                ;;

            4)
                exit 0
                ;;

            *)
                echo "Pilihan tidak valid!"
                ;;
        esac
    done
}

# ============================================================
# JALANKAN MENU JIKA FILE DIEKSEKUSI LANGSUNG
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_menu
fi
