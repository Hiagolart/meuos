#!/usr/bin/env bash
# Roda uma única vez no primeiro login e aplica o visual. Depois se remove.
sleep 8
TEMA="@TEMA@"; FUNDO="@FUNDO@"; ATALHO="@ATALHO@"
if [[ $TEMA == Dark ]]; then ICONES="WhiteSur-dark"; else ICONES="WhiteSur-light"; fi
[[ -d /usr/share/icons/$ICONES ]] || ICONES="WhiteSur"

x() { xfconf-query -c "$1" -p "$2" --create -t "$3" -s "$4"; }

# Aparência
x xsettings /Net/ThemeName        string "WhiteSur-$TEMA"
x xsettings /Net/IconThemeName    string "$ICONES"
x xsettings /Gtk/CursorThemeName  string "WhiteSur-cursors"
x xsettings /Gtk/FontName         string "Inter 10"
x xsettings /Gtk/MonospaceFontName string "Noto Sans Mono 10"
x xsettings /Xft/Antialias        int 1
x xsettings /Xft/HintStyle        string "hintslight"
x xsettings /Xft/RGBA             string "rgb"

# Janelas: botões à esquerda (fechar, minimizar, maximizar), título centralizado
x xfwm4 /general/theme            string "WhiteSur-$TEMA"
x xfwm4 /general/button_layout    string "CHM|"
x xfwm4 /general/title_alignment  string "center"
x xfwm4 /general/title_font       string "Inter Bold 10"
x xfwm4 /general/use_compositing  bool true
x xfwm4 /general/show_dock_shadow bool false
x xfwm4 /general/vblank_mode      string "glx"

# Área de trabalho limpa + papel de parede
x xfce4-desktop /desktop-icons/style int 0
if [[ -n $FUNDO && -f $FUNDO ]]; then
  for m in $(xrandr --listmonitors | awk 'NR>1{print $NF}'); do
    for w in 0 1 2 3; do
      x xfce4-desktop "/backdrop/screen0/monitor$m/workspace$w/last-image"  string "$FUNDO"
      x xfce4-desktop "/backdrop/screen0/monitor$m/workspace$w/image-style" int 5
    done
  done
  xfdesktop --reload 2>/dev/null || true
fi

# Busca estilo Spotlight
x xfce4-keyboard-shortcuts "/commands/custom/$ATALHO" string "rofi -show drun"

# Dock (Plank)
D="net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/"
gsettings set "$D" position 'bottom'
gsettings set "$D" theme 'Transparent'
gsettings set "$D" icon-size 44
gsettings set "$D" zoom-enabled true
gsettings set "$D" zoom-percent 140
gsettings set "$D" hide-mode 'intelligent'
NAV="firefox-esr.dockitem"; [[ -f /usr/share/applications/google-chrome.desktop ]] && NAV="google-chrome.dockitem"
gsettings set "$D" dock-items "['thunar.dockitem', '$NAV', 'xfce4-terminal.dockitem', 'libreoffice-writer.dockitem', 'mpv.dockitem', 'xfce-settings-manager.dockitem']"

# Pastas padrão (Documentos, Downloads...) em português
xdg-user-dirs-update

# Se remove
rm -f "$HOME/.config/autostart/primeiro-login.desktop"
xfce4-panel -r &
