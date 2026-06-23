# Sistem Sinkronisasi Data Praktikum Antar Laboratorium

Tugas Besar Mata Kuliah Sistem Operasi — Program Studi Sains Data, Semester 2

Sistem ini dibuat untuk menyelesaikan masalah sinkronisasi data praktikum di 3 laboratorium komputer. Sebelumnya sinkronisasi dilakukan manual pakai flashdisk, sering ada file yang beda versi atau hilang, dan tidak ada catatan perubahan sama sekali. Sistem ini mengotomatisasi seluruh proses tersebut menggunakan shell scripting di Ubuntu Linux.

---

## Anggota Tim

| Nama | File | Tugas |
|------|------|-------|
| Daffa | `sync_main.sh` | Entry point & menu utama |
| Misya | `sync_daemon.sh`, `scripts/04_lock.sh` | Background daemon & file locking |
| Nabilah | `scripts/02_copy_file.sh` | Salin file yang belum ada atau perlu diperbarui |
| Dewo | `scripts/03_backup.sh` | Backup sebelum sinkronisasi |
| Jelli | `scripts/05_history.sh` | Riwayat sinkronisasi |
| Attar | `scripts/01_scanner.sh` | Scanning & perbandingan dua direktori |
| Naren | `scripts/06_simulate.sh` | Simulasi kondisi file di tiap lab |

---

## Struktur Folder

```
lab-sync-praktikum/
├── sync_main.sh
├── sync_daemon.sh
├── scripts/
│   ├── 01_scanner.sh
│   ├── 02_copy_file.sh
│   ├── 03_backup.sh
│   ├── 04_lock.sh
│   ├── 05_history.sh
│   └── 06_simulate.sh
├── .gitignore
└── README.md
```

Folder `lab1/`, `lab2/`, `lab3/`, `backup/`, `logs/`, dan `lock/` dibuat otomatis saat program dijalankan.

---

## Cara Pakai

Clone repo, kasih izin eksekusi, lalu jalankan.

```bash
git clone https://github.com/nabilah-nugroho/lab-sync.git
cd lab-sync
chmod +x sync_main.sh sync_daemon.sh scripts/*.sh
./sync_main.sh
```

Nanti muncul menu interaktif. Mulai dari menu **6 (Buat Simulasi File Lab)** dulu biar ada data yang bisa disinkronisasi, baru pilih menu **1 (Sinkronisasi Otomatis Semua Lab)**.

Kalau mau jalan di background terus:

```bash
nohup ./sync_daemon.sh &
```

---

## Yang Bisa Dilakukan Sistem Ini

- Membandingkan isi dua direktori dan mendeteksi file mana yang hilang atau beda versi
- Menyalin file yang belum ada di tujuan, memperbarui yang lebih lama
- Backup otomatis sebelum sinkronisasi dijalankan, dengan auto-cleanup (simpan 7 backup terakhir)
- File locking supaya tidak terjadi race condition kalau ada dua proses jalan barengan
- Menyimpan riwayat setiap sinkronisasi lengkap dengan timestamp dan status
- Bisa jalan di background sebagai daemon, sinkronisasi otomatis tiap 60 detik

---

## Alur Sinkronisasi

```
Mulai
  └─► Cek lock (kalau ada proses lain yang jalan, berhenti dulu)
        └─► Backup Lab2 & Lab3
              └─► Scan Lab1 vs Lab2 → salin yang perlu
                    └─► Scan Lab1 vs Lab3 → salin yang perlu
                          └─► Catat ke riwayat
                                └─► Lepas lock → Selesai
```

Lab1 dijadikan direktori master/acuan.