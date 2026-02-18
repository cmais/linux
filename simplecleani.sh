#!/bin/bash

# Se algum comando falhar, o script para (segurança)
set -e

echo "--- 1. Atualizando Repositórios e Pacotes (.deb) ---"
sudo apt update
# O upgrade comum é mais seguro que o dist-upgrade para o dia a dia
sudo apt upgrade -y

echo "--- 2. Atualizando Flatpaks e Snaps ---"
# Atualiza flatpaks e remove bibliotecas que não são mais usadas
if command -v flatpak &> /dev/null; then
    flatpak update -y
    flatpak uninstall --unused -y
fi

# Atualiza snaps (silencioso se não houver o comando)
command -v snap &> /dev/null && sudo snap refresh

echo "--- 3. Limpeza Segura ---"
# Remove apenas pacotes que eram dependências de algo que você já deletou
sudo apt autoremove -y
# Limpa apenas arquivos de pacotes que não podem mais ser baixados (obsoletos)
sudo apt autoclean

echo "--- Sistema pronto! ---"
