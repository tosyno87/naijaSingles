#!/bin/bash

# Script to create a proper app icon with just the symbol (no text)
# Requirements: Heart + Africa symbol, enlarged, on cream background

SOURCE_LOGO="afropeep_logo_transparent_new.png"
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
CREAM_COLOR="#FFF6E5"

echo "🎨 Creating proper app icon (symbol only, no text)"
echo "📁 Source: $SOURCE_LOGO"
echo "🎯 Target: Heart + Africa symbol on cream background"

# Create a temporary working directory
mkdir -p temp_icon_work
cd temp_icon_work

# Create a 1024x1024 canvas with cream background
echo "🖼️ Creating cream background canvas..."
sips -s format png -s dpiHeight 72 -s dpiWidth 72 \
     --setProperty format png \
     --resampleWidth 1024 --resampleHeight 1024 \
     --padToHeightWidth 1024 1024 \
     --padColor "$CREAM_COLOR" \
     "$SOURCE_LOGO" \
     --out "cream_canvas.png"

# Extract just the symbol part (assuming it's in the center)
# We'll crop to get just the heart + Africa symbol without text
echo "✂️ Extracting symbol from logo..."

# Get dimensions of source image
WIDTH=$(sips -g pixelWidth "$SOURCE_LOGO" | grep pixelWidth | awk '{print $2}')
HEIGHT=$(sips -g pixelHeight "$SOURCE_LOGO" | grep pixelHeight | awk '{print $2}')

echo "📐 Source dimensions: ${WIDTH}x${HEIGHT}"

# Crop to get just the top portion (symbol, not text)
# Assuming the symbol is in the top 60% of the image
SYMBOL_HEIGHT=$((HEIGHT * 60 / 100))

sips -c "$SYMBOL_HEIGHT" "$WIDTH" "$SOURCE_LOGO" --out "symbol_only.png"

# Resize symbol to fill 75% of the 1024x1024 canvas
SYMBOL_SIZE=768  # 75% of 1024
sips -z "$SYMBOL_SIZE" "$SYMBOL_SIZE" "symbol_only.png" --out "symbol_resized.png"

# Center the symbol on the cream background
echo "🎯 Centering symbol on cream background..."

# Create final app icon
sips --padToHeightWidth 1024 1024 \
     --padColor "$CREAM_COLOR" \
     "symbol_resized.png" \
     --out "app_icon_final.png"

echo "✅ Created proper app icon: app_icon_final.png"

# Copy back to project directory
cp "app_icon_final.png" "../$SOURCE_LOGO"

echo "🔄 Updated source logo for icon generation"
echo "📱 Ready to generate all iOS app icon sizes"

cd ..
rm -rf temp_icon_work

echo "🎉 App icon preparation complete!"
echo "💡 Next: Run ./generate_app_icons.sh to create all sizes"
