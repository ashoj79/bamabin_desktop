#!/bin/bash

set -e

SOURCE="assets/img/icon.png"

mkdir -p build/icons
mkdir -p windows/runner/resources

echo "Generating Windows icon..."

magick "$SOURCE" \
  -define icon:auto-resize=256,128,64,48,32,16 \
  windows/runner/resources/app_icon.ico

echo "Generating Linux icons..."

for SIZE in 16 24 32 48 64 128 256 512; do
    mkdir -p "build/icons/${SIZE}x${SIZE}"
    magick "$SOURCE" \
      -resize "${SIZE}x${SIZE}" \
      "build/icons/${SIZE}x${SIZE}/my_app.png"
done

# echo "Generating macOS icons..."

# mkdir -p build/icons/AppIcon.iconset

# for SIZE in 16 32 128 256 512; do
#     magick "$SOURCE" -resize "${SIZE}x${SIZE}" \
#       "build/icons/AppIcon.iconset/icon_${SIZE}x${SIZE}.png"

#     DOUBLE=$((SIZE * 2))

#     magick "$SOURCE" -resize "${DOUBLE}x${DOUBLE}" \
#       "build/icons/AppIcon.iconset/icon_${SIZE}x${SIZE}@2x.png"
# done

# iconutil -c icns \
#   build/icons/AppIcon.iconset \
#   -o build/icons/AppIcon.icns

echo "Done."
