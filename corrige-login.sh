#!/bin/bash
# =============================================================================
# corrige-login-amdgpu.sh  (v1.0)
#
# Problema tratado: o Xorg sobe sobre o vídeo básico (simpledrm), o driver
# amdgpu só chega 60-100 s depois, o Xorg aborta ao receber a GPU e a sessão
# de login automático cai para a tela de login.
#
# O que este script faz (duas camadas, ambas reversíveis):
#   A) Coloca o amdgpu (e o firmware da GPU) no initramfs, para o driver
#      carregar logo no início do boot, antes do LightDM e do Xorg existirem.
#   B) Instala uma espera limitada (máx. 150 s) antes do LightDM iniciar: ele
#      só sobe depois que o amdgpu assumir a GPU. É a rede de segurança caso o
#      driver ainda chegue tarde. Não faz nada se o amdgpu já estiver pronto.
#
# Uso:
#   sudo bash corrige-login-amdgpu.sh               aplica A + B
#   sudo bash corrige-login-amdgpu.sh --so-espera   aplica só B (sem mexer no initramfs)
#   sudo bash corrige-login-amdgpu.sh --verificar   depois de reiniciar: confere o resultado
#   sudo bash corrige-login-amdgpu.sh --desfazer    remove A e B
# =============================================================================

MODO="${1:-aplicar}"
BKP="/root/fix-amdgpu-backup"
ESTADO="$BKP/estado.txt"
ESPERA_BIN="/usr/local/sbin/lightdm-espera-gpu"
DROPIN_DIR="/etc/systemd/system/lightdm.service.d"
DROPIN="$DROPIN_DIR/espera-gpu.conf"
MODS="/etc/initramfs-tools/modules"
KVER="$(uname -r)"
IMG="/boot/initrd.img-$KVER"
DATA="$(date +%Y%m%d-%H%M%S)"

if [ "$(id -u)" -ne 0 ]; then echo "Rode com sudo:  sudo bash $0 $*"; exit 1; fi

USER_ALVO="${SUDO_USER:-root}"
USER_HOME="$(getent passwd "$USER_ALVO" | cut -d: -f6)"
LOG="${USER_HOME:-/root}/corrige-login-amdgpu-$DATA.log"
exec > >(tee -a "$LOG") 2>&1
echo "corrige-login-amdgpu v1.0 | modo: $MODO | kernel: $KVER | $(date '+%F %T')"
echo "Log: $LOG"

passo()  { echo; echo ">>> $*"; }
ok()     { echo "    [OK] $*"; }
aviso()  { echo "    [ATENÇÃO] $*"; }
erro()   { echo "    [ERRO] $*"; }
estado_get() { grep -E "^$1=" "$ESTADO" 2>/dev/null | tail -n1 | cut -d= -f2; }
estado_set() { mkdir -p "$BKP"; sed -i "/^$1=/d" "$ESTADO" 2>/dev/null; echo "$1=$2" >> "$ESTADO"; }

