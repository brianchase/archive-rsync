#!/bin/bash

# Default source directory in $HOME (change as necessary):
DIR="Archive"

ar_usage () {
  printf '%s\n' "Usage: $(basename "$0"): [-r] [-s PATH] [-d PATH]" \
    "Options:" \
    "  -r Reverse default source and destination" \
    "  -s PATH Set source to PATH" \
    "     Default: $HOME/$DIR" \
    "  -d PATH Set destination to PATH" \
    "     Default: user selected mounted device" >&2
  exit 1
}

while getopts :rs:d: Flag; do
  case $Flag in
    r) Reverse="true" ;;
    s) From="$OPTARG" ;;
    :) printf '%s\n' "Invalid flag: -$OPTARG requires an argument!" >&2
       exit 1 ;;
    d) To="$OPTARG" ;;
    :) printf '%s\n' "Invalid flag: -$OPTARG requires an argument!" >&2
       exit 1 ;;
    \?) ar_usage ;;
  esac
done
shift $((OPTIND -1))

ar_sync () {
  local Free Used Sync
  Free="$(df -h "$ToDir" | awk '!/Filesystem/ {print $4}')"
  Used="$(df -h "$ToDir" | awk '!/Filesystem/ {print $3}')"
  printf '%s\n\n' "[Free space: $Free] [Used space: $Used]"
  read -r -p "Sync $From to $To? [y/n] " Sync
  if [ "$Sync" = y ]; then
    rsync -amu --delete --progress "$From" "$To"
  fi
  if [ "${MntArr2[0]}" ]; then
    printf '\n'
    chk_umount_args "${DevArr2[0]}"
  fi
}

chk_space () {
  local DIRTotal FSTotal
  DIRTotal="$(du -ms "$From" | awk '{print $1}')"
  FSTotal="$(df -m "$ToDir" | awk '!/Filesystem/ {print $2}')"
  if [ "$FSTotal" -lt "$DIRTotal" ]; then
    printf '%s\n' "Insufficient space on $To for $From!"
    if [ "${MntArr2[0]}" ]; then
      chk_umount_args "${DevArr2[0]}"
    fi
    exit 1
  fi
}

chk_from () {
  local TSlash MntCD
  case $From in
    */) read -r -p "Drop trailing slash from '$From'? [y/n] " TSlash
        if [ "$TSlash" = y ]; then
          From="${From%/}"
        fi ;;
  esac
  if [ ! -d "$From" ]; then
    if [ -x "$(command -v get-mnt.sh)" ]; then
      read -r -p "Mount a connected device for '$From'? [y/n] " MntCD
      if [ "$MntCD" = y ]; then
        source get-mnt.sh
        if [ ! -d "$From" ]; then
          printf '%s\n' "Source '$From' not found!" >&2
          chk_umount_args "${DevArr2[0]}"
          exit 1
        fi
      fi
    fi
    printf '%s\n' "Source '$From' not found!" >&2
    exit 1
  fi
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
            printf '%s\n' "Destination '$To' not writable!" >&2
          elif [ ! -d "$To" ] && [ ! -d "$ToDir" ]; then
            printf '%s\n' "Base destination '$ToDir' not found!" >&2
          elif [ ! -d "$To" ] && [ ! -w "$ToDir" ]; then
            printf '%s\n' "Base destination '$ToDir' not writable!" >&2
          else
            return
          fi
          chk_umount_args "${DevArr2[0]}"
          exit 1
        elif [ -d "$ToDir" ] && [ -w "$ToDir" ]; then
          return
        fi
      elif [ -d "$ToDir" ] && [ -w "$ToDir" ]; then
        return
      fi
    fi
    printf '%s\n' "Destination '$To' not found!" >&2
    exit 1
  elif [ ! -w "$To" ]; then
    printf '%s\n' "Destination '$To' not writable!" >&2
    exit 1
  else
    ToDir="$To"
  fi
}

chk_get_mnt () {
  if [ -x "$(command -v get-mnt.sh)" ]; then
    source get-mnt.sh
  else
    printf '%s\n' "Setting default $1 requires get-mnt.sh!" \
      "Please visit https://github.com/brianchase/get-mnt" >&2
    exit 1
  fi
}

set_defaults () {
  if [ "$Reverse" ]; then
    To="$HOME"
    chk_to
    if chk_get_mnt source; then
      From="${MntArr2[0]}/$DIR"
      chk_from
    fi
  else
    if [ -z "$From" ]; then
      From="$HOME/$DIR"
    fi
    chk_from
    if [ -z "$To" ] && chk_get_mnt destination; then
      To="${MntArr2[0]}"
    fi
    chk_to
  fi
}

ar_opts () {
  if [ "$Reverse" ] && [ "$From" ]; then
    printf '%s\n' "Invalid flags: -r and -s conflict!" >&2
    exit 1
  elif [ "$Reverse" ] && [ "$To" ]; then
    printf '%s\n' "Invalid flags: -r and -d conflict!" >&2
    exit 1
  elif [ "$From" ] && [ "$To" ]; then
    if [ "$From" = "$To" ]; then
      printf '%s\n' "Source and destination paths are the same!" >&2
      exit 1
    fi
  fi
}

ar_main () {
  ar_opts
  set_defaults
  chk_space
  ar_sync
}

case $1 in
  ''|-r|-s|-d) ar_main ;;
  *) ar_usage ;;
esac
