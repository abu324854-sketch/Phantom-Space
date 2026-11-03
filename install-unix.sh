#!/usr/bin/env bash
# PCloud klienti - macOS va Linux.
# Faqat Oracle serveri:   ./install-unix.sh https://mening-bulutim.duckdns.org admin
# Bepul hisoblar bilan:   ./install-unix.sh https://mening-bulutim.duckdns.org admin "$HOME/P" 10 mega,gdrive,pcl
# Oracle to'lganda yangi fayllar boshqa hisoblarga tushishi uchun: ORACLE_FULL=1 ./install-unix.sh ...
set -euo pipefail

URL="${1:?Server manzilini bering: ./install-unix.sh https://server admin}"
USER_NAME="${2:-admin}"
MOUNT="${3:-$HOME/P}"
CACHE_GB="${4:-10}"
EXTRAS="${5:-}"

echo "1/4 rclone tekshirilmoqda..."
if ! command -v rclone >/dev/null; then
  if [[ "$(uname)" == "Darwin" ]]; then
    command -v brew >/dev/null || { echo "Avval Homebrew o'rnating: https://brew.sh"; exit 1; }
    brew install rclone
    echo "macOS uchun macFUSE ham kerak: brew install --cask macfuse (o'rnatgach tizim sozlamalarida ruxsat bering)"
  else
    curl -fsSL https://rclone.org/install.sh | sudo bash
    sudo apt-get install -y fuse3 2>/dev/null || true
  fi
fi

echo "2/4 Parolni kiriting (ekranda ko'rinmaydi):"
read -rs -p "Bulut paroli: " PW; echo
rclone config create mycloud webdav url "$URL" vendor other user "$USER_NAME" pass "$(rclone obscure "$PW")" >/dev/null
unset PW

REMOTE="mycloud:"
if [[ -n "$EXTRAS" ]]; then
  FIRST="mycloud:"
  [[ "${ORACLE_FULL:-0}" == "1" ]] && FIRST="mycloud::nc"
  UPS="$FIRST"
  IFS=',' read -ra LIST <<< "$EXTRAS"
  for e in "${LIST[@]}"; do
    e="$(echo "$e" | xargs)"
    [[ -z "$e" ]] && continue
    if rclone listremotes | grep -qx "${e}:"; then
      UPS="$UPS ${e}:"
    else
      echo "OGOHLANTIRISH: '$e' nomli ulanish topilmadi, o'tkazib yuborildi (add-free-accounts.md ga qarang)"
    fi
  done
  if [[ "$UPS" != "$FIRST" ]]; then
    rclone config create cloudall union upstreams "$UPS" create_policy ff action_policy epall search_policy ff >/dev/null
    REMOTE="cloudall:"
    echo "Birlashtirilgan hisoblar: $UPS"
  fi
fi

mkdir -p "$MOUNT"
RCLONE="$(command -v rclone)"
ARGS="mount $REMOTE $MOUNT --vfs-cache-mode full --vfs-cache-max-size ${CACHE_GB}G --vfs-cache-max-age 24h --vfs-read-chunk-size 64M --dir-cache-time 10m"

echo "3/4 Avtomatik ishga tushirish sozlanmoqda..."
if [[ "$(uname)" == "Darwin" ]]; then
  PLIST="$HOME/Library/LaunchAgents/com.pcloud.mount.plist"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.pcloud.mount</string>
<key>ProgramArguments</key><array>
<string>$RCLONE</string>
$(for a in $ARGS; do echo "<string>$a</string>"; done)
</array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
</dict></plist>
EOF
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
else
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/pcloud.service" <<EOF
[Unit]
Description=PCloud mount
After=network-online.target

[Service]
Type=simple
ExecStart=$RCLONE $ARGS
ExecStop=/bin/fusermount -u $MOUNT
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now pcloud.service
  loginctl enable-linger "$USER" 2>/dev/null || true
fi

echo "4/4 Tayyor! Bulut shu yerga ulandi: $MOUNT"
