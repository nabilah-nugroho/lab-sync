#!/bin/bash
# MODUL 4 : FILE LOCKING & BACKGROUND PROCESS
# File    : 04_lock.sh
# Author  : Misya 
# Desc    : Mengelola lock file untuk mencegah race condition dan menangani proses sinkronisasi di background

RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
CYAN=${CYAN:-'\033[0;36m'}
BOLD=${BOLD:-'\033[1m'}
NC=${NC:-'\033[0m'}

SCRIPT_DIR_LOCK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_ROOT="${LOCK_DIR:-$SCRIPT_DIR_LOCK/lock}"
LOCK_TIMEOUT=300  # Timeout lock dalam detik (5 menit)

# FUNGSI UTAMA: acquire_lock
# Parameter  : $1 = nama operasi (identifier unik)
# Return     : 0 jika berhasil dapat lock, 1 jika gagal

acquire_lock() {
    local LOCK_NAME="$1"
    local LOCK_FILE="$LOCK_ROOT/${LOCK_NAME}.lock"
    local MAX_WAIT=10   # Detik maksimal menunggu
    local WAIT_COUNT=0

    mkdir -p "$LOCK_ROOT"

    echo -e "${BLUE}[LOCK] Mencoba mendapatkan lock: $LOCK_NAME${NC}"

    # Loop: coba dapatkan lock
    while true; do
        # Cek apakah lock file sudah ada
        if [ -f "$LOCK_FILE" ]; then
            local lock_pid lock_time current_time elapsed

            # Baca PID dari lock file
            lock_pid=$(cat "$LOCK_FILE" 2>/dev/null | grep "PID=" | cut -d'=' -f2)
            lock_time=$(cat "$LOCK_FILE" 2>/dev/null | grep "TIMESTAMP=" | cut -d'=' -f2)
            current_time=$(date +%s)

            if [ -n "$lock_time" ]; then
                elapsed=$(( current_time - lock_time ))
            else
                elapsed=0
            fi

            # Cek apakah proses yang memegang lock masih hidup
            if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
                # Proses masih hidup
                if [ "$elapsed" -gt "$LOCK_TIMEOUT" ]; then
                    # Lock sudah terlalu lama → paksa lepas
                    echo -e "${YELLOW}[LOCK] Lock sudah $elapsed detik (PID $lock_pid). Paksa lepas...${NC}"
                    rm -f "$LOCK_FILE"
                else
                    WAIT_COUNT=$(( WAIT_COUNT + 1 ))
                    if [ "$WAIT_COUNT" -ge "$MAX_WAIT" ]; then
                        echo -e "${RED}[LOCK] GAGAL mendapatkan lock setelah ${MAX_WAIT}s. Proses lain masih berjalan (PID: $lock_pid).${NC}"
                        return 1
                    fi
                    echo -e "${YELLOW}[LOCK] Menunggu lock... ($WAIT_COUNT/${MAX_WAIT}s) [PID: $lock_pid]${NC}"
                    sleep 1
                    continue
                fi
            else
                # Proses tidak ada → lock stale, hapus
                echo -e "${YELLOW}[LOCK] Lock stale ditemukan (PID $lock_pid tidak berjalan). Membersihkan...${NC}"
                rm -f "$LOCK_FILE"
            fi
        fi

        # Coba buat lock file secara atomik menggunakan mkdir
        if mkdir "$LOCK_FILE.dir" 2>/dev/null; then
            # Tulis informasi lock
            cat > "$LOCK_FILE" << EOF
PID=$$
PROCESS_NAME=$LOCK_NAME
TIMESTAMP=$(date +%s)
DATE=$(date '+%d-%m-%Y %H:%M:%S')
USER=$(whoami)
HOSTNAME=$(hostname)
SCRIPT=$0
EOF
            # Hapus marker direktori sementara
            rmdir "$LOCK_FILE.dir" 2>/dev/null

            echo -e "${GREEN}[LOCK] ✓ Lock berhasil diperoleh: $LOCK_NAME (PID: $$)${NC}"

            # Setup trap untuk otomatis lepas lock saat exit
            trap "release_lock '$LOCK_NAME'" EXIT INT TERM

            return 0
        fi

        # Gagal buat lock → coba lagi
        sleep 1
        WAIT_COUNT=$(( WAIT_COUNT + 1 ))
        if [ "$WAIT_COUNT" -ge "$MAX_WAIT" ]; then
            echo -e "${RED}[LOCK] TIMEOUT: Tidak bisa mendapatkan lock '$LOCK_NAME'.${NC}"
            return 1
        fi
    done
}

