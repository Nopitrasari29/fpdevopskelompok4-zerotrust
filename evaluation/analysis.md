# Analysis & Evaluation Report — Kelompok 4 (TaskFlow API)
### M. Abhinaya Al Faruqi (NRP: 5027231011) — Jobdesk 7: Evaluation Analysis, Refleksi & Demo

## 1. Analisis Perbandingan Keamanan (Before vs After)

Penerapan prinsip **Zero Trust** ("*Never Trust, Always Verify*") diuji melalui dua skenario utama untuk membuktikan efektivitas keamanan dari modifikasi pipeline CI/CD kami:

| Metrik Evaluasi | Skenario Before (Pipeline Konvensional) | Skenario After (Zero Trust CI/CD) |
|---|---|---|
| **Image Container** | `nginx:1.14` | `nginx:latest` (serta uji blokir pada `nginx:1.14`) |
| **Pengecekan Keamanan** | Dilewati (*Implicit Trust*) | Aktif via Trivy (*Continuous Verification*) |
| **Kerentanan HIGH & CRITICAL** | **113 kerentanan** (31 Critical, 82 High) lolos sepenuhnya | **77 kerentanan** (27 Critical, 50 High) diblokir otomatis |
| **Status Deploy** | **Success** (Vulnerable image berhasil masuk klaster) | **Skipped** jika rentan; **Success** hanya jika bersih |
| **Prevention Rate (Tingkat Pencegahan)** | **0%** | **100%** |

### Analisis Jumlah Kerentanan (Perbedaan Manual vs Pipeline)
*   **Manual Scan (Riskiyatul - Job 3)** mendeteksi **113 kerentanan** pada `nginx:1.14` karena dijalankan tanpa filter, memetakan seluruh celah termasuk yang belum memiliki solusi (*unfixed*).
*   **Pipeline Scan (Hasan - Job 1)** mendeteksi **77 kerentanan** (27 Critical, 50 High) karena dikonfigurasi dengan `ignore-unfixed: true`. 
*   **Justifikasi**: Penggunaan `ignore-unfixed: true` dalam keputusan desain kami bertujuan untuk meminimalisasi *noise* dan mencegah terhambatnya proses *delivery* untuk kerentanan yang belum memiliki patch resmi dari komunitas open-source. Hal ini sejalan dengan aspek efisiensi DevOps tanpa mengabaikan perlindungan terhadap celah yang aktif dieksploitasi (*actionable vulnerabilities*).

---

## 2. Analisis Perbandingan Kinerja & Overhead Latency

Penerapan verifikasi keamanan berkelanjutan menambahkan overhead waktu pada proses integrasi. Berikut adalah rincian perbandingan durasi eksekusi pipeline:

| Stage Pipeline | Skenario Before (Commit `ae0182b`) | Skenario After - Sukses (Commit `b5130fa`) | Overhead Waktu (Detik) |
|---|---|---|---|
| **Build Application** | 6 detik | 4 detik | -2 detik |
| **Security Scan (Trivy)** | *Dilewati (0s)* | 15 detik | +15 detik |
| **Deploy** | 2 detik | 4 detik | +2 detik |
| **Send Notification** | 3 detik | 3 detik | 0 detik |
| **Runner Setup & Teardown** | 11 detik | 15 detik | +4 detik |
| **Total Durasi** | **22 detik** | **41 detik** | **+19 detik** |

### Pembahasan Overhead Latency
Secara matematis, penambahan pemindaian keamanan menyebabkan peningkatan waktu sebesar **86.36%** (selisih 19 detik). 

Secara teknis, peningkatan ini disebabkan oleh:
1.  **Unduhan Database Kerentanan**: GitHub Actions runner virtual yang dinamis (*clean environment*) tidak memiliki cache database Trivy, sehingga harus mengunduh data definisi kerentanan sebesar ~100MB+ pada setiap eksekusi.
2.  **Overhead Runner**: Setup container runner tambahan di GitHub Actions untuk Trivy memerlukan waktu sekitar 9-10 detik.

**Justifikasi Kelayakan**: Durasi total **41 detik** secara absolut sangat cepat dan berada jauh di bawah batas toleransi waktu pengiriman perangkat lunak modern (biasanya berkisar antara 5–15 menit). Peningkatan waktu 19 detik ini merupakan harga yang sangat murah dibandingkan kerugian akibat infiltrasi kerentanan kritis di lingkungan produksi.

---

## 3. Korelasi Temuan dengan Literatur Akademis

### Hubungan dengan Bhardwaj dkk. (2025)
Paper utama kami menunjukkan peningkatan *prevention rate* dari 50% ke 100% dengan overhead kinerja yang minimal (+5% hingga +7% di lingkungan GitLab CI terkontrol). 
*   Di proyek kami, *prevention rate* juga naik ke **100%**. 
*   Namun, kami mengalami persentase overhead yang sedikit lebih tinggi (**86.36%**) karena kami menggunakan runner publik GitHub Actions yang bersifat ephemeral (tidak menyimpan cache secara persisten), berbeda dari klaster eksperimen Bhardwaj dkk. yang menggunakan runner terdedikasi (*warmed agents*).

### Hubungan dengan Shin dkk. (2025)
Shin dkk. menekankan pentingnya analisis bertahap di sepanjang SDLC untuk menghindari *implicit trust*. Dengan menempatkan `security-scan` langsung di antara `build` dan `deploy`, serta menguncinya dengan sintaks `needs: security-scan`, kelompok kami berhasil menghilangkan *implicit trust* pada tahap serah terima artefak (*artifact handoff*).

---

## 4. Kesimpulan Akhir

Eksperimen membuktikan bahwa **Zero Trust CI/CD** yang kami bangun memberikan peningkatan keamanan yang mutlak (dari Prevention Rate 0% menjadi 100% terhadap image rentan `nginx:1.14`) dengan mengorbankan durasi pipeline sebesar 19 detik. Secara operasional, peningkatan ini sangat layak diterapkan demi mengamankan rantai pasok perangkat lunak (*software supply chain*) aplikasi TaskFlow API.