# ----------------------------------------------------------------------------
# utilidades de hardware
# ----------------------------------------------------------------------------
achar_gpu_amd() {
  GPU_AMD=""; GPU_ID=""
  for d in /sys/bus/pci/devices/*; do
    [ "$(cat "$d/vendor" 2>/dev/null)" = "0x1002" ] || continue
    case "$(cat "$d/class" 2>/dev/null)" in
      0x03*) GPU_AMD="$(basename "$d")"; GPU_ID="$(cat "$d/device" 2>/dev/null)"; return 0 ;;
    esac
  done
  return 1
}

# ----------------------------------------------------------------------------
# camada B: espera limitada antes do LightDM
# ----------------------------------------------------------------------------
instala_espera() {
  passo "Camada B: LightDM espera a GPU (máx. 150 s)"
  cat > "$ESPERA_BIN" <<'EOF'
#!/bin/sh
# Espera o driver amdgpu assumir a GPU AMD antes de o LightDM/Xorg iniciarem.
# Nunca bloqueia o boot por mais de 150 s e sempre termina com sucesso.
MAX=150
# Em modo de compatibilidade (nomodeset) o amdgpu não carrega: não espera.
grep -qw nomodeset /proc/cmdline && exit 0
amd=""
for d in /sys/bus/pci/devices/*; do
  [ "$(cat "$d/vendor" 2>/dev/null)" = "0x1002" ] || continue
  case "$(cat "$d/class" 2>/dev/null)" in 0x03*) amd="$amd $(basename "$d")" ;; esac
done
[ -z "$amd" ] && exit 0
ok=0; i=0
while [ "$i" -lt "$MAX" ]; do
  ok=1
  for a in $amd; do [ -e "/sys/bus/pci/drivers/amdgpu/$a" ] || ok=0; done
  [ "$ok" -eq 1 ] && break
  sleep 1; i=$((i+1))
done
if [ "$ok" -eq 1 ]; then
  udevadm settle --timeout=5 >/dev/null 2>&1
  logger -t lightdm-espera-gpu "amdgpu pronto apos ${i}s; liberando o LightDM"
else
  logger -t lightdm-espera-gpu "tempo esgotado (${MAX}s) sem o amdgpu assumir a GPU; liberando o LightDM mesmo assim"
fi
exit 0
EOF
  chmod 755 "$ESPERA_BIN"
  mkdir -p "$DROPIN_DIR"
  cat > "$DROPIN" <<EOF
[Service]
# A espera conta no tempo de partida do serviço, por isso o limite é ampliado.
TimeoutStartSec=300
ExecStartPre=$ESPERA_BIN
EOF
  systemctl daemon-reload
  if systemctl cat lightdm 2>/dev/null | grep -q "lightdm-espera-gpu"; then
    ok "espera instalada ($ESPERA_BIN + $DROPIN)"
    estado_set ESPERA_CRIADA 1
  else
    erro "o systemd não enxergou o drop-in do LightDM."
    return 1
  fi
}

remove_espera() {
  rm -f "$DROPIN" "$ESPERA_BIN"
  rmdir "$DROPIN_DIR" 2>/dev/null
  systemctl daemon-reload 2>/dev/null
  ok "espera do LightDM removida"
  estado_set ESPERA_CRIADA 0
}

# ----------------------------------------------------------------------------
# camada A: amdgpu no initramfs
# ----------------------------------------------------------------------------
restaura_initrd() {
  if [ -f "$BKP/initrd.img-$KVER.orig" ]; then
    cp -a "$BKP/initrd.img-$KVER.orig" "$IMG" && ok "initramfs original restaurado do backup"
  fi
}

aplica_initramfs() {
  passo "Camada A: amdgpu no initramfs"
  command -v update-initramfs >/dev/null && command -v lsinitramfs >/dev/null || { erro "update-initramfs/lsinitramfs ausentes."; return 1; }
  [ -f "$IMG" ] || { erro "initramfs do kernel em uso não encontrado: $IMG"; return 1; }
  achar_gpu_amd || { erro "nenhuma GPU AMD encontrada; este script é para o seu HP com Radeon."; return 1; }
  ok "GPU AMD: $GPU_AMD (id $GPU_ID)"
  modinfo amdgpu >/dev/null 2>&1 || { erro "módulo amdgpu não encontrado para este kernel."; return 1; }

  FWPAT=""; [ "$GPU_ID" = "0x98e4" ] && FWPAT="stoney"
  if ! ls /lib/firmware/amdgpu/${FWPAT}* >/dev/null 2>&1; then
    erro "firmware da GPU ausente em /lib/firmware/amdgpu (${FWPAT:-qualquer}). Instale o pacote linux-firmware antes."
    return 1
  fi
  ok "firmware da GPU presente no disco"

  LIVRE_BOOT_MB=$(df -Pm /boot | awk 'NR==2{print $4}')
  LIVRE_ROOT_MB=$(df -Pm /root | awk 'NR==2{print $4}')
  if [ "${LIVRE_BOOT_MB:-0}" -lt 400 ] || [ "${LIVRE_ROOT_MB:-0}" -lt 400 ]; then
    erro "pouco espaço livre (/boot: ${LIVRE_BOOT_MB} MB, /root: ${LIVRE_ROOT_MB} MB). Preciso de pelo menos 400 MB."
    return 1
  fi
  ok "espaço livre suficiente (${LIVRE_BOOT_MB} MB)"

  mkdir -p "$BKP"
  [ -f "$BKP/initrd.img-$KVER.orig" ] || cp -a "$IMG" "$BKP/initrd.img-$KVER.orig"
  [ -f "$BKP/modules.orig" ] || cp -a "$MODS" "$BKP/modules.orig" 2>/dev/null
  ok "backup do initramfs original em $BKP"
  echo "    initramfs antes: $(ls -lh "$IMG" | awk '{print $5}')"

  if grep -qx "amdgpu" "$MODS" 2>/dev/null; then
    ok "'amdgpu' já estava em $MODS"
    [ -n "$(estado_get MODULO_ADICIONADO)" ] || estado_set MODULO_ADICIONADO 0
  else
    echo "amdgpu" >> "$MODS"
    estado_set MODULO_ADICIONADO 1
    ok "'amdgpu' adicionado a $MODS"
  fi

  echo "    Reconstruindo o initramfs (pode levar alguns minutos neste processador; não interrompa)..."
  if ! update-initramfs -u -k "$KVER"; then
    erro "update-initramfs falhou. Revertendo."
    [ "$(estado_get MODULO_ADICIONADO)" = "1" ] && sed -i '/^amdgpu$/d' "$MODS"
    restaura_initrd
    return 1
  fi

  # verificação do conteúdo
  LISTA="$(lsinitramfs "$IMG" 2>/dev/null)"
  if ! echo "$LISTA" | grep -qE '/amdgpu\.ko'; then
    erro "o módulo amdgpu NÃO entrou no initramfs. Revertendo."
    [ "$(estado_get MODULO_ADICIONADO)" = "1" ] && sed -i '/^amdgpu$/d' "$MODS"
    restaura_initrd
    return 1
  fi
  ok "módulo amdgpu presente no initramfs"
  NFW="$(echo "$LISTA" | grep -cE "amdgpu/${FWPAT}")"
  if [ "$NFW" -lt 5 ]; then
    erro "firmware da GPU quase ausente do initramfs ($NFW arquivos): o driver carregaria sem firmware e a tela ficaria preta. Revertendo."
    [ "$(estado_get MODULO_ADICIONADO)" = "1" ] && sed -i '/^amdgpu$/d' "$MODS"
    restaura_initrd
    return 1
  fi
  ok "firmware da GPU no initramfs ($NFW arquivos)"
  echo "    initramfs depois: $(ls -lh "$IMG" | awk '{print $5}')"
  estado_set INITRAMFS_ALTERADO 1
}

desfaz_initramfs() {
  passo "Desfazendo a camada A (initramfs)"
  if [ "$(estado_get MODULO_ADICIONADO)" = "1" ]; then
    sed -i '/^amdgpu$/d' "$MODS" && ok "'amdgpu' removido de $MODS"
  else
    aviso "o script não adicionou 'amdgpu' ao $MODS; mantendo como estava"
  fi
  echo "    Reconstruindo o initramfs..."
  update-initramfs -u -k "$KVER" && ok "initramfs reconstruído sem a alteração" || { aviso "falhou; tentando restaurar a cópia de segurança"; restaura_initrd; }
  estado_set INITRAMFS_ALTERADO 0
}

# ----------------------------------------------------------------------------
# verificação depois do reinício
# ----------------------------------------------------------------------------
verifica() {
  passo "Verificação do boot atual (uptime: $(cut -d' ' -f1 /proc/uptime) s)"
  JF="$(mktemp)"; journalctl -b -o short-monotonic --no-pager > "$JF" 2>/dev/null
  mono() { sed -E 's/^\[ *([0-9]+\.[0-9]+)\].*/\1/'; }
  AM="$(grep -m1 'initializing kernel modesetting' "$JF" | mono)"
  LD="$(grep -m1 'Started lightdm.service' "$JF" | mono)"
  AO="$(grep -m1 'lightdm-autologin:session): session opened' "$JF" | mono)"
  AC="$(grep -m1 'lightdm-autologin:session): session closed' "$JF" | mono)"
  XC="$(grep -ciE 'Process [0-9]+ \(Xorg\) of user [0-9]+ dumped core' "$JF")"
  echo "    amdgpu iniciou aos:          ${AM:-n/d} s"
  echo "    LightDM iniciou aos:         ${LD:-n/d} s"
  echo "    sessão de autologin abriu:   ${AO:-n/d} s | encerrou: ${AC:-não encerrou}"
  echo "    crashes do Xorg neste boot:  $XC"
  echo "    mensagens da espera do LightDM:"
  journalctl -b -t lightdm-espera-gpu --no-pager 2>/dev/null | tail -n 3 | sed 's/^/       /'
  echo "    initramfs contém amdgpu: $(lsinitramfs "$IMG" 2>/dev/null | grep -qE '/amdgpu\.ko' && echo sim || echo NÃO)"
  echo
  RES=0
  [ "$XC" = "0" ] && ok "nenhum crash do Xorg neste boot" || { erro "o Xorg travou $XC vez(es)"; RES=1; }
  if [ -n "$AC" ]; then erro "a sessão de autologin foi encerrada (aos ${AC}s)"; RES=1
  elif [ -n "$AO" ]; then ok "a sessão de autologin abriu e continua ativa"
  else aviso "não há sessão de autologin registrada neste boot"; fi
  if [ -n "$AM" ] && [ -n "$LD" ]; then
    awk -v a="$AM" -v l="$LD" 'BEGIN{exit !(a<=l)}' && ok "o amdgpu chegou antes do LightDM (${AM}s < ${LD}s)" || aviso "o amdgpu ainda chegou depois do LightDM"
  fi
  rm -f "$JF"
  echo
  if [ "$RES" -eq 0 ]; then echo "RESULTADO: aparentemente corrigido neste boot. Reinicie mais 2 ou 3 vezes para confirmar."
  else echo "RESULTADO: o problema ainda ocorreu. Guarde este log e me envie: precisaremos investigar o atraso (diagnostico-gpu-preso.sh)."; fi
}

