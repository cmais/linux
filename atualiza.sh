#!/bin/bash

# Atualiza a lista de pacotes e o sistema
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

# Atualiza os pacotes Flatpak
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y
else
    echo "Flatpak não está instalado. Pulando..."
fi

# Atualiza os pacotes Snap
if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    sudo snap refresh
else
    echo "Snap não está instalado. Pulando..."
fi

# Limpeza adicional de caches
sudo rm -rf /var/cache/apt/archives/*
sudo rm -rf ~/.cache/*

# Verifica atualizações do kernel (opcional)
echo "Verificando kernels antigos para remoção..."
sudo apt autoremove --purge -y

# Listar pacotes que não foram atualizados
echo "Verificando pacotes que não foram atualizados..."
apt list --upgradable

# Mensagem de finalização
echo "Sistema atualizado e limpo com sucesso!"

# Exibe Logo
neofetch

