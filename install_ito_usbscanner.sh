#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# IT-ONKEL USB-CHECKER – INSTALLER
# Raspberry Pi OS Bookworm Lite
# ============================================================

if [[ $EUID -ne 0 ]]; then
  echo "❌ Bitte mit sudo ausführen."
  exit 1
fi

echo "🛡️ IT-ONKEL USB-CHECKER – INSTALLATION"
echo "====================================="

# ------------------------------------------------------------
# 1) SYSTEMHÄRTUNG
# ------------------------------------------------------------
echo "🔒 Systemhärtung …"

systemctl disable --now bluetooth.service 2>/dev/null || true
systemctl disable --now avahi-daemon 2>/dev/null || true
systemctl disable --now triggerhappy.service 2>/dev/null || true
systemctl disable --now wpa_supplicant.service 2>/dev/null || true

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true

install -d -m 0700 /mnt/usbscan
install -d -m 0700 /var/log/it-onkel
touch /var/log/it-onkel/usbscan.log
chmod 0600 /var/log/it-onkel/usbscan.log

# ------------------------------------------------------------
# 2) PAKETE
# ------------------------------------------------------------
echo "📦 Pakete installieren …"

apt update
apt install -y \
  clamav clamav-daemon clamav-freshclam \
  yara \
  usbutils \
  util-linux \
  coreutils \
  findutils \
  procps \
  dialog \
  pv \
  rfkill \
  rsyslog \
  console-setup \
  fonts-terminus \
  fbi

# ------------------------------------------------------------
# 3) CLAMAV BASIS
# ------------------------------------------------------------
echo "🦠 ClamAV initialisieren …"

systemctl enable --now clamav-daemon
systemctl disable --now clamav-freshclam 2>/dev/null || true
freshclam 2>/dev/null || true

# ------------------------------------------------------------
# 4) LOGO INSTALLIEREN
# ------------------------------------------------------------
echo "🖼️ IT-Onkel Logo installieren …"

install -d -m 0755 /opt/it-onkel
install -m 0644 ./logo.png /opt/it-onkel/logo.png

# ------------------------------------------------------------
# 5) YARA REGELN
# ------------------------------------------------------------
echo "📜 YARA Regeln installieren …"

install -d -m 0755 /etc/it-onkel/yara

cat > /etc/it-onkel/yara/basic.yar <<'EOF'
rule Suspicious_File_Types
{
  strings:
    $ps  = ".ps1" nocase
    $vbs = ".vbs" nocase
    $js  = ".js"  nocase
    $exe = ".exe" nocase
    $dll = ".dll" nocase
    $lnk = ".lnk" nocase
  condition:
    any of them
}
EOF

# ------------------------------------------------------------
# 6) USB-SCAN SCRIPT
# ------------------------------------------------------------
echo "🧪 Scan-Script installieren …"

cat > /usr/local/sbin/ito-usbscan <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DEV="/dev/$1"
MNT="/mnt/usbscan"
LOG="/var/log/it-onkel/usbscan.log"
LOGO="/opt/it-onkel/logo.png"
DOC_URL="https://wiki.netzhirsch.de/index.php?title=USB-Stick_Richtlinie"
YARA_RULES="/etc/it-onkel/yara/basic.yar"

exec >>"$LOG" 2>&1

broadcast() {
  echo -e "$*"
  for t in /dev/tty{1..6}; do
    [[ -w "$t" ]] && echo -e "$*" > "$t" || true
  done
}

show_logo() {
  for fb in /dev/fb0 /dev/fb1; do
    [[ -e "$fb" ]] && fbi -T 1 -d "$fb" -noverbose -a "$LOGO" || true
  done
}

clear_all() {
  for t in /dev/tty{1..6}; do
    [[ -w "$t" ]] && printf "\033c" > "$t" || true
  done
}

LOCK="/run/ito-usbscan.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

clear_all
show_logo
broadcast ""
broadcast "🛡️ IT-ONKEL USB-CHECKER"
broadcast "======================="
broadcast ""
broadcast "Richtlinie:"
broadcast "$DOC_URL"
broadcast ""
broadcast "🔌 USB erkannt: $DEV"
broadcast ""

# WLAN an → Update
broadcast "🌐 WLAN aktivieren (nur für Updates) …"
rfkill unblock wifi || true
sleep 2

broadcast "🦠 ClamAV Signaturen aktualisieren …"
timeout 180 freshclam || broadcast "⚠️ Update fehlgeschlagen – Offline-Scan"

broadcast "📴 WLAN deaktivieren …"
rfkill block wifi || true
sleep 1

