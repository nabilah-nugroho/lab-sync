#!/bin/bash
# ============================================================
# MODUL 6 : SIMULASI FILE DI DIREKTORI LAB
# File    : 06_simulate.sh
# Author  : Naren (Lab Simulator)
# Desc    : Membuat file-file simulasi modul praktikum dan
#           data mahasiswa di masing-masing direktori lab
#           dengan kondisi berbeda (ada yang hilang, beda versi)
# ============================================================

RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
CYAN=${CYAN:-'\033[0;36m'}
BOLD=${BOLD:-'\033[1m'}
NC=${NC:-'\033[0m'}

SCRIPT_DIR_SIM="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================================
# FUNGSI UTAMA: create_lab_simulation
# ============================================================
create_lab_simulation() {
    local LAB1="${LAB1_DIR:-$SCRIPT_DIR_SIM/lab1}"
    local LAB2="${LAB2_DIR:-$SCRIPT_DIR_SIM/lab2}"
    local LAB3="${LAB3_DIR:-$SCRIPT_DIR_SIM/lab3}"

    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║       SIMULASI FILE DIREKTORI LAB            ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Membuat struktur file simulasi 3 laboratorium...${NC}\n"

    # Buat struktur direktori
    for lab in "$LAB1" "$LAB2" "$LAB3"; do
        mkdir -p "$lab"/{modul,data_mahasiswa,referensi,tugas,konfigurasi}
    done

    echo -e "${BLUE}[SIM] Membuat file Lab 1 (MASTER - paling lengkap)...${NC}"
    create_lab1_files "$LAB1"

    echo -e "${BLUE}[SIM] Membuat file Lab 2 (ada file hilang & beda versi)...${NC}"
    create_lab2_files "$LAB2" "$LAB1"

    echo -e "${BLUE}[SIM] Membuat file Lab 3 (kondisi paling tertinggal)...${NC}"
    create_lab3_files "$LAB3" "$LAB1"

    echo -e "\n${GREEN}${BOLD}✓ Simulasi selesai!${NC}"
    show_simulation_summary "$LAB1" "$LAB2" "$LAB3"
}

