#!/bin/bash

# ============================================
# Script simples de atualização e limpeza
# ============================================

# Encerra o script se algo falhar
set -e

# --- 1. Atualização do sistema ---
echo "Atualizando lista de pacotes..."
sudo apt update

echo "Atualizando sistema..."
# dist-upgrade cobre o upgrade normal
sudo apt dist-upgrade -y

# --- 2. Limpeza do sistema ---
echo "Removendo pacotes desnecessários e kernels antigos..."
sudo apt autoremove --purge -y

echo "Limpando cache de pacotes..."
# Forma mais conservadora para scripts
sudo apt-get clean

# --- 3. Atualização de Flatpak ---
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y
else
    echo "Flatpak não está instalado. Pulando..."
fi

# --- 4. Atualização de Snap ---
if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    sudo snap refresh
else
    echo "Snap não está instalado. Pulando..."
fi

# --- 5. Verificação final ---
echo "Verificando pacotes pendentes..."
# Não deixa o script falhar nesta etapa
apt list --upgradable || true

# --- Finalização ---
echo ""
echo "Sistema atualizado e limpo com sucesso!"
echo ""

# --- Informações do sistema (opcional) ---
if command -v neofetch &> /dev/null; then
    neofetch
fi
