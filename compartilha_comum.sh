#!/bin/bash

# Nome da pasta a ser compartilhada
PASTA="comum"
CAMINHO="$HOME/$PASTA"

# Atualiza e instala o Samba, se necessário
echo "Instalando ou atualizando o Samba..."
sudo apt update && sudo apt install -y samba

# Cria a pasta se ela não existir
if [ ! -d "$CAMINHO" ]; then
    echo "Criando a pasta $PASTA..."
    mkdir -p "$CAMINHO"
fi

# Configura permissões para acesso público
echo "Configurando permissões..."
sudo chmod 777 "$CAMINHO"

# Faz backup da configuração original do Samba
SAMBA_CONF="/etc/samba/smb.conf"
BACKUP_CONF="/etc/samba/smb.conf.bak"
if [ ! -f "$BACKUP_CONF" ]; then
    echo "Criando backup do arquivo de configuração do Samba..."
    sudo cp "$SAMBA_CONF" "$BACKUP_CONF"
fi

# Adiciona a configuração para compartilhamento anônimo
echo "Configurando o compartilhamento no Samba..."
sudo bash -c "cat >> $SAMBA_CONF" <<EOL

# Compartilhamento da pasta 'comum'
[comum]
   path = $CAMINHO
   browseable = yes
   read only = no
   guest ok = yes
   force user = $USER
EOL

# Reinicia o serviço Samba
echo "Reiniciando o Samba para aplicar as configurações..."
sudo systemctl restart smbd

# Informa o usuário
echo "Configuração concluída! A pasta '$PASTA' foi criada em '$CAMINHO' e está acessível na rede local."
echo "Certifique-se de que os outros dispositivos estão na mesma rede para acessar a pasta."

