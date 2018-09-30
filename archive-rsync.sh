#!/bin/bash

# From: https://github.com/brianchase/archive-rsync
# See also: https://github.com/brianchase/get-mnt

# Default source directory in $HOME (change as necessary):
DIR="Archive"

ar_error () {
  printf '%s\n' "$@" >&2
  [ "${MntArr2[0]}" ] && mnt_args "${DevArr2[0]}"
  exit 1
}

ar_usage () {
  ar_error "Usage: $(basename "$0"): [-r] [-s PATH] [-d PATH]" \
    "Options:" \
    "  -r Reverse default source and destination" \
    "  -s PATH Set source to PATH" \
    "     Default: $HOME/$DIR" \
    "  -d PATH Set destination to PATH" \
    "     Default: user selected mounted device"
}

while getopts :rs:d: Flag; do
  case $Flag in
    r) Reverse="true" ;;
    s) From="$OPTARG" ;;
    :) ar_error "Invalid flag: -$OPTARG requires an argument!" ;;
    d) To="$OPTARG" ;;
    :) ar_error "Invalid flag: -$OPTARG requires an argument!" ;;
    \?) ar_usage ;;
  esac
done
shift $((OPTIND - 1))

ar_sync () {
  local Free Sync Used
  Free="$(df -h "$ToDir" | awk '!/Filesystem/ {print $4}')"
  Used="$(df -h "$ToDir" | awk '!/Filesystem/ {print $3}')"
  printf '%s\n' "[Free space: $Free] [Used space: $Used]"
  read -r -p "Sync $From to $To? [y/n] " Sync
  [ "$Sync" = y ] && rsync -amu --delete --progress "$From" "$To"
  [ "${MntArr2[0]}" ] && mnt_args "${DevArr2[0]}"
}

chk_space () {
  local DIRTotal FSTotal
  DIRTotal="$(du -ms "$From" | awk '{print $1}')"
  FSTotal="$(df -m "$ToDir" | awk '!/Filesystem/ {print $2}')"
  [ "$FSTotal" -lt "$DIRTotal" ] && ar_error "Not enough space on $To for $From!"
}

chk_from () {
  local MntCD TSlash
  if [ ! -d "$From" ]; then
    [ -x "$(command -v get-mnt.sh)" ] || ar_error "Source '$From' not found!"
    read -r -p "Is '$From' on a connected device? [y/n] " MntCD
    [ "$MntCD" = y ] && source get-mnt.sh
    [ ! -d "$From" ] && ar_error "Source '$From' not found!"
  fi
  case $From in
    */) read -r -p "Drop trailing slash from '$From'? [y/n] " TSlash
        [ "$TSlash" = y ] && From="${From%/}" ;;
  esac
}

chk_to () {

# Since rsync can create the directory at the end of the destination
# path, you need to check more than just whether $To is a directory.

  if [ ! -d "$To" ]; then
    if ToDir="$(dirname "$To" 2>/dev/null)"; then
      if [ -x "$(command -v get-mnt.sh)" ]; then
        local MntCD
        read -r -p "Mount a connected device for '$To'? [y/n] " MntCD
        if [ "$MntCD" = y ]; then
          source get-mnt.sh
          if [ -d "$To" ] && [ ! -w "$To" ]; then
            ar_error "Destination '$To' not writable!"
          elif [ ! -d "$To" ] && [ ! -d "$ToDir" ]; then
            ar_error "Base destination '$ToDir' not found!"
          elif [ ! -d "$To" ] && [ ! -w "$ToDir" ]; then
            ar_error "Base destination '$ToDir' not writable!"
          fi
          return
        elif [ -d "$ToDir" ] && [ -w "$ToDir" ]; then
          return
        fi
      elif [ -d "$ToDir" ] && [ -w "$ToDir" ]; then
        return
      fi
    fi
    ar_error "Destination '$To' not found!"
  elif [ ! -w "$To" ]; then
    ar_error "Destination '$To' not writable!"
  fi
  ToDir="$To"
}

chk_get_mnt () {
  [ -x "$(command -v get-mnt.sh)" ] || ar_error "$1 path requires get-mnt.sh!"
  source get-mnt.sh
}

ar_defaults () {
  [ "$Reverse" ] && chk_get_mnt Source && From="${MntArr2[0]}/$DIR"
  [ "${From=$HOME/$DIR}" ] && chk_from
  [ "$Reverse" ] && To="$HOME"
  [ -z "$To" ] && chk_get_mnt Destination && To="${MntArr2[0]}"
  chk_to
}

ar_opts () {
  if [ "$Reverse" ] && [ "$From" ]; then
    ar_error "Invalid flags: -r and -s conflict!"
  elif [ "$Reverse" ] && [ "$To" ]; then
    ar_error "Invalid flags: -r and -d conflict!"
  elif [ "$From" ] && [ "$From" = "$To" ]; then
    ar_error "Source and destination paths are the same!"
  fi
}

ar_main () {
  ar_opts
  ar_defaults
  chk_space
  ar_sync
}

case $1 in
  ''|-r|-s|-d) ar_main ;;
  *) ar_usage ;;
esac
