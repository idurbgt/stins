#!/bin/bash

# Script Instalasi dan Konfigurasi Unbound untuk Split DNS di Debian 12
# Domain lokal: labsiber.xyz
# Forward: DNS-over-TLS (Cloudflare)

echo "======================================"
echo "Instalasi Unbound DNS Server"
echo "======================================"

# Update repository
echo "[1/8] Update repository..."
apt update

# Install Unbound
echo "[2/8] Install Unbound..."
apt install -y unbound unbound-anchor

# Buat direktori log jika belum ada
echo "[3/8] Membuat direktori log..."
mkdir -p /var/log/unbound
chown unbound:unbound /var/log/unbound

# Backup konfigurasi default
echo "[4/8] Backup konfigurasi default..."
if [ -f /etc/unbound/unbound.conf ]; then
    cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.backup
fi

# Download root hints
echo "[5/8] Download root hints..."
wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root

# Generate root key untuk DNSSEC
echo "[6/8] Generate root key untuk DNSSEC..."
unbound-anchor -a /var/lib/unbound/root.key

# Set permission
chown unbound:unbound /var/lib/unbound/root.hints
chown unbound:unbound /var/lib/unbound/root.key

# Pilih konfigurasi
echo ""
echo "======================================"
echo "Pilih tipe konfigurasi:"
echo "1) Dengan local-data langsung (Recommended untuk setup sederhana)"
echo "2) Dengan stub-zone (Untuk authoritative server terpisah)"
echo "======================================"
read -p "Pilihan [1/2]: " choice

case $choice in
    2)
        echo "[7/8] Menggunakan konfigurasi dengan stub-zone..."
        # Copy dari file yang sudah dibuat
        if [ -f /home/claude/unbound.conf ]; then
            cp /home/claude/unbound.conf /etc/unbound/unbound.conf
        else
            echo "Error: File unbound.conf tidak ditemukan!"
            exit 1
        fi
        ;;
    *)
        echo "[7/8] Menggunakan konfigurasi dengan local-data..."
        # Copy dari file yang sudah dibuat
        if [ -f /home/claude/unbound-with-local-data.conf ]; then
            cp /home/claude/unbound-with-local-data.conf /etc/unbound/unbound.conf
        else
            echo "Error: File unbound-with-local-data.conf tidak ditemukan!"
            exit 1
        fi
        ;;
esac

# Ubah permission
chown root:unbound /etc/unbound/unbound.conf
chmod 644 /etc/unbound/unbound.conf

# Test konfigurasi
echo "[8/8] Test konfigurasi..."
unbound-checkconf /etc/unbound/unbound.conf

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "✓ Konfigurasi valid!"
    echo "======================================"
    
    # Restart Unbound
    echo "Restart Unbound service..."
    systemctl restart unbound
    systemctl enable unbound
    
    # Check status
    echo ""
    echo "Status Unbound:"
    systemctl status unbound --no-pager
    
    echo ""
    echo "======================================"
    echo "Instalasi selesai!"
    echo "======================================"
    echo ""
    echo "CATATAN PENTING:"
    echo "1. Edit /etc/unbound/unbound.conf untuk menyesuaikan:"
    echo "   - IP address di local-data sesuai kebutuhan"
    echo "   - Access control sesuai network Anda"
    echo ""
    echo "2. Test DNS dengan perintah:"
    echo "   dig @localhost labsiber.xyz"
    echo "   dig @localhost google.com"
    echo ""
    echo "3. Untuk monitoring:"
    echo "   tail -f /var/log/unbound/unbound.log"
    echo ""
    echo "4. Untuk reload setelah edit config:"
    echo "   systemctl reload unbound"
    echo ""
    echo "5. Untuk test DNS-over-TLS:"
    echo "   dig @1.1.1.1 +tls google.com"
    echo "======================================"
else
    echo ""
    echo "✗ Error dalam konfigurasi!"
    echo "Silakan periksa file /etc/unbound/unbound.conf"
    exit 1
fi
