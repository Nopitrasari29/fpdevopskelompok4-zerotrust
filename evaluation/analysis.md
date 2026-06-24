# Analysis & Evaluation Report — Kelompok 4 (TaskFlow API)
### M. Abhinaya Al Faruqi (NRP: 5027231011) — Jobdesk 7: Evaluation Analysis, Refleksi & Demo

## 1. Analisis Perbandingan Keamanan (Before vs After)

Penerapan prinsip **Zero Trust** ("*Never Trust, Always Verify*") diuji secara komprehensif melalui perbandingan metrik keamanan pada pipeline CI/CD kami:

| Metrik Evaluasi | Skenario Before (Pipeline Konvensional) | Skenario After (Zero Trust CI/CD Lanjutan) |
|---|---|---|
| **Image Container** | `nginx:1.14` (Rentan & Root) | `nginxinc/nginx-unprivileged:latest` (Aman & Non-Root) |
| **Pengecekan Keamanan** | Dilewati (*Implicit Trust*) | Berlapis: Trivy (Scan), Cosign (Kriptografi), Conftest (Policy) |
| **Kerentanan HIGH & CRITICAL** | Lolos sepenuhnya (Vulnerable) | Pemblokiran otomatis oleh **Trivy** |
| **Miskonfigurasi Akses Root** | Lolos sepenuhnya (Risiko Container Escape) | Pemblokiran otomatis oleh **Conftest** (`runAsUser: 0` ditolak) |
| **Integritas Supply Chain** | Tidak ada validasi artefak (Rentan Tampering) | Verifikasi kriptografis SBOM oleh **Cosign** (Tampering ditolak) |
| **Prevention Rate (Tingkat Pencegahan)** | **0%** | **100%** di berbagai vektor serangan |

### Analisis Pemindaian Kerentanan (Trivy)
*   **Manual Scan (Riskiyatul - Job 3)** mendeteksi **113 kerentanan** pada `nginx:1.14` karena dijalankan tanpa filter, memetakan seluruh celah termasuk yang belum memiliki solusi (*unfixed*).
*   **Pipeline Scan (Hasan - Job 1)** mendeteksi **77 kerentanan** (27 Critical, 50 High) karena dikonfigurasi dengan `ignore-unfixed: true`. 
*   **Justifikasi**: Penggunaan `ignore-unfixed: true` dalam keputusan desain kami bertujuan untuk meminimalisasi *noise* dan mencegah terhambatnya proses *delivery* untuk kerentanan yang belum memiliki patch resmi dari komunitas open-source. Hal ini sejalan dengan aspek efisiensi DevOps tanpa mengabaikan perlindungan terhadap celah yang aktif dieksploitasi (*actionable vulnerabilities*).

### Analisis Pertahanan Berlapis (Zero Trust Lanjutan)
Selain mencegah *vulnerability* melalui Trivy, pipeline *After* mendemonstrasikan efektivitas dua lapis keamanan baru:
1.  **Policy as Code (Shift-Left Security)**: Melalui uji *Negative Testing*, terbukti bahwa Conftest berhasil memblokir upaya *deployment* jika manifest YAML mengizinkan akses *root* (`runAsUser: 0`). Ini mencegah eskalasi privilese di level klaster Kubernetes.
2.  **Cryptographic Verification (Supply Chain Security)**: Melalui uji *Negative Testing* terhadap integritas artefak, terbukti bahwa modifikasi (*tampering*) ilegal pada file SBOM di tengah proses CI/CD langsung terdeteksi oleh Cosign di tahap *Deployment Gate*, mencegah masuknya aplikasi yang dikompromikan ke *production*.

---

## 2. Analisis Perbandingan Kinerja & Overhead Latency

Penerapan verifikasi keamanan berkelanjutan menambahkan overhead waktu pada proses integrasi. Berikut adalah rincian perbandingan durasi eksekusi pipeline:

