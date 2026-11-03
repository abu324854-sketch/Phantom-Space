#!/usr/bin/env bash
# Oracle Cloud (Ubuntu) serverida ishga tushiring:  sudo bash oracle-setup.sh
# Natija: https://DOMEN manzilida parol bilan himoyalangan bulut (WebDAV), 200 GB disk.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "sudo bilan ishga tushiring: sudo bash oracle-setup.sh"; exit 1; }

read -rp "Domen (masalan: mening-bulutim.duckdns.org): " DOMAIN
read -rp "Login [admin]: " CUSER; CUSER="${CUSER:-admin}"
read -rsp "Parol (kamida 12 belgi): " CPASS; echo
[[ ${#CPASS} -ge 12 ]] || { echo "Parol juda qisqa."; exit 1; }
[[ -n "$DOMAIN" ]] || { echo "Domen kerak."; exit 1; }

export DEBIAN_FRONTEND=noninteractive
echo "1/5 Paketlar o'rnatilmoqda..."
apt-get update -y
apt-get install -y curl gpg debian-keyring debian-archive-keyring apt-transport-https iptables-persistent

echo "2/5 rclone o'rnatilmoqda..."
command -v rclone >/dev/null || curl -fsSL https://rclone.org/install.sh | bash

echo "3/5 Caddy (HTTPS) o'rnatilmoqda..."
if ! command -v caddy >/dev/null; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -y
  apt-get install -y caddy
fi

echo "4/5 Bulut xizmati sozlanmoqda..."
id pcloud >/dev/null 2>&1 || useradd --system --home /srv/pcloud --shell /usr/sbin/nologin pcloud
mkdir -p /srv/pcloud
chown pcloud:pcloud /srv/pcloud

umask 077
cat > /etc/pcloud.env <<EOF
RCLONE_USER=$CUSER
RCLONE_PASS=$CPASS
EOF
chown root:pcloud /etc/pcloud.env
chmod 640 /etc/pcloud.env

cat > /etc/systemd/system/pcloud.service <<'EOF'
[Unit]
Description=PCloud WebDAV server
After=network-online.target
Wants=network-online.target

[Service]
User=pcloud
EnvironmentFile=/etc/pcloud.env
ExecStart=/usr/bin/rclone serve webdav /srv/pcloud --addr 127.0.0.1:8080 --dir-cache-time 5m
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/caddy/Caddyfile <<EOF
$DOMAIN {
    reverse_proxy 127.0.0.1:8080
}
EOF

echo "5/5 Xizmatlar va xavfsizlik devori sozlanmoqda..."
iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 443 -j ACCEPT
netfilter-persistent save

systemctl daemon-reload
systemctl enable --now pcloud
systemctl restart caddy

echo
echo "Tayyor. Tekshirish:  systemctl status pcloud caddy"
echo "MUHIM: Oracle konsolida 80 va 443 portlarni ham oching (Security List -> Ingress Rules)."
echo "Kompyuteringizdan ulanish manzili: https://$DOMAIN   login: $CUSER"
