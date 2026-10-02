#!/usr/bin/env bash
set -euo pipefail

# --- Pede a senha sudo logo no início ---
sudo -v

DL="$HOME/Downloads"
mkdir -p "$DL"

# --- Pacotes .deb ---
wget -q --show-progress -N -P "$DL" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
wget -q --show-progress -N -P "$DL" https://github.com/cmais/linux/releases/download/veyon-4.8.3.0/veyon_4.8.3.0-ubuntu.jammy_amd64.deb
wget -q --show-progress -N -P "$DL" https://github.com/cmais/linux/releases/download/deep-lock-1.0.0/deep-lock_1.0.0_all.deb

sudo apt install -y \
    "$DL/google-chrome-stable_current_amd64.deb" \
    "$DL/veyon_4.8.3.0-ubuntu.jammy_amd64.deb" \
    "$DL/deep-lock_1.0.0_all.deb"

# --- Papéis de parede / material de manutenção ---
sudo apt install -y unzip
wget -q --show-progress -N -P "$DL" https://github.com/cmais/linux/releases/download/manut/manut26.zip
unzip -o -q "$DL/manut26.zip" -d "$DL"

# --- Flatpak ---
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

sudo flatpak install -y --noninteractive flathub \
    org.localsend.localsend_app \
    org.luanti.luanti
