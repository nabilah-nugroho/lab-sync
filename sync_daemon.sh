#!/bin/bash
# DAEMON: Sinkronisasi Otomatis Background
# File  : sync_daemon.sh
# Desc  : Berjalan di background, sinkronisasi setiap N detik

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
LOG_DIR="$SCRIPT_DIR/logs"
BACKUP_DIR="$SCRIPT_DIR/backup"
LOCK_DIR="$SCRIPT_DIR/lock"

LAB1_DIR="$SCRIPT_DIR/lab1"
LAB2_DIR="$SCRIPT_DIR/lab2"
LAB3_DIR="$SCRIPT_DIR/lab3"

SYNC_INTERVAL=60  # Sinkronisasi setiap 60 detik
DAEMON_LOG="$LOG_DIR/daemon.log"

# Source modul
source "$SCRIPTS_DIR/01_scanner.sh"
source "$SCRIPTS_DIR/02_copy_file.sh"
source "$SCRIPTS_DIR/03_backup.sh"
source "$SCRIPTS_DIR/04_lock.sh"
source "$SCRIPTS_DIR/05_history.sh"

mkdir -p "$LOG_DIR"

log_daemon() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DAEMON] $1" | tee -a "$DAEMON_LOG"
}

log_daemon "=== DAEMON DIMULAI (PID: $$) ==="
log_daemon "Interval sinkronisasi: ${SYNC_INTERVAL}s"

# Tangani sinyal berhenti
trap 'log_daemon "=== DAEMON DIHENTIKAN ==="; exit 0' SIGTERM SIGINT

CYCLE=0
while true; do
    CYCLE=$(( CYCLE + 1 ))
    log_daemon "--- Siklus #$CYCLE dimulai ---"

    if [ -d "$LAB1_DIR" ] && [ -d "$LAB2_DIR" ] && [ -d "$LAB3_DIR" ]; then
        if acquire_lock "daemon_sync" 2>/dev/null; then
            # Backup singkat sebelum sync
            do_backup "$LAB2_DIR" "daemon_lab2" >> "$DAEMON_LOG" 2>&1
            do_backup "$LAB3_DIR" "daemon_lab3" >> "$DAEMON_LOG" 2>&1

            # Sinkronisasi
            copy_missing_files "$LAB1_DIR" "$LAB2_DIR" >> "$DAEMON_LOG" 2>&1
            copy_missing_files "$LAB1_DIR" "$LAB3_DIR" >> "$DAEMON_LOG" 2>&1

            log_history "SYNC" "Daemon cycle #$CYCLE: Lab1->Lab2 & Lab1->Lab3"
            release_lock "daemon_sync" 2>/dev/null
            log_daemon "Siklus #$CYCLE selesai."
        else
            log_daemon "Siklus #$CYCLE: Skip (lock tidak bisa diperoleh)"
        fi
    else
        log_daemon "Direktori lab belum ada. Skip."
    fi

    log_daemon "Menunggu ${SYNC_INTERVAL}s..."
    sleep "$SYNC_INTERVAL"
done
