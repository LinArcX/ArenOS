#!/bin/bash

# Depenendencies
#   build.sh:
#     bash
#     curl
#     gnupg2
#   Linux:
#     bc
#     openssl-devel

# Define colors using ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color (to reset the color)

DOWNLOADER=curl

LINUX_VERSION=6.6
LINUX_MAJOR_VERSION=$(echo $LINUX_VERSION | grep -o '^[0-9]*' | cut -d$'\n' -f1)
LINUX_SRC_URL=https://mirrors.edge.kernel.org/pub/linux/kernel/v$LINUX_MAJOR_VERSION.x/linux-$LINUX_VERSION.tar.xz
LINUX_SIG_URL=https://mirrors.edge.kernel.org/pub/linux/kernel/v$LINUX_MAJOR_VERSION.x/linux-$LINUX_VERSION.tar.sign

BUSYBOX_VERSION=1.36.1
BUSYBOX_SRC_URL=https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
BUSYBOX_SIG_URL=https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2.sig
BUSYBOX_SHA256_URL=https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2.sha256

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
  # To reduce compile time during linux compilation:
  # - only use features/modules that your system really need. disable all other modules/features.
  #
  # To reduce cpu usage during linux compilation:
  # - Use Fewer Cores by specifying less cores(-j). maybe half of your cores are enough.
  # - Use ccache: This way, repeated compilations only need to compile changed portions, reducing overall CPU usage
  # - Nice and Ionice: Prioritize the process using nice and ionice commands. nice adjusts the process priority, and ionice assigns I/O priority. For example, you could use nice -n 19 make -j4 to lower the priority of the compilation.
  echo -e "\n${GREEN}>>> Extracting linux-$LINUX_VERSION.tar.xz into src/ ...${NC}"
  tar -xvf linux-$LINUX_VERSION.tar -C .

  echo -e "\n${GREEN}>>> Building linux-$LINUX_VERSION ...${NC}"
  cd linux-$LINUX_VERSION 
    make defconfig
    time make -j"$(($(nproc) / 2))" && echo -e "\n${GREEN}>>> linux-${LINUX_VERSION} successfully built.${NC}" || echo -e "\n${RED}!!! linux-${LINUX_VERSION} build failed!${NC}" && exit
  cd ..
}

verify_linux_signature() {
  echo -e "\n${GREEN}>>> Import keys belonging to Linus Torvalds and Greg Kroah-Hartman.(Linux developers)${NC}"
  gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org

  echo -e "\n${GREEN}>>> Trust keys belonging Greg Kroah-Hartman.(Linux developer)${NC}"
  gpg2 --tofu-policy good 38DBBDC86092693E

  echo -e "\n${GREEN}>>> Downloading signature ...${NC}"
  $DOWNLOADER -o linux-$LINUX_VERSION.tar.sign $LINUX_SIG_URL

  echo -e "\n${GREEN}>>> Verifing signature ...${NC}"
  if [ -f "linux-$LINUX_VERSION.tar.xz" ]; then
    unxz linux-$LINUX_VERSION.tar.xz
  fi
  gpg --trust-model tofu --verify linux-$LINUX_VERSION.tar.sign linux-$LINUX_VERSION.tar

  if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}>>> linux-$LINUX_VERSION.tar.sign is valid.${NC}"
    return 0
  else
    echo -e "\n${RED}!!! linux-$LINUX_VERSION.tar.sign is invalid!${NC}"
    return 1
  fi
}

download_extract_build_linux() {
  cd src/

  if [ -f "linux-$LINUX_VERSION.tar" ]; then
    if verify_linux_signature; then
      extract_build_linux
      return 0
    else
      echo -e "\n${RED}!!! Signature verification failed: linux-${LINUX_VERSION}.tar${NC}"
      return 1
    fi
  else
    if check_url $LINUX_SRC_URL; then
      echo -e "\n${GREEN}>>> linux-${LINUX_VERSION}.tar.xz URL is valid.${NC}"

      echo -e "\n${GREEN}>>> Downloading linux-$LINUX_VERSION.tar.xz ...${NC}"
      $DOWNLOADER -o linux-$LINUX_VERSION.tar.xz $LINUX_SRC_URL

      if verify_linux_signature; then
        extract_build_linux
        return 0
      else
        echo -e "\n${RED}!!! Signature verification failed: linux-${LINUX_VERSION}.tar${NC}"
        return 1
      fi
    else
      echo -e "\n${RED}!!! linux-${LINUX_VERSION}.tar.xz URL is not valid.${NC}"
      return 2
    fi
  fi

  cd ..
}

extract_build_busybox() {
  echo -e "\n${GREEN}>>> Extracting busybox-$BUSYBOX_VERSION.tar.bz2 ...${NC}"
  tar -xjf busybox-$BUSYBOX_VERSION.tar.bz2 -C .

  echo -e "\n${GREEN}>>> Building busybox-$BUSYBOX_VERSION ...${NC}"
  cd busybox-$BUSYBOX_VERSION
    make defconfig
    #time make -j"$(($(nproc) / 2))" && echo -e "\n${GREEN}>>> busybox-$BUSYBOX_VERSION successfully built.${NC}" || echo -e "\n${RED}!!! busybox-$BUSYBOX_VERSION build failed!${NC}" && exit
  cd ..
  return 0
}


verify_busybox_signature() {
  echo -e "\n${GREEN}>>> Downloading busybox-$BUSYBOX_VERSION.tar.bz2.sig ...${NC}"
  $DOWNLOADER -o busybox-$BUSYBOX_VERSION.tar.bz2.sha256 $BUSYBOX_SHA256_URL

  echo -e "\n${GREEN}>>> Verifing busybox-$BUSYBOX_VERSION.tar.bz2.sha256 ...${NC}"
  sha256sum -c busybox-$BUSYBOX_VERSION.tar.bz2.sha256

  if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}>>> busybox-$BUSYBOX_VERSION.tar.bz2.sig is valid.${NC}"
    return 0
  else
    echo -e "\n${RED}!!! busybox-$BUSYBOX_VERSION.tar.bz2.sig is invalid!${NC}"
    return 1
  fi
}

download_extract_build_busybox() {
  cd src/

  if [ -f "busybox-$BUSYBOX_VERSION.tar.bz2" ]; then
    if verify_busybox_signature; then
      extract_build_busybox
      return 0
    else
      echo -e "\n${RED}!!! Signature verification failed: busybox-$BUSYBOX_VERSION.tar.bz2${NC}"
      return 1
    fi
  else
    if check_url $BUSYBOX_SRC_URL; then
      echo -e "\n${GREEN}>>> busybox-$BUSYBOX_VERSION.tar.bz2 URL is valid.${NC}"

      echo -e "\n${GREEN}>>> Downloading busybox-$BUSYBOX_VERSION.tar.bz2 ...${NC}"
      $DOWNLOADER -o busybox-$BUSYBOX_VERSION.tar.bz2 $BUSYBOX_SRC_URL

      if verify_busybox_signature; then
        extract_build_busybox
        return 0
      else
        echo -e "\n${RED}!!! Signature verification failed: busybox-$BUSYBOX_VERSION.tar.bz2${NC}"
        return 1
      fi
    else
      echo -e "\n${RED}!!! BusyBox URL is not valid.${NC}"
      return 2
    fi
  fi

  cd ..
}

build_src_output_dir
#download_extract_build_linux
download_extract_build_busybox

#if download_extract_build_kernel; then
#  download_extract_build_busybox
#fi

#arch/x86/boot/bzImage