# FUNGSI: release_lock
# Parameter : $1 = nama operasi
release_lock() {
    local LOCK_NAME="$1"
    local LOCK_FILE="$LOCK_ROOT/${LOCK_NAME}.lock"

    if [ -f "$LOCK_FILE" ]; then
        # Pastikan kita yang memegang lock ini
        local lock_pid
        lock_pid=$(grep "PID=" "$LOCK_FILE" 2>/dev/null | cut -d'=' -f2)

        if [ "$lock_pid" = "$$" ]; then
            rm -f "$LOCK_FILE"
            echo -e "${GREEN}[LOCK] ✓ Lock dilepas: $LOCK_NAME${NC}"
        else
            echo -e "${YELLOW}[LOCK] Lock '$LOCK_NAME' dimiliki PID lain ($lock_pid). Tidak dilepas.${NC}"
        fi
    fi

    # Hapus trap
    trap - EXIT INT TERM 2>/dev/null
}

# FUNGSI: check_lock_status
# Desc    : Tampilkan status semua lock yang aktif
check_lock_status() {
    mkdir -p "$LOCK_ROOT"

    local lock_files=()
    while IFS= read -r -d '' f; do
        lock_files+=("$f")
    done < <(find "$LOCK_ROOT" -name "*.lock" -type f -print0 2>/dev/null)

    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         STATUS LOCK FILE                 ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo -e "  ${BLUE}Direktori lock: $LOCK_ROOT${NC}\n"

    if [ "${#lock_files[@]}" -eq 0 ]; then
        echo -e "  ${GREEN}✓ Tidak ada lock aktif. Sistem bebas.${NC}"
    else
        echo -e "  ${YELLOW}⚠ Ditemukan ${#lock_files[@]} lock aktif:${NC}\n"
        for lf in "${lock_files[@]}"; do
            local lock_name
            lock_name=$(basename "$lf" .lock)
            echo -e "  ${RED}■ $lock_name${NC}"

            while IFS='=' read -r key val; do
                [[ "$key" =~ ^# ]] && continue
                [[ -z "$key" ]] && continue
                echo -e "    ${BLUE}$key${NC} = $val"
            done < "$lf"

            # Cek apakah proses masih hidup
            local pid
            pid=$(grep "PID=" "$lf" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$pid" ]; then
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "    ${GREEN}STATUS = AKTIF (proses berjalan)${NC}"
                else
                    echo -e "    ${RED}STATUS = STALE (proses tidak berjalan)${NC}"
                fi
            fi
            echo ""
        done
    fi

    # Cek juga PID daemon
    local daemon_pid_file="$LOCK_ROOT/daemon.pid"
    if [ -f "$daemon_pid_file" ]; then
        local dpid
        dpid=$(cat "$daemon_pid_file")
        echo -e "  ${BLUE}Daemon PID: $dpid${NC}"
        if kill -0 "$dpid" 2>/dev/null; then
            echo -e "  ${GREEN}Status Daemon: BERJALAN${NC}"
        else
            echo -e "  ${YELLOW}Status Daemon: TIDAK BERJALAN (PID stale)${NC}"
        fi
    fi
}

# FUNGSI: force_release_all_locks
# Desc    : Paksa hapus semua lock (emergency)
force_release_all_locks() {
    mkdir -p "$LOCK_ROOT"
    echo -e "${YELLOW}[LOCK] Membersihkan semua lock file...${NC}"

    find "$LOCK_ROOT" -name "*.lock" -type f -print | while read -r lf; do
        echo -e "  ${RED}Hapus: $lf${NC}"
        rm -f "$lf"
    done

    find "$LOCK_ROOT" -name "*.lock.dir" -type d -exec rmdir {} \; 2>/dev/null

    echo -e "${GREEN}[LOCK] Semua lock telah dibersihkan.${NC}"
}

# FUNGSI: is_locked
# Return : 0 jika terkunci, 1 jika bebas
is_locked() {
    local LOCK_NAME="$1"
    local LOCK_FILE="$LOCK_ROOT/${LOCK_NAME}.lock"
    [ -f "$LOCK_FILE" ]
}

# FUNGSI: run_with_lock
# Desc    : Jalankan perintah dengan proteksi lock
run_with_lock() {
    local LOCK_NAME="$1"
    shift
    local COMMAND="$@"

    if acquire_lock "$LOCK_NAME"; then
        echo -e "${BLUE}[LOCK] Menjalankan dengan lock: $COMMAND${NC}"
        eval "$COMMAND"
        local exit_code=$?
        release_lock "$LOCK_NAME"
        return $exit_code
    else
        echo -e "${RED}[LOCK] Tidak bisa menjalankan - lock gagal diperoleh.${NC}"
        return 1
    fi
}
