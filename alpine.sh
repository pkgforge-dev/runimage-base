#!/usr/bin/env bash
#
##DO NOT RUN DIRECTLY
##Self: bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge-dev/runimage-base/refs/heads/main/alpine.sh")
# HOST: aarch64-Linux, x86_64-Linux
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
 "./runimage" getdimg --extract rootfs "pkgforge/alpine-base:$(uname -m)"
 RIM_NO_NET="0"
 RIM_NO_NVIDIA_CHECK="1"
 RIM_ROOT="1"
 RIM_ROOTFS="$(find '.' -maxdepth 1 -type d -iname "*root*" -exec sh -c '[ -d "{}" ] && realpath "{}"' \; | head -n 1 | tr -d '[:space:]')"
 export RIM_NO_NET RIM_NO_NVIDIA_CHECK RIM_OVERFS_MODE RIM_ROOTFS RIM_ROOT
 if [ ! -d "${RIM_ROOTFS}" ] || [ ! "$(find "${RIM_ROOTFS}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
   echo -e "\n[-] FATAL: Failed to Fetch RootFS"
  exit 1 
 fi
##Base Deps
 build_image()
  {
   #Fix & Patches
    echo -e "nameserver 8.8.8.8\nnameserver 2620:0:ccc::2" | tee "/etc/resolv.conf"
    echo -e "nameserver 1.1.1.1\nnameserver 2606:4700:4700::1111" | tee -a "/etc/resolv.conf"
   #Requirements
    BASE_PKGS=(bash binutils coreutils curl file findutils gawk gocryptfs grep gzip iproute2 iptables iputils jq kmod libnotify lsof lz4 nftables openresolv patchelf procps-ng slirp4netns sed socat tar util-linux which xhost xz zstd)
    apk update --no-interactive
    apk upgrade --no-interactive
    #apk add "${BASE_PKGS[@]}" --no-cache --latest --upgrade --no-interactive
    for pkg in "${BASE_PKGS[@]}"; do apk add "${pkg}" --no-cache --latest --upgrade --no-interactive 2>/dev/null; done
   #Cleanup
    chmod 755 "/bin/bbsuid"
    rm -rfv "/var/cache/apk/"* 2>/dev/null
    rm -rfv "/usr/share/fonts/"* 2>/dev/null
    rm -rfv "/usr/share/licenses/"* 2>/dev/null
    rm -rfv "/usr/share/locale/"* 2>/dev/null
    rm -rfv "/usr/share/man/"* 2>/dev/null
    apk cache clean
    ln -s "/dev/null" "/etc/apk/cache"
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