#!/bin/bash

# Requirements:
# - bash
# - wget

# Define colors using ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color (to reset the color)

FILE_DOWNLOADER=curl

KERNEL_VERSION=6.6
KERNEL_MAJOR_VERSION=$(echo $KERNEL_VERSION | grep -o '^[0-9]*' | cut -d$'\n' -f1)
KERNEL_URL=https://mirrors.edge.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR_VERSION.x/linux-$KERNEL_VERSION.tar.xz

BUSYBOX_VERSION=1.36.1
BUSYBOX_URL=https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2

check_url() {
  URL="$1"
  response=$(curl --head --silent --output /dev/null --write-out "%{http_code}" "$URL")
  
  if [ "$response" = "200" ]; then
    return 0
  else
    return 1
  fi
}

build_src_output_dir() {
  echo -e "${GREEN}>>> Creating src/ and output/ directories.${NC}\n"
  mkdir -p src
  mkdir -p output
}

download_build_kernel() {
  if check_url $KERNEL_URL; then
    echo -e "${GREEN}>>> Kernel URL is valid.${NC}\n"
    curl -o src/linux-$KERNEL_VERSION.tar.xz $KERNEL_URL
    return 0
  else
    echo -e "${RED}!!! Kernel URL is not valid.${NC}\n"
    return 1
  fi
}

download_build_busybox() {
  if check_url $BUSYBOX_URL; then
    echo -e "${GREEN}>>> BuysBox URL is valid.${NC}\n"
    curl -o src/busybox-$BUSYBOX_VERSION.tar.bz2 $BUSYBOX_URL
    return 0
  else
    echo -e "${RED}!!! BusyBox URL is not valid.${NC}\n"
    return 1
  fi
}

build_src_output_dir
if download_build_kernel; then
  download_build_busybox
fi
