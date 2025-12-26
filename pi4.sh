#!/bin/bash
# --- 1. Preparação e Repositórios ---
echo "Adicionando repositório oficial do Fastfetch..."
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch

# Aceita automaticamente a licença (EULA) das fontes da Microsoft
echo "Configurando aceitação automática da licença Microsoft..."
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

# Atualiza a lista de pacotes e o sistema
echo "Atualizando listas e aplicando correções do sistema..."
sudo apt update
sudo apt upgrade -y

# Instala o Fastfetch agora que o PPA foi adicionado
echo "Instalando Fastfetch..."
sudo apt install -y fastfetch

# --- 2. Remoção de Softwares Indesejados ---
echo "Removendo pacotes desnecessários..."
sudo apt remove --purge -y thunderbird
sudo apt remove --purge -y gnome-keyring
sudo apt remove --purge -y hypnotix
sudo apt autoremove -y

# --- 3. Instalação de Ferramentas e Compactadores ---
echo "Instalando ferramentas de sistema e compactadores..."
sudo apt install -y wavemon
sudo apt install -y btop
sudo apt install -y veyon
sudo apt install -y unrar
sudo apt install -y p7zip-full
sudo apt install -y p7zip-rar
sudo apt install -y zip
sudo apt install -y unzip
sudo apt install -y lzip
sudo apt install -y lhasa
sudo apt install -y arj
sudo apt install -y sharutils

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
echo "Instalando LocalSend via Flatpak..."
# (Verifica rapidamente se flatpak está instalado; se não, instala)
if ! command -v flatpak &> /dev/null; then
    sudo apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
flatpak install -y flathub org.localsend.localsend_app

# --- 6. Limpeza e Finalização ---
echo "Limpando arquivos residuais..."
sudo apt autoremove -y
sudo apt clean

echo "Configuração concluída!"
echo "--------------------------------------"

# --- 7. Execução do Fastfetch ---
fastfetch
