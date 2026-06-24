#daffa

#!/bin/bash

# Fungsi untuk menjalankan alur sinkronisasi utama
jalankan_sinkronisasi() {
    echo "Mengecek status kunci..."
    # 1. Panggil skrip lock untuk pasang kunci
    ./scripts/04_lock.sh lock

    echo "Memulai proses pencadangan (Backup)..."
    # 2. Panggil skrip backup
    ./scripts/03_backup.sh

    echo "Menyinkronkan Lab 1 ke Lab 2..."
    # 3. Jalankan Scanner untuk Lab 2
    ./scripts/01_scanner.sh lab1 lab2
    ./scripts/02_copy_file.sh lab1 lab2

    echo "Menyinkronkan Lab 1 ke Lab 3..."
    # 4. Jalankan Scanner untuk Lab 3
    ./scripts/01_scanner.sh lab1 lab3
    ./scripts/02_copy_file.sh lab1 lab3

    echo "Mencatat riwayat aktivitas..."
    # 5. Panggil skrip history  
    ./scripts/05_history.sh "Sukses menyinkronkan Lab 2 dan Lab 3"

    echo "Membuka kembali kunci sistem..."
    # 6. Lepas kunci 
    ./scripts/04_lock.sh unlock
    
    echo ">> Sinkronisasi Selesai Berhasil! <<"
}


echo "╔════════════════════════════════════════════════╗"
echo "║  SISTEM SINKRONISASI DATA PRAKTIKUM ANTAR LAB  ║"
echo "╚════════════════════════════════════════════════╝"
echo "1. Sinkronisasi Otomatis Semua Lab"
echo "2. Lihat Riwayat Sinkronisasi"
echo "3. Backup Manual"
echo "4. Berhentikan Proses Background (Daemon)"
echo "5. Buat Simulasi File Lab"
echo "6. Keluar"
echo "══════════════════════════════════════════════════"
read -p "Pilih menu [1-6]: " pilihan

case $pilihan in
    1)
        jalankan_sinkronisasi
        ;;
    2)
        # Memanggil skrip riwayat 
        ./scripts/05_history.sh view
        ;;
    3)
        # Memanggil skrip backup  
        ./scripts/03_backup.sh
        ;;
    4)
        echo "Mematikan daemon latar belakang..."
        sync_daemon.sh
        echo "Daemon dihentikan."
        ;;
    5)
        # Memanggil skrip simulasi 
        ./scripts/06_simulate.sh
        ;;
    6)
        echo "Keluar dari program."
        exit 0
        ;;
    *)
        echo "Pilihan tidak valid!"
        ;;
esac
      
