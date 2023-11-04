#!/bin/bash

# Depenendencies
#   build.sh:
#     bash
#     curl
#     gnupg2
#   Linux:
#     bc

# Define colors using ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color (to reset the color)

DOWNLOADER=curl

KERNEL_VERSION=6.6
KERNEL_MAJOR_VERSION=$(echo $KERNEL_VERSION | grep -o '^[0-9]*' | cut -d$'\n' -f1)
KERNEL_SRC_URL=https://mirrors.edge.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR_VERSION.x/linux-$KERNEL_VERSION.tar.xz
KERNEL_SIG_URL=https://mirrors.edge.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR_VERSION.x/linux-$KERNEL_VERSION.tar.sign

BUSYBOX_VERSION=1.36.1
BUSYBOX_URL=https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2

build_src_output_dir() {
  echo -e "\n${GREEN}>>> Creating src/ and output/ directories.${NC}"
  mkdir -p src
  mkdir -p output
}

check_url() {
  URL="$1"
  response=$($DOWNLOADER --head --silent --output /dev/null --write-out "%{http_code}" "$URL")
  
  if [ "$response" = "200" ]; then
    return 0
  else
    return 1
  fi
}

extract_build_linux() {
  echo -e "\n${GREEN}>>> Extracting linux-$KERNEL_VERSION.tar.xz into src/ ...${NC}"
  tar -xvf linux-$KERNEL_VERSION.tar -C .

  echo -e "\n${GREEN}>>> Building linux-$KERNEL_VERSION ...${NC}"
  cd linux-$KERNEL_VERSION 
    make defconfig
    make -j12 && echo -e "\n${GREEN}>>> linux-${KERNEL_VERSION} successfully built.${NC}" || echo -e "\n${RED}!!! linux-${KERNEL_VERSION} make failed!${NC}" && exit
  cd ..
}

verify_linux_signature() {
  echo -e "\n${GREEN}>>> Import keys belonging to Linus Torvalds and Greg Kroah-Hartman.(Linux developers)${NC}"
  gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org

  echo -e "\n${GREEN}>>> Trust keys belonging Greg Kroah-Hartman.(Linux developer)${NC}"
  gpg2 --tofu-policy good 38DBBDC86092693E

  echo -e "\n${GREEN}>>> Downloading signature ...${NC}"
  $DOWNLOADER -o linux-$KERNEL_VERSION.tar.sign $KERNEL_SIG_URL

  echo -e "\n${GREEN}>>> Verifing signature ...${NC}"
  if [ -f "linux-$KERNEL_VERSION.tar.xz" ]; then
    unxz linux-$KERNEL_VERSION.tar.xz
  fi
  gpg --trust-model tofu --verify linux-$KERNEL_VERSION.tar.sign linux-$KERNEL_VERSION.tar

  if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}>>> linux-$KERNEL_VERSION.tar.sign is valid.${NC}"
    return 0
  else
    echo -e "\n${RED}>>> linux-$KERNEL_VERSION.tar.sign is invalid!${NC}"
    return 1
  fi
}

download_extract_build_linux() {
  cd src/

  if [ -f "linux-$KERNEL_VERSION.tar" ]; then
    if verify_linux_signature; then
      extract_build_linux
      return 0
    else
      echo -e "\n${RED}!!! Signature verification failed: linux-${KERNEL_VERSION}.tar${NC}"
      return 1
    fi
  else
    if check_url $KERNEL_SRC_URL; then
      echo -e "\n${GREEN}>>> linux-${KERNEL_VERSION}.tar.xz URL is valid.${NC}"

      echo -e "\n${GREEN}>>> Downloading linux-$KERNEL_VERSION.tar.xz ...${NC}"
      $DOWNLOADER -o linux-$KERNEL_VERSION.tar.xz $KERNEL_SRC_URL

      if verify_linux_signature; then
        extract_build_linux
        return 0
      else
        echo -e "\n${RED}!!! Signature verification failed: linux-${KERNEL_VERSION}.tar${NC}"
        return 1
      fi
    else
      echo -e "\n${RED}!!! linux-${KERNEL_VERSION}.tar.xz URL is not valid.${NC}"
      return 2
    fi
  fi

  cd ..
}

download_extract_build_busybox() {
  if check_url $BUSYBOX_URL; then
    echo -e "${GREEN}>>> BuysBox URL is valid.${NC}\n"
    $DOWNLOADER -o src/busybox-$BUSYBOX_VERSION.tar.bz2 $BUSYBOX_URL

    echo -e "${GREEN}>>> Extracting busybox-$BUSYBOX_VERSION.tar.bz2 into src/ ...${NC}\n"
    tar -xjf src/busybox-$BUSYBOX_VERSION.tar.bz2 -C ./src

    echo -e "${GREEN}>>> Building busybox-$BUSYBOX_VERSION ...${NC}\n"
    cd busybox-$BUSYBOX_VERSION

    cd ..
    return 0
  else
    echo -e "${RED}!!! BusyBox URL is not valid.${NC}\n"
    return 1
  fi
}

build_src_output_dir
download_extract_build_linux

#if download_extract_build_kernel; then
#  download_extract_build_busybox
#fi
