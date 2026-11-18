#!/usr/bin/env bash
# ============================================================
#  Instalador do sistema — roda num Debian 13 mínimo (sem desktop)
#  Uso:  sudo ./instalar.sh            (ou, como root: ./instalar.sh SEU_USUARIO)
# ============================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$DIR/config.sh"

verde() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
aviso() { printf '\033[1;33m[aviso] %s\033[0m\n' "$*"; }
erro()  { printf '\033[1;31m[erro] %s\033[0m\n' "$*"; exit 1; }

[[ $EUID -eq 0 ]] || erro "Rode como root:  sudo ./instalar.sh   (ou 'su -' e depois ./instalar.sh SEU_USUARIO)"
grep -q 'VERSION_CODENAME=trixie' /etc/os-release 2>/dev/null || aviso "Feito para Debian 13 (trixie). Seguindo mesmo assim..."

# Descobre o usuário principal
USUARIO="${1:-${SUDO_USER:-}}"
[[ -z "$USUARIO" || "$USUARIO" == "root" ]] && USUARIO="$(getent passwd 1000 | cut -d: -f1 || true)"
[[ -n "$USUARIO" ]] || erro "Não achei seu usuário. Rode: ./instalar.sh SEU_USUARIO"
CASA="$(getent passwd "$USUARIO" | cut -d: -f6)"
[[ -d "$CASA" ]] || erro "Pasta do usuário $USUARIO não encontrada."
verde "Instalando $NOME_SISTEMA $VERSAO para o usuário: $USUARIO"

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8   # apt em inglês: o filtro de pacotes procura "Candidate:"
LOG=/var/log/instalar-sistema.log
exec > >(tee -a "$LOG") 2>&1

