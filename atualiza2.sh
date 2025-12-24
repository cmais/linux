#!/bin/bash

# ==================================================
# Script de Manutenção do Sistema Linux
# Atualiza sistema, pacotes DEB, Flatpak, Snap
# Remove pacotes órfãos, kernels antigos e cache
# ==================================================

# --- Configuração de Segurança ---
set -Eeuo pipefail

# --- Verificação de Privilégios ---
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como root. Use: sudo ./script.sh"
    exit 1
fi

# --- 1. Atualização do Sistema (APT) ---
echo "Atualizando lista de pacotes..."
apt-get update

echo "Atualizando sistema e pacotes instalados..."
apt-get dist-upgrade -y

# --- 2. Limpeza do Sistema (APT e Kernels Antigos) ---
echo "Removendo pacotes desnecessários e kernels antigos..."
apt-get autoremove --purge -y

echo "Limpando cache de pacotes..."
apt-get clean

# --- 3. Atualização de Formatos de Pacotes Adicionais ---
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y
else
    echo "Flatpak não está instalado. Pulando..."
fi

if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    snap refresh
else
    echo "Snap não está instalado. Pulando..."
fi

# --- 4. Verificação Final ---
echo "Verificando se restaram pacotes para atualizar..."
apt list --upgradable || true

# --- Finalização ---
echo ""
echo "Manutenção concluída com sucesso!"
echo ""

# --- Informações do Sistema (Opcional) ---
if command -v neofetch &> /dev/null; then
    neofetch
fi

