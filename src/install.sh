#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: "${SN:=""}"                # Device serial
: "${MLB:=""}"               # Board serial
: "${MAC:=""}"               # MAC address
: "${UUID:=""}"              # Unique ID
: "${WIDTH:="1920"}"         # Horizontal
: "${HEIGHT:="1080"}"        # Vertical
: "${VERSION:="13"}"         # OSX Version
: "${MODEL:="iMacPro1,1"}"   # Device model

TMP="$STORAGE/tmp"
BASE_IMG_ID="InstallMedia"
BASE_IMG="$STORAGE/base.dmg"
BASE_VERSION="$STORAGE/$PROCESS.version"

detectType() {

  local dir=""
  local file="$1"

  [ ! -f "$file" ] && return 1
  [ ! -s "$file" ] && return 1

  case "${file,,}" in
    *".iso" | *".img" | *".raw" | *".qcow2" )
      return 0 ;;
    * ) return 1 ;;
  esac

  return 0
}

findBackingFile() {

  local ext="$1"
  local file

  file=$(find "$STORAGE" -maxdepth 1 -type f -iname "macOS.$ext" | head -n 1)
  detectType "$file" && return 0

  return 1
}

generateID() {

  local file="$STORAGE/$PROCESS.id"

  [ -n "$UUID" ] && return 0
  [ -s "$file" ] && UUID=$(<"$file")
  [ -n "$UUID" ] && return 0

  UUID=$(cat /proc/sys/kernel/random/uuid 2> /dev/null || uuidgen --random)
  UUID="${UUID^^}"
  echo "$UUID" > "$file"

  return 0
}

generateAddress() {

  local file="$STORAGE/$PROCESS.mac"

  [ -n "$MAC" ] && return 0
  [ -s "$file" ] && MAC=$(<"$file")
  [ -n "$MAC" ] && return 0

  # Generate Apple MAC address based on Docker container ID in hostname
  MAC=$(echo "$HOST" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/00:16:cb:\3:\4:\5/')
  MAC="${MAC^^}" 
  echo "$MAC" > "$file"

  return 0
}

generateSerial() {

  local file="$STORAGE/$PROCESS.sn"
  local file2="$STORAGE/$PROCESS.mlb"

  [ -n "$SN" ] && [ -n "$MLB" ] && return 0
  [ -s "$file" ] && SN=$(<"$file")
  [ -s "$file2" ] && MLB=$(<"$file2")
  [ -n "$SN" ] && [ -n "$MLB" ] && return 0

  # Generate unique serial numbers for machine
  SN=$(/usr/local/bin/macserial --num 1 --model "${MODEL}" 2>/dev/null)

  SN="${SN##*$'\n'}"
  [[ "$SN" != *" | "* ]] && error "$SN" && return 1

  MLB=${SN#*|}
  MLB="${MLB#"${MLB%%[![:space:]]*}"}"
  SN="${SN%%|*}"
  SN="${SN%"${SN##*[![:space:]]}"}"

  echo "$SN" > "$file"
  echo "$MLB" > "$file2"

  return 0
}

findBackingFile "img" && qemu-img create -f qcow2 -b /storage/macOS.img -F qcow2 /storage/data.qcow2
findBackingFile "qcow2" && qemu-img create -f qcow2 -b /storage/macOS.qcow2 -F qcow2 /storage/data.qcow2

if ! generateID; then
  error "Failed to generate UUID!" && exit 35
fi

if ! generateSerial; then
  error "Failed to generate serialnumber!" && exit 36
fi

if ! generateAddress; then
  error "Failed to generate MAC address!" && exit 37
fi

return 0