# ============================================================
# FUNGSI: Buat file Lab 1 (Master/Lengkap)
# ============================================================
create_lab1_files() {
    local LAB="$1"

    # === MODUL PRAKTIKUM ===
    cat > "$LAB/modul/modul_01_pengenalan_linux.pdf.txt" << 'EOF'
MODUL 01 - PENGENALAN LINUX
Versi: 3.0 (TERBARU)
Tanggal: 2024-12-15

1. Pendahuluan Linux
2. Perintah Dasar Terminal
3. Manajemen File dan Direktori
4. Hak Akses (Permission)
5. Text Editor (nano, vim)

Diperbarui: Ditambah materi WSL2 untuk Windows
EOF

    cat > "$LAB/modul/modul_02_shell_scripting.pdf.txt" << 'EOF'
MODUL 02 - SHELL SCRIPTING
Versi: 2.5 (TERBARU)
Tanggal: 2024-12-10

1. Pengenalan Shell Script
2. Variabel dan Tipe Data
3. Struktur Kontrol (if, for, while)
4. Fungsi
5. Penanganan Error
6. Praktik: Membuat Script Backup Otomatis
EOF

    cat > "$LAB/modul/modul_03_jaringan_komputer.pdf.txt" << 'EOF'
MODUL 03 - JARINGAN KOMPUTER
Versi: 2.0 (TERBARU)
Tanggal: 2024-12-05

1. Konsep Dasar Jaringan
2. IP Address dan Subnet
3. Protokol TCP/IP
4. Konfigurasi Jaringan Linux
5. Tools: ping, netstat, traceroute, nmap
EOF

    cat > "$LAB/modul/modul_04_database_mysql.pdf.txt" << 'EOF'
MODUL 04 - DATABASE MYSQL
Versi: 1.8 (TERBARU)
Tanggal: 2024-11-28

1. Pengenalan Database
2. Instalasi MySQL
3. DDL: CREATE, ALTER, DROP
4. DML: SELECT, INSERT, UPDATE, DELETE
5. JOIN dan Subquery
6. Backup dan Restore Database
EOF

    cat > "$LAB/modul/modul_05_web_server.pdf.txt" << 'EOF'
MODUL 05 - WEB SERVER
Versi: 1.5 (TERBARU)
Tanggal: 2024-11-20

1. Pengenalan Web Server
2. Instalasi Apache/Nginx
3. Virtual Host
4. SSL/HTTPS
5. Deploy Aplikasi Web Sederhana
EOF

    # === DATA MAHASISWA ===
    cat > "$LAB/data_mahasiswa/daftar_mahasiswa_2024.csv" << 'EOF'
NIM,NAMA,KELAS,EMAIL,STATUS
2024001,Ahmad Fauzi,TI-A,ahmad.f@kampus.ac.id,AKTIF
2024002,Budi Santoso,TI-A,budi.s@kampus.ac.id,AKTIF
2024003,Citra Dewi,TI-B,citra.d@kampus.ac.id,AKTIF
2024004,Deni Pratama,TI-B,deni.p@kampus.ac.id,AKTIF
2024005,Eka Putri,TI-C,eka.p@kampus.ac.id,AKTIF
2024006,Fajar Nugroho,TI-C,fajar.n@kampus.ac.id,AKTIF
2024007,Gita Rahayu,TI-A,gita.r@kampus.ac.id,AKTIF
2024008,Hendra Wijaya,TI-B,hendra.w@kampus.ac.id,AKTIF
EOF

    cat > "$LAB/data_mahasiswa/nilai_uts_2024.csv" << 'EOF'
NIM,NAMA,MODUL1,MODUL2,MODUL3,RATA_RATA
2024001,Ahmad Fauzi,85,90,88,87.67
2024002,Budi Santoso,78,82,80,80.00
2024003,Citra Dewi,92,95,91,92.67
2024004,Deni Pratama,70,75,72,72.33
2024005,Eka Putri,88,91,89,89.33
2024006,Fajar Nugroho,65,68,70,67.67
2024007,Gita Rahayu,95,97,96,96.00
2024008,Hendra Wijaya,80,83,81,81.33
EOF

    cat > "$LAB/data_mahasiswa/absensi_praktikum.csv" << 'EOF'
NIM,NAMA,PERTEMUAN_1,PERTEMUAN_2,PERTEMUAN_3,PERTEMUAN_4,TOTAL_HADIR
2024001,Ahmad Fauzi,H,H,H,H,4
2024002,Budi Santoso,H,A,H,H,3
2024003,Citra Dewi,H,H,H,H,4
2024004,Deni Pratama,A,H,H,A,2
2024005,Eka Putri,H,H,H,H,4
2024006,Fajar Nugroho,H,H,A,H,3
2024007,Gita Rahayu,H,H,H,H,4
2024008,Hendra Wijaya,H,A,H,H,3
EOF

    # === REFERENSI ===
    cat > "$LAB/referensi/panduan_instalasi_ubuntu.txt" << 'EOF'
PANDUAN INSTALASI UBUNTU 22.04 LTS
=====================================
1. Download ISO dari ubuntu.com
2. Buat bootable USB dengan Rufus/Balena Etcher
3. Boot dari USB
4. Pilih "Install Ubuntu"
5. Ikuti wizard instalasi
6. Reboot setelah selesai

Kebutuhan minimum:
- RAM: 4GB (rekomendasi 8GB)
- Storage: 25GB
- CPU: 2 core
EOF

    cat > "$LAB/referensi/cheatsheet_linux_commands.txt" << 'EOF'
CHEATSHEET PERINTAH LINUX
==========================
NAVIGASI:
  ls -la      : Tampilkan semua file
  cd /path    : Pindah direktori
  pwd         : Tampilkan lokasi saat ini
  find . -name "*.sh" : Cari file

MANAJEMEN FILE:
  cp src dst  : Salin file
  mv src dst  : Pindah/rename file
  rm -rf dir  : Hapus direktori
  mkdir -p    : Buat direktori rekursif

PERMISSION:
  chmod 755   : rwxr-xr-x
  chown u:g   : Ubah pemilik
  ls -la      : Lihat permission

PROSES:
  ps aux      : Tampilkan proses
  kill PID    : Hentikan proses
  nohup &     : Jalankan di background
EOF

    # === KONFIGURASI ===
    cat > "$LAB/konfigurasi/config_lab.conf" << 'EOF'
# Konfigurasi Laboratorium 1
LAB_NAME=Laboratorium Komputer 1
LAB_CAPACITY=30
OS=Ubuntu 22.04 LTS
PROCESSOR=Intel Core i5
RAM=8GB
STORAGE=512GB SSD
NETWORK=Gigabit Ethernet
PRINTER=HP LaserJet Pro
UPDATED=2024-12-15
EOF


    echo -e "  ${GREEN}✓ Lab 1: $(find "$LAB" -type f | wc -l) file dibuat${NC}"
}

