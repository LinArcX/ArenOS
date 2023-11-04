#!/bin/bash

# Requirements:
#   bash
#   curl
#   gnupg2

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
  echo -e "${GREEN}>>> Creating src/ and output/ directories.${NC}\n"
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
  echo -e "${GREEN}>>> Extracting linux-$KERNEL_VERSION.tar.xz into src/ ...${NC}\n"
  tar -xvf src/linux-$KERNEL_VERSION.tar -C ./src

  echo -e "${GREEN}>>> Building linux-$KERNEL_VERSION ...${NC}\n"
  cd linux-$KERNEL_VERSION 
    make defconfig
    make -j12 && echo "${GREEN}>>> linux-${KERNEL_VERSION} successfully built.${NC}\n" || echo "${RED}!!! linux-${KERNEL_VERSION} make failed!${NC}\n" && exit
  cd ..
}

verify_linux_signature() {
  echo -e "${GREEN}>>> Import keys belonging to Linus Torvalds and Greg Kroah-Hartman.(Linux developers)${NC}\n"
  gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org

  echo -e "${GREEN}>>> Trust keys belonging Greg Kroah-Hartman.(Linux developer)${NC}\n"
  gpg2 --tofu-policy good 38DBBDC86092693E

  echo -e "${GREEN}>>> Verifing signature ...${NC}\n"
  $DOWNLOADER -O linux-$KERNEL_VERSION.tar.sign $KERNEL_SIG_URL
  unxz linux-$KERNEL_VERSION.tar.xz
  gpg2 --trust-model tofu linux-$KERNEL_VERSION.tar.sign linux-$KERNEL_VERSION.tar

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}>>> linux-$KERNEL_VERSION.tar.sign is valid.${NC}\n"
    return 0
  else
    echo -e "${RED}>>> linux-$KERNEL_VERSION.tar.sign is invalid!${NC}\n"
    return 1
  fi
}

download_extract_build_linux() {
  cd src/

  if [ -f "linux-$KERNEL_VERSION.tar.xz" ]; then
    if verify_linux_signature; then
      extract_build_linux
      return 0
    else
      echo -e "${RED}!!! Signature verification failed: linux-${KERNEL_VERSION}.tar${NC}\n"
      return 1
    fi
  else
    echo -e "${GREEN}>>> Downloading linux-$KERNEL_VERSION.tar.xz ...${NC}\n"
    if check_url $KERNEL_SRC_URL; then
      echo -e "${GREEN}>>> linux-${KERNEL_VERSION}.tar.xz URL is valid.${NC}\n"
      $DOWNLOADER -o src/linux-$KERNEL_VERSION.tar.xz $KERNEL_SRC_URL
      if verify_linux_signature; then
        extract_build_linux
        return 0
      else
        echo -e "${RED}!!! Signature verification failed: linux-${KERNEL_VERSION}.tar${NC}\n"
        return 1
      fi
    else
      echo -e "${RED}!!! linux-${KERNEL_VERSION}.tar.xz URL is not valid.${NC}\n"
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
