# Design Decisions: Security Scanning

> Bagian ini akan diisi oleh Hasan — Jobdesk 1:Setup & Implementasi Security Scan Job

Implementasi pemindaian keamanan (*security scanning*) pada pipeline CI/CD proyek ini menggunakan **Trivy**. Pemilihan Trivy didasarkan pada kapabilitasnya sebagai *tool open-source* yang ringan dan dirancang secara *native* untuk *container image scanning*. 

Pada tahap pemindaian ini, *severity threshold* ditetapkan secara ketat pada tingkat **CRITICAL** dan **HIGH**. Jika Trivy mendeteksi kerentanan pada tingkat tersebut, parameter `exit-code: '1'` akan membuat *pipeline* otomatis gagal (*failed status*). 

Keputusan desain ini merupakan perwujudan langsung dari prinsip *Zero Trust* ("*never trust, always verify*") yang dikemukakan oleh **Bhardwaj dkk. (2025)**. Berdasarkan referensi tersebut, *pipeline* konvensional dengan asumsi *implicit trust* sangat berisiko terhadap injeksi *malware* atau *dependency hijacking*. Pemblokiran otomatis ini adalah bentuk verifikasi keamanan berkelanjutan untuk memastikan tidak ada *image* berisiko tinggi yang lolos ke tahap *deployment*.