| Stage Pipeline | Skenario Before (Commit `ae0182b`) | Skenario After - Sukses (Commit `b5130fa`) | Overhead Waktu (Detik) |
|---|---|---|---|
| **Build Application** | 4 detik | 4 detik | 0 detik |
| **Security Scan (Trivy, Cosign, Conftest)** | *Dilewati (0s)* | 29 detik | +29 detik |
| **Deploy (termasuk KinD)** | 59 detik | 1 menit 3 detik (63s) | +4 detik |
| **Send Notification** | 2 detik | 2 detik | 0 detik |
| **Runner Setup & Teardown** | 11 detik | 15 detik | +4 detik |
| **Total Durasi** | **76 detik** | **113 detik** | **+37 detik** |

### Pembahasan Overhead Latency
Secara matematis, penambahan lapisan keamanan Zero Trust menyebabkan peningkatan waktu sebesar **48.68%** (selisih 37 detik). 

Secara teknis, peningkatan ini secara kumulatif disebabkan oleh:
1.  **Unduhan Database Kerentanan**: GitHub Actions runner virtual yang dinamis tidak memiliki cache database Trivy, sehingga harus mengunduh puluhan MB data definisi kerentanan pada setiap eksekusi.
2.  **Kriptografi & Evaluasi Kebijakan**: Proses eksekusi *key-pair* Cosign, verifikasi kriptografis SBOM, serta validasi manifes YAML dengan mesin Rego (Conftest).
3.  **Setup Ephemeral Cluster**: Proses pembuatan *node* Kubernetes in Docker (KinD) secara instan menyumbang tambahan waktu sebelum eksekusi *rollout* aplikasi dilakukan.

**Justifikasi Kelayakan**: Durasi total **113 detik** (hanya sekitar 1.8 menit) secara absolut masih tergolong sangat cepat dan berada jauh di bawah standar waktu toleransi pengiriman perangkat lunak modern (biasanya berkisar 5–15 menit). Tambahan 37 detik adalah "premi asuransi" yang sangat murah dan sepadan untuk mencegah ancaman kritis seperti celah injeksi, kebocoran *root*, dan *supply chain tampering* di lingkungan *production*.

---

## 3. Korelasi Temuan dengan Literatur Akademis

### Hubungan dengan Bhardwaj dkk. (2025)
Paper utama kami menunjukkan peningkatan *prevention rate* dari 50% ke 100% dengan overhead kinerja yang minimal (+5% hingga +7% di lingkungan GitLab CI terkontrol). 
*   Di proyek kami, *prevention rate* juga naik ke **100%**. 
*   Namun, kami mengalami persentase overhead yang lebih tinggi (**48.68%** atau 37 detik) karena kami mengimplementasikan pertahanan berlapis secara berurutan (Trivy, Cosign, Conftest, dan klaster KinD *ephemeral*) di dalam runner publik GitHub Actions yang tidak menyimpan cache secara persisten, berbeda dari klaster eksperimen Bhardwaj dkk. yang menggunakan runner terdedikasi (*warmed agents*).

### Hubungan dengan Shin dkk. (2025)
Shin dkk. menekankan pentingnya analisis bertahap di sepanjang SDLC untuk menghindari *implicit trust*. Dengan menempatkan `security-scan` langsung di antara `build` dan `deploy`, serta menguncinya dengan sintaks `needs: security-scan`, kelompok kami berhasil menghilangkan *implicit trust* pada tahap serah terima artefak (*artifact handoff*).

---

## 4. Kesimpulan Akhir

Eksperimen membuktikan bahwa **Zero Trust CI/CD Lanjutan** yang kami bangun memberikan peningkatan keamanan yang mutlak (Prevention Rate 100% terhadap kerentanan image, miskonfigurasi akses root, dan tampering artefak) dengan mengorbankan durasi pipeline sebesar 37 detik. Secara operasional, peningkatan durasi di bawah 1 menit ini sangat layak dan efisien untuk diterapkan demi mengamankan rantai pasok perangkat lunak (*software supply chain*) aplikasi TaskFlow API secara keseluruhan.
