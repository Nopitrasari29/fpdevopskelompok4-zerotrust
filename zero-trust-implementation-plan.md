# Zero Trust Enhancements Implementation Plan

Sangat memungkinkan untuk diimplementasikan! Ketiga fitur tersebut akan melengkapi arsitektur Zero Trust yang Anda bangun, memperluas pengamanan tidak hanya dari segi kerentanan (vulnerability) tetapi juga integritas rantai pasok (Supply Chain Security) dan kepatuhan konfigurasi infrastruktur (Policy as Code).

Berikut adalah rencana implementasi untuk ketiga fitur tersebut tanpa merusak simulasi yang sudah berjalan.

## Proposed Changes

### 1. SBOM Generation (Trivy)
Trivy dapat dipanggil dua kali: pertama untuk memindai kerentanan (yang menggagalkan pipeline jika ditemukan CRITICAL/HIGH), dan kedua untuk mengekstrak Software Bill of Materials (SBOM) ke dalam file berformat CycloneDX atau SPDX.
*   **File yang dimodifikasi**: `.github/workflows/ci.yml`
*   **Perubahan**: Menambahkan step Trivy baru dengan argumen `format: 'cyclonedx'` dan `output: 'sbom.json'`. File ini kemudian akan diunggah sebagai *build artifact* di GitHub.

### 2. Artifact Signing & Verification (Cosign)
Karena pipeline saat ini tidak mem-build dan mem-push image ke registry nyata (bersifat simulasi menggunakan image publik `nginx:latest`), kita akan menggunakan Cosign untuk melakukan **Blob Signing**. Cosign akan membuat *keypair* secara dinamis di *runner* CI/CD, menandatangani file SBOM (`sbom.json`) yang dihasilkan Trivy, dan memverifikasi tanda tangannya. Ini adalah representasi sempurna dari prinsip "Always Verify" pada suatu artefak.
*   **File yang dimodifikasi**: `.github/workflows/ci.yml`
*   **Perubahan**: 
    * Menambahkan *action* instalasi Cosign (`sigstore/cosign-installer`).
    * Menambahkan eksekusi `cosign generate-key-pair`.
    * Menambahkan eksekusi `cosign sign-blob` dan `cosign verify-blob` pada artefak `sbom.json`.

### 3. Policy as Code (Conftest / OPA)
Untuk mengecek kepatuhan konfigurasi Kubernetes YAML sebelum di-*deploy*, kita akan menggunakan **Conftest**. Kita akan membuat *policy* menggunakan bahasa Rego yang melarang eksekusi container sebagai user root (salah satu standar Zero Trust & Kubernetes Security).
*   **File yang ditambahkan**: `policy/deployment.rego` (File Rego sederhana yang berisi aturan pelarangan user root).
*   **File yang dimodifikasi**: `.github/workflows/ci.yml`
    * Menambahkan tahap instalasi Conftest.
    * Menambahkan step: `conftest test implementation/k8s-deployment.yaml -p policy/deployment.rego`.
*   **File yang dimodifikasi**: `implementation/k8s-deployment.yaml`. Menambahkan blok `securityContext: runAsUser: 1000` pada konfigurasi pod agar mematuhi aturan keamanan Conftest yang kita buat.

---

> [!NOTE]
> Semua fitur ini dapat diimplementasikan sepenuhnya dalam batasan *Free Tier* GitHub Actions tanpa memerlukan *Secrets/Environment variables* karena sifat *keypair* Cosign dibuat secara ad-hoc per *run* dan digunakan langsung untuk *blob signing*.
