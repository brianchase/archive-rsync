#!/bin/bash

# Default source directory in $HOME (change as necessary):
DIR="Archive"

br_usage () {
  printf '%s\n' "Usage: $(basename $0): [-r] [-s PATH] [-d PATH]"
  printf '%s\n' "Options:"
  printf '%10s  %s\n' "-r" "reverse default source and destination"
  printf '%10s  %s\n' "-s PATH" "change source to PATH"
  printf '%10s  %s\n' "" "default: $HOME/$DIR"
  printf '%10s  %s\n' "-d PATH" "change destination to PATH"
  printf '%10s  %s\n' "" "default: user selected mounted device"
  exit 1
}

while getopts :rs:d: FLAG; do
  case $FLAG in
    r) RVS="true" ;;
    s) FROM="$OPTARG" ;;
    :) printf '%s\n' "Invalid flag: -$OPTARG requires an argument"
       exit 1 ;;
    d) TO="$OPTARG" ;;
    :) printf '%s\n' "Invalid flag: -$OPTARG requires an argument"
       exit 1 ;;
    \?) br_usage ;;
  esac
done
shift $((OPTIND -1))

br_sync () {
  FREE="$(df -h "$TOdname" | awk '!/Filesystem/ {print $4}')"
  USED="$(df -h "$TOdname" | awk '!/Filesystem/ {print $3}')"
  printf '%s\n\n' "[Free space: $FREE] [Used space: $USED]"
  read -r -p "Sync $FROM to $TO? [y/n] " SYNC
  if [ "$SYNC" = y ]; then
    rsync -amu --delete --progress "$FROM" "$TO"
  fi
  if [ "${B2[0]}" ]; then
    printf '\n'
    unmount_a2
  fi
}

chk_space () {
  DIRTotal="$(du -ms "$FROM" | awk '{print $1}')"
  FSTotal="$(df -m "$TOdname" | awk '!/Filesystem/ {print $2}')"
  if [ "$FSTotal" -lt "$DIRTotal" ]; then
    printf '%s\n' "Insufficient space on $TO for $FROM!"
    if [ "${B2[0]}" ]; then
      unmount_a2
    fi
    exit 1
  fi
}

chk_from_dir () {
  case $FROM in
    */) read -r -p "Drop trailing slash from '$FROM'? [y/n] " TS
        if [ "$TS" = y ]; then
          FROM="${FROM%/}"
        fi ;;
  esac
  if [ ! -d "$FROM" ]; then
    if chk_get_mnt; then
      read -r -p "Mount a connected device for '$FROM'? [y/n] " CD
      if [ "$CD" = y ]; then
        source get-mnt.sh
        if [ ! -d "$FROM" ]; then
          printf '%s\n' "Source '$FROM' not found!"
          unmount_a2
          exit 1
        fi
      fi
    fi
    printf '%s\n' "Source '$FROM' not found!"
    exit 1
  fi
}

chk_get_mnt () {
  if [ ! -x "$(command -v get-mnt.sh)" ]; then
    printf '%s\n' "get-mnt.sh not found!"
    printf '%s\n' "Please visit https://github.com/brianchase/get-mnt"
    exit 1
  fi
}

chk_to_dir () {

# Since rsync can create the directory at the end of the destination
# path, you need to check more than just whether $TO is a directory.

  if [ ! -d "$TO" ]; then
    if TOdname="$(dirname "$TO" 2>/dev/null)"; then
      if chk_get_mnt; then
        read -r -p "Mount a connected device for '$TO'? [y/n] " CD
        if [ "$CD" = y ]; then
          source get-mnt.sh
          if [ ! -d "$TOdname" ]; then
            printf '%s\n' "Base destination '$TOdname' not found!"
            unmount_a2
            exit 1
          elif [ ! -d "$TO" ] && [ ! -w "$TOdname" ]; then
            printf '%s\n' "Base destination '$TOdname' not writable!"
            unmount_a2
            exit 1
          fi
          return
        fi
      fi
    fi
    printf '%s\n' "Destination '$TO' not found!"
    exit 1
  else
    TOdname="$TO"
  fi
}

get_defaults () {
  if [ "$RVS" ]; then
    TO="$HOME"
    chk_to_dir
    if chk_get_mnt; then
      source get-mnt.sh
      FROM="${B2[0]}/$DIR"
      chk_from_dir
    fi
  else
    if [ -z "$FROM" ]; then
      FROM="$HOME/$DIR"
    fi
    chk_from_dir
    if [ -z "$TO" ]; then
      if chk_get_mnt; then
        source get-mnt.sh
        TO="${B2[0]}"
      fi
    fi
    chk_to_dir
  fi
}

br_opts () {
  if [ "$RVS" ] && [ "$FROM" ]; then
    printf '%s\n' "Invalid flags: -r and -s conflict!"
    exit 1
  elif [ "$RVS" ] && [ "$TO" ]; then
    printf '%s\n' "Invalid flags: -r and -d conflict!"
    exit 1
  elif [ "$FROM" ] && [ "$TO" ]; then
    if [ "$FROM" = "$TO" ]; then
      printf '%s\n' "Source and destination paths are the same!"
      exit 1
    fi
  fi
}

br_main () {
  br_opts
  get_defaults
  chk_space
  br_sync
}

case $1 in
  ''|-r|-s|-d) br_main ;;
  *) br_usage ;;
esac
