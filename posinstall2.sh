#!/bin/bash

# --- 1. Preparação e Repositórios ---
# Adiciona o PPA do Fastfetch
echo "Adicionando repositório do Fastfetch..."
sudo add-apt-repository -y ppa:zhanghua/fastfetch

# Aceita automaticamente a licença (EULA) das fontes da Microsoft
echo "Configurando aceitação automática da licença Microsoft..."
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

# Atualiza a lista de pacotes
sudo apt update

# --- 2. Remoção de Softwares Indesejados ---
echo "Removendo pacotes desnecessários..."
sudo apt remove --purge -y \
  thunderbird \
  gnome-keyring \
  hypnotix

sudo apt autoremove -y

# --- 3. Instalação de Ferramentas e Compactadores ---
echo "Instalando ferramentas de sistema e compactadores..."
sudo apt install -y \
  wavemon \
  btop \
  fastfetch \
  unrar \
  p7zip-full \
  p7zip-rar \
  zip \
  unzip \
  lzip \
  lhasa \
  arj \
  sharutils

# --- 4. Fontes e Multimídia ---
echo "Instalando fontes e codecs..."
sudo apt install -y \
  ttf-mscorefonts-installer \
  mint-meta-codecs \
  fonts-roboto \
  fonts-ubuntu \
  vlc

# Atualiza o cache de fontes
sudo fc-cache -f -v

# --- 5. Flatpaks ---
echo "Instalando LocalSend via Flatpak..."
flatpak install -y flathub org.localsend.localsend_app

# --- 6. Limpeza e Finalização ---
echo "Limpando arquivos residuais..."
sudo apt autoremove -y
sudo apt clean

echo "Configuração concluída!"
echo "--------------------------------------"

# --- 7. Execução do Fastfetch ---
fastfetch
