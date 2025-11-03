#!/bin/bash

# Script Testing DNS Unbound
# Test split DNS untuk domain lokal dan internet

echo "=========================================="
echo "Testing Unbound DNS Configuration"
echo "=========================================="
echo ""

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check Unbound Service
echo -e "${YELLOW}[Test 1]${NC} Checking Unbound service status..."
if systemctl is-active --quiet unbound; then
    echo -e "${GREEN}✓${NC} Unbound service is running"
else
    echo -e "${RED}✗${NC} Unbound service is NOT running"
    echo "Please start the service: sudo systemctl start unbound"
    exit 1
fi
echo ""

# Test 2: Query Local Domain (labsiber.xyz)
echo -e "${YELLOW}[Test 2]${NC} Testing local domain resolution..."
echo "Query: labsiber.xyz"
result=$(dig @localhost labsiber.xyz +short)
if [ -n "$result" ]; then
    echo -e "${GREEN}✓${NC} labsiber.xyz resolves to: $result"
else
    echo -e "${RED}✗${NC} labsiber.xyz does NOT resolve"
fi
echo ""

# Test 3: Query Local Subdomain
echo -e "${YELLOW}[Test 3]${NC} Testing local subdomain resolution..."
echo "Query: www.labsiber.xyz"
result=$(dig @localhost www.labsiber.xyz +short)
if [ -n "$result" ]; then
    echo -e "${GREEN}✓${NC} www.labsiber.xyz resolves to: $result"
else
    echo -e "${RED}✗${NC} www.labsiber.xyz does NOT resolve"
fi
echo ""

# Test 4: Query Internet Domain
echo -e "${YELLOW}[Test 4]${NC} Testing internet domain resolution..."
echo "Query: google.com"
result=$(dig @localhost google.com +short | head -1)
if [ -n "$result" ]; then
    echo -e "${GREEN}✓${NC} google.com resolves to: $result"
else
    echo -e "${RED}✗${NC} google.com does NOT resolve"
fi
echo ""

# Test 5: Query Another Internet Domain
echo -e "${YELLOW}[Test 5]${NC} Testing another internet domain..."
echo "Query: cloudflare.com"
result=$(dig @localhost cloudflare.com +short | head -1)
if [ -n "$result" ]; then
    echo -e "${GREEN}✓${NC} cloudflare.com resolves to: $result"
else
    echo -e "${RED}✗${NC} cloudflare.com does NOT resolve"
fi
echo ""

# Test 6: Check DNS-over-TLS Connection
echo -e "${YELLOW}[Test 6]${NC} Testing DNS-over-TLS connectivity..."
echo "Checking connection to Cloudflare DNS (1.1.1.1:853)..."
if timeout 5 bash -c "echo > /dev/tcp/1.1.1.1/853" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} DNS-over-TLS port is reachable"
else
    echo -e "${RED}✗${NC} Cannot reach DNS-over-TLS port (may be blocked)"
fi
echo ""

# Test 7: Query Response Time
echo -e "${YELLOW}[Test 7]${NC} Testing query response time..."
echo "Query: google.com"
time_result=$(dig @localhost google.com | grep "Query time:")
echo "$time_result"
echo ""

# Test 8: DNSSEC Validation
echo -e "${YELLOW}[Test 8]${NC} Testing DNSSEC validation..."
echo "Query: cloudflare.com (with DNSSEC)"
dnssec_result=$(dig @localhost cloudflare.com +dnssec +short | tail -1)
if echo "$dnssec_result" | grep -q "RRSIG"; then
    echo -e "${GREEN}✓${NC} DNSSEC is working"
else
    echo -e "${YELLOW}!${NC} DNSSEC signature not found (may be normal for some domains)"
fi
echo ""

# Test 9: Reverse DNS Lookup
echo -e "${YELLOW}[Test 9]${NC} Testing reverse DNS lookup..."
echo "Query: Reverse lookup for local IP"
# Ambil IP pertama dari labsiber.xyz
local_ip=$(dig @localhost labsiber.xyz +short | head -1)
if [ -n "$local_ip" ]; then
    reverse_result=$(dig @localhost -x $local_ip +short)
    if [ -n "$reverse_result" ]; then
        echo -e "${GREEN}✓${NC} Reverse DNS for $local_ip: $reverse_result"
    else
        echo -e "${YELLOW}!${NC} No reverse DNS configured for $local_ip"
    fi
else
    echo -e "${RED}✗${NC} Cannot get local IP for reverse lookup test"
fi
echo ""

# Test 10: Cache Test
echo -e "${YELLOW}[Test 10]${NC} Testing DNS cache..."
echo "First query (uncached):"
time dig @localhost example.com +short > /dev/null
echo "Second query (should be cached):"
time dig @localhost example.com +short > /dev/null
echo -e "${GREEN}✓${NC} Cache test completed (second query should be faster)"
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "✓ - All basic tests completed"
echo ""
echo "Additional manual tests you can run:"
echo "1. dig @localhost labsiber.xyz ANY"
echo "2. dig @localhost www.labsiber.xyz +trace"
echo "3. dig @localhost google.com +stats"
echo "4. sudo tail -f /var/log/unbound/unbound.log"
echo ""
echo "To set this DNS as system default:"
echo "1. Edit /etc/resolv.conf"
echo "2. Add: nameserver 127.0.0.1"
echo "Or use systemd-resolved:"
echo "   sudo systemctl edit systemd-resolved"
echo "   [Resolve]"
echo "   DNS=127.0.0.1"
echo "=========================================="
