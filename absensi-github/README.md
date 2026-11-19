# Absensi Karyawan (GitHub Pages + Supabase)

## 1. Siapkan Supabase (gratis)
1. Buat project di supabase.com.
2. **Authentication > Providers > Email**: matikan **Confirm email** (login memakai NIK, bukan email asli).
3. **SQL Editor**: tempel isi `schema.sql`, lalu Run.
4. **Project Settings > API**: salin **Project URL** dan **anon public key**.

## 2. Isi konfigurasi
Buka `index.html`, cari `const CFG` di bagian script, lalu isi:
- `url` dan `key` dari langkah 1
- `office`: nama, `lat`, `lng` (koordinat kantor dari Google Maps), dan `radius` dalam meter

Anon key memang aman ditaruh di kode publik, karena akses data dibatasi aturan RLS di `schema.sql`.

## 3. Deploy ke GitHub Pages
1. Buat repository baru, unggah `index.html`.
2. **Settings > Pages > Build and deployment**: Source = Deploy from a branch, Branch = `main`, folder `/ (root)`.
3. Tunggu satu menit, lalu buka `https://USERNAME.github.io/NAMA-REPO/`.

## 4. Jadikan akun Admin HRD
1. Buka aplikasi, klik **Daftar**, buat akun (mis. NIK `hrd01`).
2. Di **SQL Editor** Supabase jalankan:
   `update public.profiles set role='hrd', jabatan='Admin HRD' where nik='hrd01';`
3. Keluar lalu masuk lagi. Tab **Admin** muncul di menu bawah: setujui/tolak izin, rekap semua karyawan per bulan, unduh CSV.

## Catatan
- Karyawan baru mendaftar sendiri lewat tombol "Daftar" di halaman login.
- Lokasi dan kamera hanya jalan lewat HTTPS (GitHub Pages sudah HTTPS).
- `schema.sql` aman dijalankan ulang. Karyawan hanya bisa mengubah nomor telepon, tidak bisa mengubah role atau gaji.
- Gaji pokok dan jabatan karyawan diubah HRD lewat **Table Editor > profiles**.
- Reset kata sandi lewat **Authentication > Users** di Supabase.
- Jam absen diambil dari perangkat. Untuk pemakaian sungguhan di perusahaan, pindahkan pencatatan waktu ke server (Supabase Edge Function).
