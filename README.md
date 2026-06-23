# Zero Trust CI/CD Security
### Automated Vulnerability Scanning + Conditional Deployment Gating

Mata Kuliah Operasional Pengembang (DevOps) — Final Project Week 16

Kelompok 4 — TaskFlow API

---

## 👥 Anggota Kelompok

| Nama | NRP | Jobdesk |
|--------|--------|--------|
| Hasan | 5027231073 | Jobdesk 1 — Setup & Implementasi Security Scan Job |
| Rafika Az Zahra Kusumastuti | 5027231050 | Jobdesk 2 — Implementasi Conditional Deployment Gate |
| Riskiyatul Nur Oktarani | 5027231013 | Jobdesk 3 — Skenario Before (Baseline Testing) |
| Aswalia Novitriasari | 5027231012 | Jobdesk 4 — Skenario After (Zero Trust Testing) & Overhead |
| Nisrina Atiqah Dwiputri Ridzki | 5027231075 | Jobdesk 5 — README & Reproducibility Validation |
| Farand Febriansyah | 5027231084 | Jobdesk 6 — Eksplorasi Tooling & State of the Art |
| M. Abhinaya Al Faruqi | 5027231011 | Jobdesk 7 — Evaluation Analysis, Refleksi & Demo |

---

## 📌 Topik

**Zero Trust CI/CD Security**
(Automated Vulnerability Scanning + Conditional Deployment Gating)

Project ini merupakan pengembangan dari pipeline CI/CD TaskFlow API pada modul-modul sebelumnya yang telah mengimplementasikan deployment otomatis menggunakan GitHub Actions.

Enhancement yang ditambahkan pada project ini:

- Automated Vulnerability Scanning menggunakan Trivy
- Conditional Deployment Gate
- Implementasi prinsip Zero Trust
- Verifikasi keamanan sebelum deployment

---

## 📖 Latar Belakang

Pipeline CI/CD sebelumnya masih menggunakan pendekatan *implicit trust*, yaitu artefak hasil build dapat langsung melanjutkan ke tahap deployment tanpa proses verifikasi keamanan tambahan.

Kondisi tersebut berisiko menyebabkan image yang memiliki vulnerability dapat masuk ke lingkungan produksi.

Untuk mengatasi masalah tersebut, project ini menerapkan prinsip:

> **Never Trust, Always Verify**

dengan menambahkan proses vulnerability scanning dan deployment gate sebelum deployment dijalankan.

---

## 🔄 Arsitektur Pipeline

### Pipeline Sebelumnya

```text
Build
↓
Deploy
```

### Pipeline Zero Trust

```text
Build
↓
Security Scan
↓
Deploy
↓
Notification
```

---

## ⚙️ Implementasi

### Security Scan

Menggunakan:

- Trivy
- Severity Threshold:
  - HIGH
  - CRITICAL

Konfigurasi:

```yaml
severity: CRITICAL,HIGH
exit-code: 1
```

Apabila ditemukan vulnerability dengan severity HIGH atau CRITICAL maka pipeline otomatis gagal.

---

### Conditional Deployment Gate

Menggunakan dependency antar job pada GitHub Actions.

```yaml
deploy:
  needs: security-scan
```

Deployment hanya dapat berjalan apabila Security Scan berhasil.

---

## 📂 Struktur Repository

```text
FPDEVOPSKELOMPOK4-ZEROTRUST/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── docs/
│   └── refleksi-kelompok.md
│
├── evaluation/
│   ├── screenshots/
│   │   ├── before-pipeline-failed.png
│   │   ├── before-trivy-report.png
│   │   └── after-pipeline-success.png
│   │
│   ├── analysis.md
│   ├── metrics-before.md
│   └── metrics-after.md
│
├── papers/
│   ├── paper-1-zerotrust-cicd.md
│   └── paper-2-zerotrust-financial.md
│
├── presentation/
│
├── research/
│   ├── 01-gap-analysis.md
│   ├── 02-state-of-the-art.md
│   └── 03-design-decisions.md
│
└── README.md
```

---

## 🚀 Menjalankan Pipeline

### 0. Prerequisites (Persiapan)
Sebelum menjalankan pipeline, pastikan hal berikut sudah tersedia:
- Akun GitHub dengan akses ke repository ini.
- Klaster Kubernetes (misalnya Minikube, GKE, atau EKS) yang sudah running.
- `kubectl` yang terkonfigurasi untuk terhubung ke klaster.
- GitHub Secrets yang sudah diatur di `Settings -> Secrets and variables -> Actions`:
  - `KUBECONFIG`: Berisi konten file konfigurasi kubeconfig Anda agar GitHub Actions dapat mendeploy ke klaster.
  - `REGISTRY_USERNAME` & `REGISTRY_PASSWORD`: Untuk autentikasi ke container registry (misalnya Docker Hub atau GHCR).

### 1. Clone Repository

```bash
git clone https://github.com/Nopitrasari29/fpdevopskelompok4-zerotrust.git
cd fpdevopskelompok4-zerotrust
```

### 2. Konfigurasi Deployment
Pastikan file manifest di folder `implementation/` sudah sesuai dengan image registry Anda.

### 3. Push Perubahan
Setelah melakukan perubahan, push ke main branch:

```bash
git add .
git commit -m "update configuration"
git push origin main
```

### 4. Buka GitHub Actions
Masuk ke tab **Actions** di repositori Anda untuk melihat proses:
1.  **Build**: Membangun container image.
2.  **Security Scan**: Menjalankan Trivy untuk pemindaian.
3.  **Deploy**: Melakukan deployment ke klaster (hanya jika security scan sukses).

---

## 🧪 Skenario Pengujian

### Before (Pipeline Konvensional)

Image:

```text
nginx:1.14
```

Hasil:

| Stage | Status |
|---------|---------|
| Build | Success |
| Security Scan | Failed |
| Deploy | Skipped |

Temuan Trivy:

| Severity | Jumlah |
|-----------|---------|
| Critical | 27 |
| High | 50 |
| Total | 77 |

Screenshot:

 ![Before Pipeline Failed](evaluation/screenshots/before-pipeline-failed.png)
 ![Before Trivy Report](evaluation/screenshots/before-trivy-report.png)

---

### After (Zero Trust Aktif)

Image:

```text
nginx:latest
```

Hasil:

| Stage | Status |
|---------|---------|
| Build | Success |
| Security Scan | Success |
| Deploy | Success |

Screenshot:

 ![After Pipeline Success](evaluation/screenshots/after-pipeline-success.png)

---

## 📊 Hasil Pengujian

Implementasi berhasil menunjukkan bahwa:

- Image rentan berhasil dideteksi oleh Trivy.
- Deployment dihentikan ketika ditemukan vulnerability HIGH atau CRITICAL.
- Deployment hanya dapat dijalankan setelah lolos verifikasi keamanan.
- Prinsip Zero Trust berhasil diterapkan pada pipeline CI/CD.

---

## 📚 Referensi

1. Bhardwaj et al. (2025). Zero Trust CI/CD Pipeline: A Blueprint for Secure Software Delivery in Modern DevSecOps.
2. Shin et al. (2025). Enhancing Cloud-Native DevSecOps: A Zero Trust Approach for the Financial Sector.