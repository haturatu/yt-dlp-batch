#!/bin/bash

# Configure ###############################
URLS_FILE="$1"
DOWNLOAD_DIR="$2"
############################################

REALPATH=$(realpath $URLS_FILE)
FILENAME=$(basename $REALPATH)

_error_exit() {
    echo "Error: $1" >&2
    exit 1
}

_warn() {
    echo "Warning: $1" >&2
}

# Check if yt-dlp is installed
command -v yt-dlp >/dev/null 2>&1 || error_exit "yt-dlp is not installed. Please install it and try again."

help() {
  echo "Usage: $0 <urls_file> <download_directory>"
  echo "  <urls_file>         Path to the text file containing video URLs (one per line)."
  echo "  <download_directory> Directory where downloaded videos will be saved."
}

check_modified() {
  local file="$1"
  local dir=$(dirname "$file")
  local last_modified_time=$(stat -c %Y "$file") # check unix time of last modification

  cd dir || return 1
  if [ -f ".last_modified_$FILENAME" ]; then
    local last_recorded_time=$(cat .last_modified)
    if [ "$last_modified_time" -le "$last_recorded_time" ]; then
      exit 0 # Not modified
    else
      echo "$last_modified_time" > .last_modified
      return 0 # Modified
    fi
  else
    echo "$last_modified_time" > .last_modified_$FILENAME
    return 0 # First time, consider as modified
  fi
}

yt_dlp_download() {
  local file="$1"
  local download_dir="$2"

  mkdir -p "$download_dir" || error_exit "Failed to create download directory '$download_dir'."

  while IFS= read -r url || [ -n "$url" ]; do
    if [ -n "$url" ]; then
      yt-dlp --merge-output-format mp4 -o "$download_dir/%(title)s.%(ext)s" "$url" || _warn "Failed to download: $url"
    fi
  done < "$file"
}

main() {
  local file="$REALPATH"
  local download_dir="$DOWNLOAD_DIR"
  [ -f "$URLS_FILE" ] || help ; _error_exit "URLs file '$URLS_FILE' not found."
  [ -n "$DOWNLOAD_DIR" ] || help ; _error_exit "Download directory not specified."

  check_modified "$file"
  if [ $? -eq 0 ]; then
    yt_dlp_download "$file" "$download_dir"
  else
    printf "No changes detected in '%s'. Skipping download.\n" "$file"
  fi
}