# ----------------------------------------------------------------------------
# fluxo principal
# ----------------------------------------------------------------------------
case "$MODO" in
  aplicar|--aplicar)
    passo "Verificações iniciais"
    [ -x /usr/sbin/lightdm ] || { erro "LightDM não está instalado."; exit 1; }
    grep -q lightdm /etc/X11/default-display-manager 2>/dev/null || { erro "o gerenciador de login padrão não é o LightDM."; exit 1; }
    ok "LightDM é o gerenciador de login"
    achar_gpu_amd || { erro "nenhuma GPU AMD encontrada."; exit 1; }
    ok "GPU AMD detectada ($GPU_AMD)"
    if ! aplica_initramfs; then
      aviso "A camada A falhou ou foi revertida. Aplicando só a camada B (espera do LightDM), que já impede o crash."
    fi
    instala_espera || { erro "falha na camada B."; exit 1; }
    echo
    echo "============================================================"
    echo " Pronto. Reinicie:   sudo reboot"
    echo " Depois de 2 minutos na área de trabalho, rode:"
    echo "   sudo bash $0 --verificar"
    echo " Para desfazer tudo:  sudo bash $0 --desfazer"
    echo " (Se a tela ficar preta: GRUB com Shift/Esc > Opções avançadas >"
    echo "  recovery mode > root, e rode:  bash $0 --desfazer)"
    echo "============================================================"
    ;;
  --so-espera)
    instala_espera || exit 1
    echo; echo "Pronto. Reinicie com: sudo reboot   (depois: sudo bash $0 --verificar)"
    ;;
  --verificar)
    verifica
    ;;
  --desfazer)
    desfaz_initramfs
    passo "Desfazendo a camada B (espera do LightDM)"
    remove_espera
    echo; echo "Tudo desfeito. Reinicie com: reboot"
    ;;
  *)
    echo "Modo desconhecido: $MODO"
    echo "Use: (sem argumento) | --so-espera | --verificar | --desfazer"
    exit 1
    ;;
esac
