#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

# Determinar a arquitetura correta
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      GabrielCriste INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2024, GabrielCriste"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  install_ubuntu=YES
fi

case $install_ubuntu in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"

  # Loop para tentar baixar o proot corretamente
  for i in $(seq 1 $max_retries); do
    wget --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" \
      "https://raw.githubusercontent.com/GabrielCriste/jupyter/main/proot-${ARCH}"

    # Verificar se o arquivo foi baixado com sucesso
    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
      break
    else
      echo "Erro no download, tentando novamente ($i/$max_retries)..."
      rm -f "$ROOTFS_DIR/usr/local/bin/proot"
      sleep 5  # Esperar um pouco antes de tentar novamente
    fi
  done

  chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  rm -rf /tmp/rootfs.tar.gz /tmp/sbin
  touch "$ROOTFS_DIR/.installed"
fi

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
  echo -e ""
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
}

clear
display_gg

"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="$ROOTFS_DIR" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
  
