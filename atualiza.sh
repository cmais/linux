#!/bin/bash

# --- Configuração de Segurança ---
# Encerra o script imediatamente se um comando falhar.
# Isso evita que o sistema seja parcialmente atualizado ou que erros causem problemas maiores.
set -e

# --- 1. Atualização do Sistema Principal (APT) ---
echo "Iniciando a atualização da lista de pacotes..."
sudo apt update

echo "Instalando atualizações de pacotes e do sistema..."
# O '&&' garante que o dist-upgrade só aconteça se o upgrade for bem-sucedido.
sudo apt upgrade -y && sudo apt dist-upgrade -y

# --- 2. Limpeza do Sistema (APT e Kernels) ---
echo "Removendo pacotes desnecessários e kernels antigos..."
# O comando 'autoremove --purge' limpa dependências órfãs e remove arquivos de configuração,
# incluindo versões antigas do Kernel do Linux que não estão mais em uso.
sudo apt autoremove --purge -y

echo "Limpando o cache de pacotes baixados..."
# 'apt-get clean' é a maneira oficial e segura de limpar /var/cache/apt/archives/,
# sendo mais recomendado que 'rm -rf'.
sudo apt-get clean

# --- 3. Atualização de Formatos de Pacotes Adicionais ---
# Atualiza os pacotes Flatpak, se o comando estiver disponível.
if command -v flatpak &> /dev/null; then
    echo "Atualizando pacotes Flatpak..."
    flatpak update -y
else
    echo "Flatpak não está instalado. Pulando..."
fi

# Atualiza os pacotes Snap, se o comando estiver disponível.
if command -v snap &> /dev/null; then
    echo "Atualizando pacotes Snap..."
    sudo snap refresh
else
    echo "Snap não está instalado. Pulando..."
fi


# --- 5. Verificação Final ---
echo "Verificando se restaram pacotes para atualizar..."
# Lista pacotes que, por algum motivo, não foram atualizados.
apt list --upgradable

# --- Mensagem de Finalização ---
echo ""
echo "Sistema atualizado e limpo com sucesso!"
echo ""

# --- Exibição de Informações do Sistema (Opcional) ---
# Verifica se o Neofetch está instalado antes de tentar executá-lo.
if command -v neofetch &> /dev/null; then
    neofetch
fi 