# Instala só os pacotes que existem no repositório (evita travar por 1 nome errado)
instalar() {
  local ok=()
  for p in "$@"; do
    cand="$(LC_ALL=C apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2}')"
    if [[ -n "$cand" && "$cand" != "(none)" ]]; then ok+=("$p")
    else aviso "pacote não encontrado, pulando: $p"; fi
  done
  if ((${#ok[@]})); then apt-get install -y "${ok[@]}"; fi
}

# ------------------------------------------------------------
verde "1/9  Repositórios (contrib, non-free e firmware)"
# ------------------------------------------------------------
if [[ -f /etc/apt/sources.list ]]; then
  sed -i -E '/^deb cdrom:/s/^/# /' /etc/apt/sources.list
  sed -i -E 's/^(deb(-src)? +[^ ]+ +[^ ]+) .*/\1 main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi
for f in /etc/apt/sources.list.d/*.sources; do
  if [[ -f $f ]]; then sed -i -E 's/^Components:.*/Components: main contrib non-free non-free-firmware/' "$f"; fi
done
apt-get update
apt-get full-upgrade -y

# ------------------------------------------------------------
verde "2/9  Base gráfica + XFCE"
# ------------------------------------------------------------
instalar xorg xfce4 xfce4-terminal xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin \
  xfce4-power-manager xfce4-notifyd xfce4-screenshooter xfce4-taskmanager \
  thunar-archive-plugin thunar-volman gvfs-backends file-roller \
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
  network-manager network-manager-gnome blueman \
  pipewire-audio wireplumber pavucontrol \
  polkitd lxpolkit dbus-x11 xdg-user-dirs xdg-utils \
  sudo git curl wget unzip sassc libglib2.0-dev-bin dconf-cli

# Wi-Fi/Bluetooth/vídeo de notebooks Dell (Intel, Realtek, Broadcom)
instalar firmware-linux firmware-misc-nonfree firmware-iwlwifi firmware-realtek \
  firmware-atheros firmware-brcm80211 intel-microcode

# ------------------------------------------------------------
verde "3/9  Apps do dia a dia"
# ------------------------------------------------------------
instalar firefox-esr firefox-esr-l10n-pt-br mpv ristretto mousepad galculator \
  plank rofi fastfetch fonts-inter fonts-noto fonts-noto-color-emoji \
  fonts-liberation2 ttf-mscorefonts-installer
if [[ $INSTALAR_CHROME == 1 ]]; then
  wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y /tmp/chrome.deb || aviso "Chrome não instalado (sem internet?)"
  rm -f /tmp/chrome.deb
fi
if [[ $INSTALAR_OFFICE == 1 ]]; then
  instalar libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3 libreoffice-l10n-pt-br
fi
if [[ $INSTALAR_FLATPAK == 1 ]]; then
  instalar flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || aviso "Flathub não adicionado (sem internet?)"
fi
usermod -aG sudo "$USUARIO" || true

# ------------------------------------------------------------
verde "4/9  Vídeo por GPU (Intel) — vídeo liso e menos bateria"
# ------------------------------------------------------------
instalar intel-media-va-driver-non-free i965-va-driver vainfo mesa-va-drivers

# ------------------------------------------------------------
verde "5/9  Visual estilo Mac (tema WhiteSur)"
# ------------------------------------------------------------
TMP="$(mktemp -d)"
clonar() { git clone --depth 1 "https://github.com/vinceliuice/$1.git" "$TMP/$1"; }
if clonar WhiteSur-gtk-theme; then
  (cd "$TMP/WhiteSur-gtk-theme" && ./install.sh -d /usr/share/themes) || aviso "falha no tema GTK"
fi
if clonar WhiteSur-icon-theme; then
  (cd "$TMP/WhiteSur-icon-theme" && ./install.sh -d /usr/share/icons) || aviso "falha nos ícones"
fi
if clonar WhiteSur-cursors; then
  (cd "$TMP/WhiteSur-cursors" && ./install.sh) || aviso "falha nos cursores"
fi
mkdir -p /usr/share/backgrounds/sistema
if clonar WhiteSur-wallpapers; then
  PAPEL="$(find "$TMP/WhiteSur-wallpapers" -type f \( -iname '*whitesur*.jpg' -o -iname '*whitesur*.png' \) | sort | head -n1)"
  if [[ -n "$PAPEL" ]]; then cp "$PAPEL" "/usr/share/backgrounds/sistema/fundo.${PAPEL##*.}"; fi
fi
rm -rf "$TMP"
FUNDO="$(ls /usr/share/backgrounds/sistema/fundo.* 2>/dev/null | head -n1 || true)"

# Logo do sistema (círculo com a inicial do nome)
INICIAL="${NOME_SISTEMA:0:1}"
cat > /usr/share/pixmaps/sistema-logo.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#5ac8fa"/><stop offset="1" stop-color="#5856d6"/></linearGradient></defs>
  <circle cx="64" cy="64" r="60" fill="url(#g)"/>
  <text x="64" y="84" font-family="Inter, sans-serif" font-size="60" font-weight="700"
        text-anchor="middle" fill="#fff">${INICIAL}</text>
</svg>
EOF

# Tela de login
cat > /etc/lightdm/lightdm-gtk-greeter.conf <<EOF
[greeter]
theme-name = WhiteSur-Dark
icon-theme-name = WhiteSur-dark
cursor-theme-name = WhiteSur-cursors
font-name = Inter 11
${FUNDO:+background = $FUNDO}
default-user-image = /usr/share/pixmaps/sistema-logo.svg
indicators = ~host;~spacer;~clock;~spacer;~power
clock-format = %a, %d %b  %H:%M
EOF

# ------------------------------------------------------------
verde "6/9  Configurações do usuário (barra, dock, busca, atalhos)"
# ------------------------------------------------------------
aplicar_config() {   # $1 = pasta home destino
  local H="$1"
  mkdir -p "$H/.config/xfce4/xfconf/xfce-perchannel-xml" "$H/.config/plank/dock1/launchers" \
           "$H/.config/rofi" "$H/.config/mpv" "$H/.config/autostart" "$H/.local/bin"
  cp "$DIR/arquivos/xfce/xfce4-panel.xml"       "$H/.config/xfce4/xfconf/xfce-perchannel-xml/"
  cp "$DIR/arquivos/plank/"*.dockitem           "$H/.config/plank/dock1/launchers/"
  cp "$DIR/arquivos/rofi/"*                     "$H/.config/rofi/"
  cp "$DIR/arquivos/mpv/mpv.conf"               "$H/.config/mpv/"
  cp "$DIR/arquivos/xfce/plank.desktop"         "$H/.config/autostart/"
  cp "$DIR/arquivos/xfce/primeiro-login.desktop" "$H/.config/autostart/"
  sed -e "s|@TEMA@|$TEMA|g" -e "s|@FUNDO@|$FUNDO|g" -e "s|@ATALHO@|$ATALHO_BUSCA|g" \
      "$DIR/arquivos/xfce/primeiro-login.sh" > "$H/.local/bin/primeiro-login.sh"
  chmod +x "$H/.local/bin/primeiro-login.sh"
}
aplicar_config "$CASA"
chown -R "$USUARIO:" "$CASA/.config" "$CASA/.local"
aplicar_config /etc/skel        # novos usuários já nascem configurados

# ------------------------------------------------------------
verde "7/9  Otimizações (RAM, SSD, bateria, boot)"
# ------------------------------------------------------------
instalar zram-tools tlp tlp-rdw
cat > /etc/default/zramswap <<'EOF'
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF
cat > /etc/sysctl.d/90-fluidez.conf <<'EOF'
vm.swappiness=100
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10
EOF
systemctl enable zramswap.service tlp.service fstrim.timer || true
systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || true   # tlp cuida disso
systemctl disable ModemManager.service 2>/dev/null || true
# Logs não crescem infinito
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=100M\n' > /etc/systemd/journald.conf.d/limite.conf
# Boot rápido e silencioso
sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i -E 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3"/' /etc/default/grub

# ------------------------------------------------------------
verde "8/9  Identidade: $NOME_SISTEMA"
# ------------------------------------------------------------
sed -i -E "s/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR=\"$NOME_SISTEMA\"/" /etc/default/grub
# os-release próprio, protegido contra atualizações do Debian (dpkg-divert)
if [[ -z "$(dpkg-divert --list /usr/lib/os-release)" ]]; then
  dpkg-divert --add --rename --divert /usr/lib/os-release.debian /usr/lib/os-release
fi
sed -E -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"$NOME_SISTEMA $VERSAO\"/" \
       -e "s/^NAME=.*/NAME=\"$NOME_SISTEMA\"/" \
       /usr/lib/os-release.debian > /usr/lib/os-release
update-grub

# ------------------------------------------------------------
verde "9/9  Limpeza"
# ------------------------------------------------------------
systemctl set-default graphical.target
apt-get autoremove -y && apt-get clean

verde "Pronto! Reinicie com:  sudo reboot"
echo "Log completo em: $LOG"
