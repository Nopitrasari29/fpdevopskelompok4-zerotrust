# Metrics Before — Baseline Testing (Pipeline Konvensional)

## Tujuan Pengujian

Skenario ini mensimulasikan kondisi pipeline CI/CD **sebelum** penerapan prinsip Zero Trust, yaitu kondisi *implicit trust* — artifact hasil build langsung melanjutkan ke tahap deployment **tanpa** verifikasi keamanan apapun di tengah jalan.

Tujuannya adalah membuktikan bahwa pada kondisi ini, image container yang mengandung kerentanan kritis dapat lolos sampai ke tahap deployment tanpa terdeteksi.

## Setup Pengujian

| Item | Detail |
|---|---|
| Branch pengujian | `baseline-before-zerotrust` |
| Image yang diuji | `nginx:1.14` (image lama, dipilih karena dikenal mengandung banyak kerentanan) |
| Konfigurasi pipeline | Job `security-scan` dinonaktifkan; job `deploy` langsung dijalankan setelah job `build` (`needs: build`) |
| Tools pengujian manual | Trivy (dijalankan lewat `docker run aquasec/trivy:latest`, di luar pipeline, hanya untuk pembuktian) |
| Tanggal pengujian | 23 Juni 2026 |

## Hasil Eksekusi Pipeline

| Stage | Status | Durasi |
|---|---|---|
| Build | Success | 6s |
| Security Scan | *(tidak ada / dilewati)* | - |
| Deploy | Success | 2s |
| Notify | Success | 3s |
| **Total durasi pipeline** | **Success** | **22s** |

**Waktu push:** 17:47:40 (23 Juni 2026)
**Waktu pipeline selesai:** ± 18:08:02 (23 Juni 2026), total durasi 22 detik dari push hingga seluruh job selesai.

Tidak ada satu pun titik verifikasi yang menghalangi proses deployment. Image `nginx:1.14` berhasil "ter-deploy" sepenuhnya tanpa pengecekan keamanan apapun.

![alt text](image-1.png)

![alt text](image-2.png)

![alt text](image-3.png)


## Hasil Vulnerability Scan Manual (Pembuktian)

Karena pipeline pada skenario ini tidak melakukan pemeriksaan keamanan, scan dijalankan secara manual di luar pipeline untuk membuktikan tingkat risiko image yang sebenarnya lolos:

```
docker run --rm aquasec/trivy:latest image --severity CRITICAL,HIGH --timeout 10m nginx:1.14
```

**Report Summary:**

| Target | Type | Total Vulnerabilities |
|---|---|---|
| nginx:1.14 (debian 9.8) | debian | 113 |

| Severity | Jumlah |
|---|---|
| CRITICAL | 31 |
| HIGH | 82 |
| **Total** | **113** |

Contoh temuan kritis: `CVE-2022-1664` (dpkg) — severity CRITICAL, sudah memiliki fixed version (1.18.26) namun tetap terpasang versi rentan (1.18.25) pada image yang diuji.

## Prevention Rate

| Metrik | Hasil |
|---|---|
| Vulnerability terdeteksi | 113 (31 Critical, 82 High) |
| Vulnerability yang berhasil diblokir oleh pipeline | 0 |
| **Prevention rate** | **0%** |

Seluruh kerentanan — termasuk 31 kerentanan berstatus CRITICAL — berhasil lolos sampai ke tahap deployment tanpa terdeteksi oleh pipeline, karena tidak ada gate keamanan yang aktif.

![alt text](image.png)

## Kesimpulan Sementara

Pengujian skenario *before* ini membuktikan bahwa pipeline CI/CD konvensional (implicit trust) memiliki celah keamanan nyata: image dengan 113 vulnerability, termasuk 31 berstatus Critical, dapat melewati seluruh tahap pipeline (Build → Deploy → Notify) dalam waktu 22 detik tanpa ada satu pun mekanisme yang memverifikasi keamanannya.

Data ini menjadi baseline pembanding untuk skenario *after* (Jobdesk 4), di mana security scan diaktifkan untuk mengukur apakah kerentanan yang sama dapat dicegah, serta berapa overhead waktu yang ditambahkan oleh proses verifikasi tersebut.
