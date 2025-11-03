# Dokumentasi Konfigurasi Unbound Split DNS dengan DNS-over-TLS
## Debian 12 - Domain: labsiber.xyz

---

## 📋 Daftar Isi
1. [Penjelasan Konfigurasi](#penjelasan-konfigurasi)
2. [Instalasi](#instalasi)
3. [Testing](#testing)
4. [Troubleshooting](#troubleshooting)
5. [Customisasi](#customisasi)

---

## 🔧 Penjelasan Konfigurasi

### Cara Kerja Split DNS:
- **Domain labsiber.xyz** → Diselesaikan secara lokal dengan IP private
- **Domain lainnya** → Diteruskan ke internet via DNS-over-TLS (Cloudflare)

### Komponen Utama:

#### 1. **Server Configuration**
```
interface: 0.0.0.0          # Listen di semua interface
port: 53                    # Port DNS standard
```

#### 2. **Access Control**
```
access-control: 127.0.0.0/8 allow       # Localhost
access-control: 10.0.0.0/8 allow        # Private network
access-control: 192.168.0.0/16 allow    # Private network
access-control: 0.0.0.0/0 refuse        # Block semua yang lain
```

**⚠️ SESUAIKAN** dengan subnet network Anda!

#### 3. **Local Zone (labsiber.xyz)**
```
local-zone: "labsiber.xyz." static
local-data: "www.labsiber.xyz. IN A 192.168.1.10"
```

**⚠️ SESUAIKAN** IP address dengan server Anda!

#### 4. **DNS-over-TLS Forwarding**
```
forward-zone:
    name: "."
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-tls-upstream: yes
```

Semua query non-lokal akan diteruskan via TLS ke Cloudflare.

---

## 🚀 Instalasi

### Metode 1: Menggunakan Script Otomatis (Recommended)

```bash
# Download atau copy script install-unbound.sh
chmod +x install-unbound.sh

# Jalankan sebagai root
sudo ./install-unbound.sh
```

Script akan:
- ✅ Install Unbound
- ✅ Download root hints
- ✅ Setup DNSSEC
- ✅ Konfigurasi split DNS
- ✅ Enable dan start service

### Metode 2: Manual

```bash
# 1. Update sistem
sudo apt update

# 2. Install Unbound
sudo apt install -y unbound unbound-anchor

# 3. Download root hints
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root

# 4. Generate root key
sudo unbound-anchor -a /var/lib/unbound/root.key

# 5. Buat direktori log
sudo mkdir -p /var/log/unbound
sudo chown unbound:unbound /var/log/unbound

# 6. Copy konfigurasi
sudo cp unbound-with-local-data.conf /etc/unbound/unbound.conf

# 7. Set permission
sudo chown root:unbound /etc/unbound/unbound.conf
sudo chmod 644 /etc/unbound/unbound.conf

# 8. Test konfigurasi
sudo unbound-checkconf

# 9. Restart service
sudo systemctl restart unbound
sudo systemctl enable unbound

# 10. Check status
sudo systemctl status unbound
```

---

## 🧪 Testing

### 1. Test Query Domain Lokal

```bash
# Test domain utama
dig @localhost labsiber.xyz

# Test subdomain
dig @localhost www.labsiber.xyz
dig @localhost mail.labsiber.xyz

# Dengan detail
dig @localhost labsiber.xyz +short
```

**Expected Output:**
```
labsiber.xyz.           IN      A       192.168.1.10
```

### 2. Test Query Domain Internet

```bash
# Test query ke internet
dig @localhost google.com

# Test dengan trace
dig @localhost facebook.com +trace
```

**Expected Output:**
Harus return IP public dari domain tersebut.

### 3. Test DNS-over-TLS

```bash
# Test koneksi TLS
dig @localhost cloudflare.com

# Check log untuk verifikasi TLS
sudo tail -f /var/log/unbound/unbound.log
```

### 4. Test Reverse DNS

```bash
# Test PTR record
dig @localhost -x 192.168.1.10
```

### 5. Benchmark Performance

```bash
# Install dnsperf
sudo apt install dnsperf

# Test performance
dnsperf -s localhost -d /tmp/queries.txt
```

---

## 🔍 Troubleshooting

### Problem 1: Service Gagal Start

**Cek error:**
```bash
sudo systemctl status unbound
sudo journalctl -u unbound -n 50
```

**Solusi umum:**
```bash
# Test syntax config
sudo unbound-checkconf /etc/unbound/unbound.conf

# Cek port conflict
sudo netstat -tulpn | grep :53
sudo lsof -i :53
```

### Problem 2: Query Timeout

**Cek:**
```bash
# Pastikan service running
sudo systemctl is-active unbound

# Test langsung ke server
dig @127.0.0.1 google.com

# Cek firewall
sudo iptables -L -n | grep 53
```

### Problem 3: Domain Lokal Tidak Resolve

**Cek:**
```bash
# Verifikasi konfigurasi local-zone
sudo grep -A 20 "local-zone" /etc/unbound/unbound.conf

# Test dengan verbose
dig @localhost labsiber.xyz +trace

# Cek log
sudo tail -100 /var/log/unbound/unbound.log
```

### Problem 4: DNS-over-TLS Tidak Bekerja

**Cek:**
```bash
# Test koneksi ke server TLS
openssl s_client -connect 1.1.1.1:853

# Cek log Unbound
sudo grep -i tls /var/log/unbound/unbound.log

# Cek network/firewall
sudo tcpdump -i any port 853
```

### Problem 5: Permission Denied

**Fix permission:**
```bash
sudo chown unbound:unbound /var/lib/unbound/root.hints
sudo chown unbound:unbound /var/lib/unbound/root.key
sudo chown unbound:unbound /var/log/unbound -R
sudo chmod 644 /etc/unbound/unbound.conf
```

---

## ⚙️ Customisasi

### 1. Menambah Record Baru

Edit `/etc/unbound/unbound.conf`:

```bash
# A Record
local-data: "app.labsiber.xyz. IN A 192.168.1.100"

# CNAME
local-data: "blog.labsiber.xyz. IN CNAME www.labsiber.xyz."

# MX Record
local-data: "labsiber.xyz. IN MX 5 mail.labsiber.xyz."

# TXT Record (SPF)
local-data: "labsiber.xyz. IN TXT 'v=spf1 mx a ~all'"

# AAAA (IPv6)
local-data: "www.labsiber.xyz. IN AAAA 2001:db8::1"
```

Reload config:
```bash
sudo systemctl reload unbound
```

### 2. Mengganti DNS Upstream

**Cloudflare (Default):**
```
forward-addr: 1.1.1.1@853#cloudflare-dns.com
forward-addr: 1.0.0.1@853#cloudflare-dns.com
```

**Quad9:**
```
forward-addr: 9.9.9.9@853#dns.quad9.net
forward-addr: 149.112.112.112@853#dns.quad9.net
```

**Google:**
```
forward-addr: 8.8.8.8@853#dns.google
forward-addr: 8.8.4.4@853#dns.google
```

### 3. Menambah Access Control

```bash
# Untuk subnet baru
access-control: 10.10.0.0/16 allow
access-control: 172.20.0.0/24 allow

# Block specific IP
access-control: 192.168.1.100/32 refuse
```

### 4. Enable Query Logging (Debugging)

Edit config:
```
verbosity: 2
log-queries: yes
log-replies: yes
```

**⚠️ Warning:** Logging menggunakan banyak disk space!

Reload:
```bash
sudo systemctl reload unbound
```

### 5. Performance Tuning

Untuk server dengan RAM besar:
```
# Increase cache
rrset-cache-size: 512m
msg-cache-size: 256m

# More threads
num-threads: 8

# Increase slabs
msg-cache-slabs: 16
rrset-cache-slabs: 16
```

### 6. Menambah Domain Lokal Lainnya

```bash
# Domain kedua: internal.local
local-zone: "internal.local." static
local-data: "server.internal.local. IN A 10.0.0.50"
```

---

## 📊 Monitoring

### Check Statistics

```bash
# Show statistics
sudo unbound-control stats_noreset

# Dump cache
sudo unbound-control dump_cache

# Flush cache
sudo unbound-control flush labsiber.xyz
```

### Log Monitoring

```bash
# Real-time log
sudo tail -f /var/log/unbound/unbound.log

# Search specific domain
sudo grep "google.com" /var/log/unbound/unbound.log

# Count queries
sudo grep "query" /var/log/unbound/unbound.log | wc -l
```

### Performance Monitoring

```bash
# Check memory usage
sudo ps aux | grep unbound

# Check cache hit rate
sudo unbound-control stats | grep cache

# Network connections
sudo netstat -anp | grep unbound
```

---

## 🔐 Security Best Practices

1. **Batasi Access Control** - Hanya allow network yang diperlukan
2. **Enable DNSSEC** - Sudah enabled by default
3. **Gunakan DNS-over-TLS** - Untuk privacy dan security
4. **Regular Update** - Update Unbound dan root hints secara berkala
5. **Monitor Logs** - Periksa log untuk aktivitas mencurigakan
6. **Disable Logging** - Di production untuk privacy

---

## 📝 Maintenance

### Update Root Hints (Setiap 6 bulan)

```bash
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
sudo systemctl reload unbound
```

### Update DNSSEC Keys

```bash
sudo unbound-anchor -a /var/lib/unbound/root.key
sudo systemctl restart unbound
```

### Backup Configuration

```bash
sudo cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.backup-$(date +%Y%m%d)
```

### Log Rotation

Edit `/etc/logrotate.d/unbound`:
```
/var/log/unbound/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl reload unbound
    endscript
}
```

---

## 📞 Support

Jika ada masalah:
1. Check log: `sudo journalctl -u unbound -n 100`
2. Test config: `sudo unbound-checkconf`
3. Verify DNS: `dig @localhost labsiber.xyz`

---

**Dibuat untuk:** Debian 12  
**Tanggal:** 2025  
**Domain:** labsiber.xyz  
**DNS Upstream:** Cloudflare DNS-over-TLS
