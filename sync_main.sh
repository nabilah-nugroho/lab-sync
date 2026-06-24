#daffa

#!/bin/bash

echo -e "\n${BOLD}${GREEN}╔════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║  SISTEM SINKRONISASI DATA PRAKTIKUM ANTAR LAB  ║${NC}"
  echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo "1. Sinkronisasi Otomatis Semua Lab"
echo "2. Lihat Riwayat Sinkronisasi"
echo "3. Backup Manual"
echo "4. Berhentikan Proses Background (Daemon)"
echo "5. Buat Simulasi File Lab"
echo "6. Keluar"
echo "══════════════════════════════════════════════════ "
read -p "Pilih menu [1-6]: " pilihan

case $pilihan in
    1)
        echo "Menjalankan sinkronisasi..."
        # Nanti dipanggil: ./scripts/01_scanner.sh dsb
        ;;
    2)
        echo "Menampilkan riwayat..."
        # Nanti dipanggil: ./scripts/05_history.sh
        ;;
    3)
        echo "Melakukan backup..."
        # Nanti dipanggil: ./scripts/03_backup.sh
        ;;
    4)
        echo "Mematikan daemon..."
        pkill -f sync_daemon.sh
        echo "Daemon dihentikan."
        ;;
    5)
        echo "Membuat file simulasi..."
        # Nanti dipanggil: ./scripts/06_simulate.sh
        ;;
    6)
        echo "Keluar dari program."
        exit 0
        ;;
    *)
        echo "Pilihan tidak valid"
        ;;
esac