# ============================================================
# FUNGSI: Buat file Lab 2 (ada file hilang & beda versi)
# ============================================================
create_lab2_files() {
    local LAB="$1"
    local LAB1="$2"

    # Salin sebagian file dari lab1 (simulasi: beberapa file hilang)
    cp "$LAB1/modul/modul_01_pengenalan_linux.pdf.txt" "$LAB/modul/" 2>/dev/null
    cp "$LAB1/modul/modul_02_shell_scripting.pdf.txt" "$LAB/modul/" 2>/dev/null
    # modul_03 s/d 05 TIDAK disalin → simulasi file hilang

    # Salin data mahasiswa (tapi versi lama)
    cp "$LAB1/data_mahasiswa/daftar_mahasiswa_2024.csv" "$LAB/data_mahasiswa/" 2>/dev/null
    # nilai_uts dan absensi TIDAK ada → simulasi file hilang

    cp "$LAB1/referensi/panduan_instalasi_ubuntu.txt" "$LAB/referensi/" 2>/dev/null
    # cheatsheet tidak ada

    # Buat versi LAMA dari modul_01 (simulasi beda versi)
    sleep 1
    cat > "$LAB/modul/modul_01_pengenalan_linux.pdf.txt" << 'EOF'
MODUL 01 - PENGENALAN LINUX
Versi: 2.1 (LAMA)
Tanggal: 2024-09-01

1. Pendahuluan Linux
2. Perintah Dasar Terminal
3. Manajemen File

Catatan: Versi ini lebih lama, belum update materi WSL2
EOF

    # Buat file yang ada di lab2 tapi tidak ada di lab1 (contoh file unik)
    cat > "$LAB/konfigurasi/config_lab.conf" << 'EOF'
# Konfigurasi Laboratorium 2 (versi lokal)
LAB_NAME=Laboratorium Komputer 2
LAB_CAPACITY=25
OS=Ubuntu 20.04 LTS
PROCESSOR=Intel Core i3
RAM=4GB
STORAGE=256GB HDD
UPDATED=2024-06-01
EOF

    # Set timestamp lama agar terlihat lebih tua
    touch -t 202409010000 "$LAB/modul/modul_01_pengenalan_linux.pdf.txt" 2>/dev/null

    echo -e "  ${GREEN}✓ Lab 2: $(find "$LAB" -type f | wc -l) file dibuat (ada file hilang & versi lama)${NC}"
}

# ============================================================
# FUNGSI: Buat file Lab 3 (kondisi paling tertinggal)
# ============================================================
create_lab3_files() {
    local LAB="$1"
    local LAB1="$2"

    # Hanya salin satu modul (paling sedikit file)
    cp "$LAB1/modul/modul_01_pengenalan_linux.pdf.txt" "$LAB/modul/" 2>/dev/null

    # Data mahasiswa versi sangat lama
    cat > "$LAB/data_mahasiswa/daftar_mahasiswa_2024.csv" << 'EOF'
NIM,NAMA,KELAS
2024001,Ahmad Fauzi,TI-A
2024002,Budi Santoso,TI-A
2024003,Citra Dewi,TI-B
EOF
    # Versi lama tidak punya kolom EMAIL dan STATUS

    # Set timestamp sangat lama
    touch -t 202401010000 "$LAB/data_mahasiswa/daftar_mahasiswa_2024.csv" 2>/dev/null
    touch -t 202401010000 "$LAB/modul/modul_01_pengenalan_linux.pdf.txt" 2>/dev/null

    # Tidak ada file referensi, tugas, atau konfigurasi
    echo -e "  ${GREEN}✓ Lab 3: $(find "$LAB" -type f | wc -l) file dibuat (kondisi sangat tertinggal)${NC}"
}

# ============================================================
# FUNGSI: Tampilkan ringkasan simulasi
# ============================================================
show_simulation_summary() {
    local LAB1="$1"
    local LAB2="$2"
    local LAB3="$3"

    echo -e "\n${BOLD}${CYAN}╔══════════════════ RINGKASAN SIMULASI ══════════════════╗${NC}"

    for i in 1 2 3; do
        eval "local LAB=\$LAB$i"
        local count
        count=$(find "$LAB" -type f 2>/dev/null | wc -l)
        local subdirs
        subdirs=$(find "$LAB" -type d 2>/dev/null | tail -n +2 | wc -l)

        echo -e "  ${YELLOW}Lab $i${NC} ($(basename "$LAB")):"
        echo -e "    ${BLUE}Lokasi      : $LAB${NC}"
        echo -e "    ${BLUE}Total File  : $count file${NC}"
        echo -e "    ${BLUE}Subdirektori: $subdirs folder${NC}"

        find "$LAB" -type d 2>/dev/null | tail -n +2 | while read -r subdir; do
            local fc
            fc=$(find "$subdir" -maxdepth 1 -type f | wc -l)
            echo -e "      ${NC}├─ $(basename "$subdir")/ : $fc file${NC}"
        done
        echo ""
    done

    echo -e "  ${RED}⚠ Kondisi disimulasikan:${NC}"
    echo -e "    ${YELLOW}• Lab 2 kekurangan 3 modul dan 2 data mahasiswa${NC}"
    echo -e "    ${YELLOW}• Lab 2 punya modul_01 versi LAMA (2.1 vs 3.0)${NC}"
    echo -e "    ${YELLOW}• Lab 3 hanya punya 1 modul dan data mahasiswa tidak lengkap${NC}"
    echo -e "    ${YELLOW}• Lab 3 data mahasiswa berformat LAMA (tanpa kolom email/status)${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${GREEN}→ Gunakan menu Sinkronisasi untuk menyamakan kondisi semua lab!${NC}"
}
