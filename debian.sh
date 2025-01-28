#!/usr/bin/env bash
#
##DO NOT RUN DIRECTLY
##Self: bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge-dev/runimage-base/refs/heads/main/debian.sh")
# HOST: x86_64-Linux
#-------------------------------------------------------#

#-------------------------------------------------------#
##Debug
 set -x
 pushd "$(mktemp -d)" >/dev/null 2>&1
##RunImage
 curl -qfsSL "https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$(uname -m)" -o "./runimage"
 chmod -v 'a+x' "./runimage"
 [[ -s "./runimage" ]] || exit 1
##Get Rootfs
 "./runimage" getdimg --extract rootfs "pkgforge/debian-base:$(uname -m)"
 RIM_NO_NET="0"
 RIM_NO_NVIDIA_CHECK="1"
 RIM_ROOT="1"
 RIM_ROOTFS="$(find '.' -maxdepth 1 -type d -iname "*root*" -exec sh -c '[ -d "{}" ] && realpath "{}"' \; | head -n 1 | tr -d '[:space:]')"
 export RIM_NO_NET RIM_NO_NVIDIA_CHECK RIM_OVERFS_MODE RIM_ROOTFS RIM_ROOT
 if [ ! -d "${RIM_ROOTFS}" ] || [ ! "$(find "${RIM_ROOTFS}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
   echo -e "\n[-] FATAL: Failed to Fetch RootFS"
  exit 1 
 fi
##Fake Nvidia Driver
 if [[ "$(uname -m | tr -d '[:space:]')" == "x86_64" ]]; then
   curl -qfsSL "https://github.com/VHSgunzo/runimage-fake-nvidia-driver/raw/refs/heads/main/fake-nvidia-driver.tar" | tar -xvf- -C "${RIM_ROOTFS}"
 fi
##Base Deps
 build_image()
  {
   #Fix & Patches
    echo -e "nameserver 8.8.8.8\nnameserver 2620:0:ccc::2" | tee "/etc/resolv.conf"
    echo -e "nameserver 1.1.1.1\nnameserver 2606:4700:4700::1111" | tee -a "/etc/resolv.conf"
   #Requirements
    DEBIAN_FRONTEND="noninteractive"
    BASE_PKGS=(bash binutils coreutils curl file findutils gawk gocryptfs grep gzip iproute2 iptables iputils-ping jq kmod libnotify-bin lsof liblz4-1 nftables openresolv patchelf procps socat tar util-linux which x11-xserver-utils xz-utils zstd)
    DEBIAN_FRONTEND="noninteractive" apt clean -y
    DEBIAN_FRONTEND="noninteractive" apt update -y
    #DEBIAN_FRONTEND="noninteractive" apt install -f "${BASE_PKGS[@]}" -y --no-install-recommends --ignore-missing
    for pkg in "${BASE_PKGS[@]}"; do DEBIAN_FRONTEND="noninteractive" apt install -f "${pkg}" -y --no-install-recommends --ignore-missing 2>/dev/null; done
   #Cleanup
    curl -kqfsSL "https://raw.githubusercontent.com/VHSgunzo/runimage-fake-sudo-pkexec/refs/heads/main/usr/bin/sudo" -o "./sudo"
    mv -fv "./sudo" "/usr/bin/sudo" && chmod -v "a+x" "/usr/bin/sudo"
    apt purge locales perl -y ; apt autoremove -y ; apt autoclean -y
    apt list --installed
    apt clean -y
    rim-shrink --all --verbose 2>/dev/null
   ##Config
   # echo 'RIM_OVERFS_MODE="1"' > "${RUNDIR}/config/Run.rcfg"
  }
 export -f build_image
##Rebuild
 rm -rvf "/tmp/runimage" 2>/dev/null
 "./runimage" bash -c "build_image"
 #Rebuild [Dwarfs ZSTD 22]
 "./runimage" rim-build --bsize '22' --clvl '22' --dwfs '/tmp/runimage'
 echo "/tmp/runimage" | xargs -I "{}" bash -c 'du -sh "{}" && file "{}" && sha256sum "{}"'
##End
 set +x
 popd >/dev/null 2>&1
#-------------------------------------------------------#
