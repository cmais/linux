#!/bin/bash
# --- 1. Preparação e Repositórios ---
 sudo apt update && sudo apt upgrade -y


# Aceita automaticamente a licença (EULA) das fontes da Microsoft
echo "Configurando aceitação automática da licença Microsoft..."
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
 

# --- 2. Remoção de Softwares Indesejados ---
echo "Removendo pacotes desnecessários..."
sudo apt remove --purge -y thunderbird
sudo apt remove --purge -y hypnotix
sudo apt autoremove -y

# --- 3. Instalação de Ferramentas e Compactadores ---
echo "Instalando ferramentas de sistema e compactadores..."
sudo apt install -y wavemon
sudo apt install -y btop
sudo apt install -y veyon
sudo apt install -y unrar
sudo apt install -y p7zip-full
sudo apt install -y zip
sudo apt install -y unzip

# --- 4. Fontes e Multimídia ---
echo "Instalando fontes e codecs..."
sudo apt install -y ttf-mscorefonts-installer    # Fontes Microsoft (Arial, Times, etc.)
sudo apt install -y mint-meta-codecs             # Codecs multimídia completos
sudo apt install -y fonts-roboto                 # Roboto (moderna, do Google)
sudo apt install -y fonts-ubuntu                 # Fontes Ubuntu (clássicas e limpas)
sudo apt install -y fonts-crosextra-carlito      # Substituta para Calibri
sudo apt install -y fonts-crosextra-caladea      # Substituta para Cambria
sudo apt install -y fonts-noto-color-emoji       # Emojis coloridos
sudo apt install -y fonts-hack                   # Hack (ótima para terminal/código)
sudo apt install -y fonts-opensymbol             # Símbolos extras
sudo apt install -y vlc                          # Player VLC

# Atualiza o cache de fontes
echo "Atualizando cache de fontes..."
sudo fc-cache -f -v

# --- 5. Flatpaks ---
flatpak install -y flathub org.localsend.localsend_app

# --- 6. Limpeza e Finalização ---
echo "Limpando arquivos residuais..."
sudo apt autoremove -y
sudo apt clean

echo "Configuração concluída!"
echo "--------------------------------------"

# --- 7. Execução do Fastfetch ---
neofetch
