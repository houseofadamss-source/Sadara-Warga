# Sadara Warga 🏘️🛡️💎

**Aplikasi Pintar Pengelolaan Lingkungan RT/RW**
*Solusi Modern untuk Tetangga yang Lebih Teratur, Aman, dan Sejahtera.*

Sadara Warga bukan sekadar aplikasi pendataan. Ini adalah ruang digital bersama untuk menciptakan lingkungan tinggal yang **Transparan Keuangannya**, **Terjamin Keamanannya**, dan **Maju UMKM-nya**. 

---

## 🌟 Kenapa Lingkungan Kita Butuh Sadara Warga?

### 1. 🛡️ Keamanan Akun Lapis Baja
Kita sangat serius soal data warga. Setiap akun dikunci khusus hanya untuk **satu Handphone saja**. Gak bisa sembarangan dipinjamkan atau disalahgunakan orang luar. Data pribadi Anda terlindungi oleh sistem keamanan modern yang bekerja di balik layar.

### 2. 💰 Dompet RT yang Transparan
Gak ada lagi rasa curiga soal iuran.
*   **Ledger Real-time**: Warga bisa pantau saldo kas RT secara langsung dari HP masing-masing.
*   **Bayar Iuran Dicicil**: Memberatkan kalau bayar langsung besar? Di sini warga bisa mencicil pembayaran iuran sesuai kemampuan hingga lunas.
*   **Laporan Jelas**: Ringkasan uang masuk dan pengeluaran RT tampil di halaman utama.

### 3. 🛍️ Memajukan Usaha Tetangga (UMKM)
Punya usaha di rumah? Yuk, tampilkan di Sadara Warga!
*   **Promosi ke Tetangga**: Usaha Anda akan tampil di halaman depan aplikasi biar semua tetangga tahu.
*   **Mejeng di Peta Dunia**: Usaha pilihan bahkan bisa kita bantu daftarkan langsung ke peta dunia OpenStreetMap (OSM) secara resmi.
*   **Tampilan Keren**: Bisa kasih deskripsi produk yang lengkap dan foto yang menggoda selera.

### 4. 📋 Layanan Warga Tanpa Ribet
*   **Tombol Darurat (SOS)**: Dalam hitungan detik, Anda bisa panggil bantuan petugas atau pengurus jika terjadi sesuatu yang mendesak.
*   **Surat Digital**: Butuh surat pengantar? Ajukan lewat HP, pantau statusnya, dan ambil jika sudah disetujui. Gak perlu bolak-balik ketuk pintu rumah Pak RT.
*   **Info & Acara**: Jangan sampai ketinggalan info penting atau jadwal gotong royong. Semua kabar lingkungan ada di satu pintu.

---

## 🚀 Persiapan Menjalankan Aplikasi

Jika Anda adalah pengurus wilayah yang ingin mencoba menjalankan sistem ini secara mandiri:

1.  **Ambil Kode Sumber**
    ```bash
    git clone https://github.com/adhiputra/Sadarawarga.git
    cd Sadarawarga
    ```

2.  **Atur Kunci Rahasia**
    Siapkan file bernama `.env` di folder utama dan masukkan kode akses Supabase Anda:
    ```env
    SUPABASE_URL=https://alamat-proyek-anda.supabase.co
    SUPABASE_ANON_KEY=kode-anon-anda
    ```

3.  **Siapkan Aplikasi**
    Pastikan perangkat Anda sudah terinstall Flutter, lalu jalankan:
    ```bash
    flutter pub get
    flutter run
    ```

---

## 🤝 Mari Berkolaborasi!

Aplikasi ini dibangun dari niat tulus untuk membuat hidup bertetangga jadi lebih mudah. Jika Anda punya saran fitur baru atau menemukan kendala, jangan ragu untuk berdiskusi dengan kami.

**Sadara Warga** - *Dari Warga, Oleh Warga, Untuk Warga.* 🤝
