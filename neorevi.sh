#!/bin/bash

# --- Definição de Cores ---
# Usamos 'tput' para melhor compatibilidade com diferentes terminais.
if command -v tput &> /dev/null; then
    NC=$(tput sgr0)      # Sem Cor (Reset)
    BOLD=$(tput bold)    # Negrito
    RED=$(tput setaf 1)  # Vermelho
    GREEN=$(tput setaf 2)# Verde
    YELLOW=$(tput setaf 3)# Amarelo2
    BLUE=$(tput setaf 4) # Azul
    CYAN=$(tput setaf 6) # Ciano2
else
    # Fallback para códigos ANSI brutos se 'tput' não estiver disponível
    NC='\033[0m'
    BOLD='\033[1m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
fi

# --- Combinações de Cores ---
HEADER="${BOLD}${CYAN}"    # Cabeçalho da Seção (Negrito Ciano)
SUCCESS="${BOLD}${GREEN}"  # Mensagem de Sucesso (Negrito Verde)
INFO="${YELLOW}"     # Mensagem de Informação (Amarelo)
CMD_INFO="${BLUE}"   # Informação de Comando (Azul)


# --- Configuração de Segurança ---
# Encerra o script imediatamente se um comando falhar (exit on error).
# Isso evita que o sistema seja parcialmente atualizado ou que erros causem problemas maiores.
set -e

echo -e "${HEADER}--- Iniciando Script de Atualização e Limpeza ---${NC}"

# --- 1. Atualização do Sistema Principal (APT) ---
echo -e "\n${HEADER}--- 1. Atualização do Sistema Principal (APT) ---${NC}"
echo -e "${INFO}Iniciando a atualização da lista de pacotes...${NC}"
sudo apt update

echo -e "\n${INFO}Instalando atualizações de pacotes e do sistema...${NC}"
# O '&&' garante que o dist-upgrade só aconteça se o upgrade for bem-sucedido.
sudo apt upgrade -y && sudo apt dist-upgrade -y

# --- 2. Limpeza do Sistema (APT e Kernels) ---
echo -e "\n${HEADER}--- 2. Limpeza Segura do Sistema (APT) ---${NC}"
echo -e "${INFO}Removendo pacotes desnecessários e kernels antigos...${NC}"
# O comando 'autoremove --purge' limpa dependências órfãs e remove arquivos de configuração,
# incluindo versões antigas do Kernel do Linux que não estão mais em uso.
# Esta é a forma segura de limpar o sistema.
sudo apt autoremove --purge -y

echo -e "\n${INFO}Limpando o cache de pacotes baixados (/var/cache/apt/archives/)...${NC}"
# 'apt-get clean' é a maneira oficial e segura de limpar o cache do APT.
sudo apt-get clean

# --- 3. Atualização de Formatos de Pacotes Adicionais ---
echo -e "\n${HEADER}--- 3. Atualização de Pacotes Adicionais ---${NC}"

# Atualiza os pacotes Flatpak, se o comando estiver disponível.
if command -v flatpak &> /dev/null; then
    echo -e "${INFO}Atualizando pacotes Flatpak...${NC}"
    flatpak update -y
else
    echo -e "${CMD_INFO}Flatpak não está instalado. Pulando...${NC}"
fi

# Atualiza os pacotes Snap, se o comando estiver disponível.
if command -v snap &> /dev/null; then
    echo -e "\n${INFO}Atualizando pacotes Snap...${NC}"
    sudo snap refresh
else
    echo -e "${CMD_INFO}Snap não está instalado. Pulando...${NC}"
fi

# --- 4. Limpeza de Cache do Usuário (REMOVIDO) ---
echo -e "\n${HEADER}--- 4. Limpeza de Cache do Usuário (REMOVIDO) ---${NC}"
echo -e "${CMD_INFO}A seção de limpeza de cache de usuário (~/.cache) foi removida.${NC}"
echo -e "${CMD_INFO}Esta é uma operação arriscada para ser automatizada${NC}"
echo -e "${CMD_INFO}e pode causar instabilidade nas aplicações em execução.${NC}"

# --- 5. Verificação Final ---
echo -e "\n${HEADER}--- 5. Verificação Final ---${NC}"
echo -e "${INFO}Verificando se restaram pacotes para atualizar...${NC}"
# Captura a saída de 'apt list --upgradable' e remove o cabeçalho "Listing..."
UPGRADABLE_PACKAGES=$(apt list --upgradable 2>/dev/null | grep -v "Listing...")

if [ -n "$UPGRADABLE_PACKAGES" ]; then
    echo -e "${INFO}Atenção! Os seguintes pacotes, por algum motivo, não foram atualizados:${NC}"
    echo -e "${YELLOW}$UPGRADABLE_PACKAGES${NC}"
else
    echo -e "${SUCCESS}Nenhum pacote pendente. O sistema está 100% atualizado.${NC}"
fi

# --- Mensagem de Finalização ---
echo -e "\n${HEADER}--- Finalização ---${NC}"
echo -e "${SUCCESS}Sistema atualizado e limpo com sucesso!${NC}"

# --- Exibição de Informações do Sistema (Opcional) ---
# Verifica se o Neofetch está instalado antes de tentar executá-lo.
if command -v neofetch &> /dev/null; then
    echo -e "\n${INFO}Exibindo informações do sistema...${NC}"
    neofetch
else
    echo -e "\n${CMD_INFO}(Neofetch não instalado. Para exibir infos, instale-o com 'sudo apt install neofetch')${NC}"
fi

echo ""
