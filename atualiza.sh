#!/bin/bash

# ============================================
# Script de atualização e limpeza (versão melhorada)
# Atualiza sistema + Flatpak + Snap
# Remove runtimes não usados do Flatpak
# Remove revisões antigas do Snap
# ============================================

# Encerra o script se algo falhar
set -e

# --- 1. Atualização do sistema ---
echo "Atualizando lista de pacotes..."
sudo apt update

echo "Atualizando sistema..."
sudo apt dist-upgrade -y

# --- 2. Limpeza básica do sistema ---
echo "Removendo pacotes desnecessários e kernels antigos..."
sudo apt autoremove --purge -y

echo "Limpando cache de pacotes..."
sudo apt-get clean

# --- 3. Flatpak ---
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y

    echo "Removendo runtimes Flatpak não utilizados..."
    flatpak uninstall --unused -y
else
    echo "Flatpak não está instalado. Pulando..."
fi

# --- 4. Snap ---
if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    sudo snap refresh

    echo "Removendo revisões antigas do Snap..."
    snap list --all | awk '/disabled/{print $1, $3}' | while read -r nome rev; do
        sudo snap remove "$nome" --revision="$rev"
    done
else
    echo "Snap não está instalado. Pulando..."
fi

# --- 5. Verificação final ---
echo "Verificando pacotes pendentes..."
apt list --upgradable || true

# --- Finalização ---
echo ""
echo "Sistema atualizado e limpo com sucesso!"
echo ""

# --- Informações do sistema (opcional) ---
if command -v neofetch &> /dev/null; then
    neofetch
fi
