#!/bin/bash

# ============================================
# Script de Atualização e Limpeza do Sistema
# ============================================

# Encerra o script se algum comando falhar
set -e

# --- 1. Atualização do Sistema (APT) ---
echo "Atualizando lista de pacotes..."
sudo apt update

echo "Atualizando sistema e pacotes instalados..."
# dist-upgrade já engloba o upgrade
sudo apt dist-upgrade -y

# --- 2. Limpeza do Sistema ---
echo "Removendo pacotes desnecessários e kernels antigos..."
sudo apt autoremove --purge -y

echo "Limpando cache de pacotes..."
sudo apt clean

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

# --- 5. Verificação Final ---
echo "Verificando se restaram pacotes para atualizar..."
apt list --upgradable || true

# --- Finalização ---
echo ""
echo "Sistema atualizado e limpo com sucesso!"
echo ""

# --- Informações do Sistema (Opcional) ---
if command -v neofetch &> /dev/null; then
    neofetch
fi
