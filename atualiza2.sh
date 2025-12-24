#!/bin/bash

# ==================================================
# Script de Manutenção do Sistema Linux
# Atualiza sistema, pacotes DEB, Flatpak, Snap
# Remove pacotes órfãos, kernels antigos e cache
# ==================================================


# --- Configuração de Segurança ---
set -Eeuo pipefail

# --- Forçar pedido de senha sudo ---
sudo -k
sudo -v

# --- 1. Atualização do Sistema (APT) ---
echo "Atualizando lista de pacotes..."
apt-get update

echo "Atualizando sistema e pacotes instalados..."
apt-get dist-upgrade -y

# --- 2. Limpeza do Sistema ---
echo "Removendo pacotes desnecessários e kernels antigos..."
apt-get autoremove --purge -y

echo "Limpando cache de pacotes..."
apt-get clean

# --- 3. Flatpak ---
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y
else
    echo "Flatpak não está instalado. Pulando..."
fi

# --- 4. Snap ---
if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    snap refresh
else
    echo "Snap não está instalado. Pulando..."
fi

# --- 5. Verificação Final ---
echo "Pacotes ainda atualizáveis:"
apt list --upgradable || true

echo ""
echo "Manutenção concluída com sucesso!"
