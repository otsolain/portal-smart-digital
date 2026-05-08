# Database Schema Notes

Catatan struktur tabel Supabase untuk referensi pengembangan aplikasi Portal Smart Digital.

## Tabel: `users`
Tabel ini digunakan untuk menyimpan data pengguna (Murid, Guru, Orang Tua).

**Daftar Kolom:**
- `id` (UUID) - Primary Key
- `email` (String) - Email pengguna
- `password_hash` (String) - Kata sandi (saat ini disimpan tanpa enkripsi kompleks berdasarkan data dummy `123456`)
- `school_id` (UUID/Lainnya) - ID referensi sekolah (bisa null)
- `role` (String) - Peran pengguna (contoh: "Guru", "Murid", "Orang Tua")
- `created_at` (Timestamp) - Waktu pembuatan akun
- `updated_at` (Timestamp) - Waktu pembaruan akun
- `id_sekolah` (String) - Kode string sekolah (contoh: "SCH0005")
- `nama_user` (String) - Nama lengkap pengguna
- `status` (String) - Status akun (contoh: "Aktif")
- `foto_profile` (String/URL) - Tautan foto profil
- `nomor_telepon` (String) - Nomor telepon pengguna

---
*Catatan tambahan dari sistem:* 
- Tabel untuk sekolah bernama `schools` (bukan `school`).
- File gambar dashboard disimpan di bucket `dashboard-images` di dalam folder dengan nama `id_sekolah` (contoh: `SCH0005/`).
