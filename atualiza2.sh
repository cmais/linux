 #!/bin/bash

# ==================================================
# Script de Manutenção do Sistema Linux
# ==================================================

# --- Configuração de Segurança ---
set -Eeuo pipefail

# --- Auto-elevação de privilégios ---
if [[ $EUID -ne 0 ]]; then
    echo "Privilégios administrativos necessários. Solicitando sudo..."
    exec sudo "$0" "$@"
fi

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

# --- 3. Atualização de Flatpak ---
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y || echo "Nenhum Flatpak para atualizar."
else
    echo "Flatpak não está instalado. Pulando..."
fi

# --- 4. Atualização de Snap ---
if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    snap refresh
else
    echo "Snap não está instalado. Pulando..."
fi

# --- 5. Verificação Final ---
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
