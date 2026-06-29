#!/bin/bash
# Entry point & Menu Utama
# File: sync_main.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Impor fungsi-fungsi dari modul agar dapat dieksekusi di skrip utama
source "$SCRIPTS_DIR/01_scanner.sh"
source "$SCRIPTS_DIR/02_copy_file.sh"
source "$SCRIPTS_DIR/03_backup.sh"
source "$SCRIPTS_DIR/04_lock.sh"
source "$SCRIPTS_DIR/05_history.sh"
source "$SCRIPTS_DIR/06_simulate.sh"

LAB1="$SCRIPT_DIR/lab1"
LAB2="$SCRIPT_DIR/lab2"
LAB3="$SCRIPT_DIR/lab3"

jalankan_sinkronisasi() {
    if acquire_lock "manual_sync"; then
        do_backup "$LAB2" "manual_lab2"
        do_backup "$LAB3" "manual_lab3"

        scan_directories "$LAB1" "$LAB2"
        copy_missing_files "$LAB1" "$LAB2"

        scan_directories "$LAB1" "$LAB3"
        copy_missing_files "$LAB1" "$LAB3"

        log_history "SYNC" "Sinkronisasi Manual: Lab1->Lab2 & Lab1->Lab3"
        release_lock "manual_sync"
        echo -e "\n>> Sinkronisasi Selesai Berhasil! <<"
    else
        echo "Proses sinkronisasi gagal dijalankan karena direktori sedang dikunci."
    fi
}

while true; do
    echo "╔══════════════════════════════════════════════════╗"
    echo "║   SISTEM SINKRONISASI DATA PRAKTIKUM ANTAR LAB   ║"
    echo "║══════════════════════════════════════════════════║"
    echo "║ 1. Sinkronisasi Otomatis Semua Lab               ║"
    echo "║ 2. Hentikan Paksa Daemon (Matikan Background)    ║"
    echo "║ 3. Scanner Direktori                             ║"
    echo "║ 4. Menu Backup                                   ║"
    echo "║ 5. Lihat Riwayat Sinkronisasi                    ║"
    echo "║ 6. Buat Simulasi File Lab                        ║"
    echo "║ 7. Cek Status Lock File                          ║"
    echo "║ 8. Jalankan Sinkronisasi di Background (Daemo)   ║"
    echo "║ 9. Keluar                                        ║"
    echo "╚══════════════════════════════════════════════════╝"
    read -p "Pilih menu [1-9]: " pilihan

    case $pilihan in
        1) 
            jalankan_sinkronisasi 
            ;;
        2) 
            echo "Mematikan daemon latar belakang..."
            pkill -f sync_daemon.sh
            echo "Daemon dihentikan."
            ;;
        3)
            read -p "Masukkan path sumber (contoh: lab1): " src_path
            read -p "Masukkan path tujuan (contoh: lab2): " dst_path
            scan_directories "$SCRIPT_DIR/$src_path" "$SCRIPT_DIR/$dst_path"
            ;;
        4) 
            # Dieksekusi sebagai script terpisah agar exit 0 tidak mematikan main script
            "$SCRIPTS_DIR/03_backup.sh" 
            ;;
        5) 
            show_history 
            ;;
        6) 
            create_lab_simulation 
            ;;
        7) 
            check_lock_status 
            ;;
        8)
            echo "Menginisiasi Daemon..."
            nohup ./sync_daemon.sh > /dev/null 2>&1 &
            echo "Proses sinkronisasi otomatis berjalan di background (PID: $!)."
            ;;
        9) 
            exit 0 
            ;;
        *) 
            echo "Pilihan tidak valid!" 
            ;;
    esac
done