# Mount
broadcast ""
broadcast "💾 USB wird sicher eingebunden (read-only) …"
umount "$MNT" 2>/dev/null || true
mount -o ro,nosuid,nodev,noexec "$DEV" "$MNT" || {
  clear_all
  show_logo
  broadcast "🔴 FEHLER: USB konnte nicht gemountet werden"
  broadcast "➡ Stick NICHT verwenden – IT-Onkel informieren"
  exit 20
}

FILES=$(find "$MNT" -type f 2>/dev/null)
TOTAL=$(echo "$FILES" | wc -l)
COUNT=0
INFECTED=0

# ClamAV Scan
for f in $FILES; do
  COUNT=$((COUNT+1))
  PCT=$((COUNT * 100 / TOTAL))
  clear_all
  show_logo
  broadcast ""
  broadcast "🦠 ClamAV Scan läuft … $PCT % ($COUNT/$TOTAL)"
  broadcast "Datei:"
  broadcast "  $(basename "$f")"

  if clamscan --no-summary "$f" | grep -q FOUND; then
    INFECTED=1
    FOUND="$f"
    break
  fi
done

# YARA Scan (nur wenn sauber)
YARA_HIT=0
if [[ "$INFECTED" -eq 0 ]]; then
  mapfile -t YFILES < <(find "$MNT" -type f \( -iname '*.ps1' -o -iname '*.js' -o -iname '*.vbs' -o -iname '*.exe' -o -iname '*.dll' -o -iname '*.lnk' \) 2>/dev/null)
  for yf in "${YFILES[@]}"; do
    if yara "$YARA_RULES" "$yf" >/dev/null 2>&1; then
      YARA_HIT=1
    fi
  done
fi

umount "$MNT" || true

clear_all
show_logo
broadcast ""
broadcast "🛡️ IT-ONKEL USB-CHECKER"
broadcast "======================="
broadcast ""

if [[ "$INFECTED" -eq 1 ]]; then
  broadcast "🔴 STOPP – MALWARE GEFUNDEN"
  broadcast ""
  broadcast "Datei:"
  broadcast "  $FOUND"
  broadcast ""
  broadcast "➡ USB NICHT verwenden!"
  broadcast "➡ Kennzeichnen und IT-Onkel übergeben."
  exit 10
fi

broadcast "🟢 KEINE MALWARE GEFUNDEN"
broadcast ""

if [[ "$YARA_HIT" -eq 1 ]]; then
  broadcast "⚠️ Hinweis: Auffällige Dateitypen erkannt."
  broadcast "➡ Nur übernehmen, wenn fachlich erforderlich."
fi

broadcast ""
broadcast "➡ USB kann entfernt werden."
exit 0
EOF

chmod 750 /usr/local/sbin/ito-usbscan

# ------------------------------------------------------------
# 7) SYSTEMD SERVICE
# ------------------------------------------------------------
echo "⚙️ systemd Service installieren …"

cat > /etc/systemd/system/ito-usbscan@.service <<'EOF'
[Unit]
Description=IT-Onkel USB Scan (%i)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ito-usbscan %i
TimeoutStartSec=0
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
EOF

systemctl daemon-reload

# ------------------------------------------------------------
# 8) UDEV REGEL
# ------------------------------------------------------------
echo "⚙️ udev Regel installieren …"

cat > /etc/udev/rules.d/99-ito-usbscan.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="block", ENV{ID_BUS}=="usb", ENV{DEVTYPE}=="partition", TAG+="systemd", ENV{SYSTEMD_WANTS}="ito-usbscan@%k.service"
EOF

udevadm control --reload

# ------------------------------------------------------------
# 9) LOGIN-BANNER
# ------------------------------------------------------------
cat > /etc/profile.d/ito-banner.sh <<'EOF'
#!/bin/sh
clear
if command -v fbi >/dev/null 2>&1 && [ -f /opt/it-onkel/logo.png ]; then
  fbi -T 1 -d /dev/fb0 -noverbose -a /opt/it-onkel/logo.png || true
fi
echo "🛡️ IT-ONKEL USB-CHECKER"
echo "======================="
echo
echo "➡ Bitte USB-Stick einstecken"
echo
EOF

chmod +x /etc/profile.d/ito-banner.sh

for n in {1..6}; do
  systemctl enable getty@tty$n.service >/dev/null 2>&1 || true
done

# ------------------------------------------------------------
# 10) WLAN DEFAULT OFF
# ------------------------------------------------------------
rfkill block wifi || true

echo
echo "✅ INSTALLATION ABGESCHLOSSEN"
echo "➡ Bitte neu starten: sudo reboot"
echo
