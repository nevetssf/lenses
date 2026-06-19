#!/usr/bin/env bash
#
# resize-images.sh — shrink images for the web docs site.
#
# Photos straight off a phone/camera are ~4000px wide and >1MB each, which is
# far more than the Material theme ever displays. This downsizes them to a
# sane max dimension and re-encodes the JPEG, typically cutting file size ~90%.
#
# Uses macOS's built-in `sips`, so there are no dependencies to install.
#
# Usage:
#   scripts/resize-images.sh [-w MAXSIZE] [-q QUALITY] [-n] PATH [PATH...]
#
#   PATH      A file or directory. Directories are searched recursively for
#             .jpg/.jpeg/.png files.
#   -w MAXSIZE  Longest side, in pixels (default 1600). Images already at or
#               below this are left untouched (sips never upscales).
#   -q QUALITY  JPEG quality 1-100 (default 80). Ignored for PNGs.
#   -n          Dry run: report what would change without rewriting files.
#
# Examples:
#   scripts/resize-images.sh docs/Canon/images/100mm-f2-ltm
#   scripts/resize-images.sh -w 2000 -q 85 docs/Canon/images/some-lens/IMG_0001.jpeg
#
set -euo pipefail

MAXSIZE=1600
QUALITY=80
DRYRUN=0

while getopts "w:q:nh" opt; do
  case "$opt" in
    w) MAXSIZE="$OPTARG" ;;
    q) QUALITY="$OPTARG" ;;
    n) DRYRUN=1 ;;
    h|*)
      grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed '1d'
      exit 0
      ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -eq 0 ]; then
  echo "error: no PATH given. Run with -h for usage." >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "error: sips not found (this script requires macOS)." >&2
  exit 1
fi

# Collect target files into an array.
files=()
for path in "$@"; do
  if [ -d "$path" ]; then
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find "$path" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)
  elif [ -f "$path" ]; then
    files+=("$path")
  else
    echo "warning: skipping '$path' (not a file or directory)" >&2
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "No images found."
  exit 0
fi

total_before=0
total_after=0

for f in "${files[@]}"; do
  width=$(sips -g pixelWidth "$f" | awk '/pixelWidth/ {print $2}')
  height=$(sips -g pixelHeight "$f" | awk '/pixelHeight/ {print $2}')
  longest=$width
  [ "$height" -gt "$longest" ] && longest=$height

  before=$(stat -f%z "$f")
  total_before=$((total_before + before))

  if [ "$longest" -le "$MAXSIZE" ]; then
    echo "skip   ${f}  (${width}x${height}, already <= ${MAXSIZE}px)"
    total_after=$((total_after + before))
    continue
  fi

  if [ "$DRYRUN" -eq 1 ]; then
    echo "would  ${f}  (${width}x${height} -> longest ${MAXSIZE}px)"
    total_after=$((total_after + before))
    continue
  fi

  # Resize so neither dimension exceeds MAXSIZE; re-encode JPEGs at QUALITY.
  case "$f" in
    *.jpg|*.jpeg|*.JPG|*.JPEG)
      sips -Z "$MAXSIZE" -s formatOptions "$QUALITY" "$f" >/dev/null
      ;;
    *)
      sips -Z "$MAXSIZE" "$f" >/dev/null
      ;;
  esac

  after=$(stat -f%z "$f")
  total_after=$((total_after + after))
  printf 'resize %s  (%sx%s -> %dpx, %.1fMB -> %.1fMB)\n' \
    "$f" "$width" "$height" "$MAXSIZE" \
    "$(echo "$before" | awk '{print $1/1048576}')" \
    "$(echo "$after"  | awk '{print $1/1048576}')"
done

printf '\nTotal: %.1fMB -> %.1fMB\n' \
  "$(echo "$total_before" | awk '{print $1/1048576}')" \
  "$(echo "$total_after"  | awk '{print $1/1048576}')"
