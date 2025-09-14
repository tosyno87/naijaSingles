#!/bin/bash

# Script to generate all required iOS app icon sizes from the Afropeep logo
# Usage: ./generate_app_icons.sh

SOURCE_LOGO="afropeep_logo_transparent_new.png"
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Check if source logo exists
if [ ! -f "$SOURCE_LOGO" ]; then
    echo "❌ Source logo file '$SOURCE_LOGO' not found!"
    exit 1
fi

echo "🎨 Generating iOS app icons from: $SOURCE_LOGO"
echo "📁 Output directory: $ICON_DIR"

# Create backup of existing icons
echo "💾 Creating backup of existing icons..."
mkdir -p backup_icons
cp $ICON_DIR/*.png backup_icons/ 2>/dev/null || true

# Generate all required icon sizes
echo "🔄 Generating icon sizes..."

# iPhone icons
sips -z 40 40 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-20x20@2x.png"
sips -z 60 60 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-20x20@3x.png"
sips -z 29 29 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-29x29@1x.png"
sips -z 58 58 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-29x29@2x.png"
sips -z 87 87 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-29x29@3x.png"
sips -z 80 80 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-40x40@2x.png"
sips -z 120 120 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-40x40@3x.png"
sips -z 120 120 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-60x60@2x.png"
sips -z 180 180 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-60x60@3x.png"

# iPad icons
sips -z 20 20 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-20x20@1x.png"
sips -z 40 40 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-20x20@2x.png"
sips -z 29 29 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-29x29@1x.png"
sips -z 58 58 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-29x29@2x.png"
sips -z 40 40 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-40x40@1x.png"
sips -z 80 80 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-40x40@2x.png"
sips -z 76 76 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-76x76@1x.png"
sips -z 152 152 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-76x76@2x.png"
sips -z 167 167 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-83.5x83.5@2x.png"

# App Store icon
sips -z 1024 1024 "$SOURCE_LOGO" --out "$ICON_DIR/Icon-App-1024x1024@1x.png"

echo "✅ All iOS app icons generated successfully!"
echo "📱 Icons created:"
echo "   - iPhone: 20x20, 29x29, 40x40, 60x60 (all scales)"
echo "   - iPad: 20x20, 29x29, 40x40, 76x76, 83.5x83.5 (all scales)"
echo "   - App Store: 1024x1024"
echo ""
echo "🔄 Next steps:"
echo "   1. Clean and rebuild your iOS project"
echo "   2. Test the new app icon on device/simulator"
echo "   3. Deploy to App Store Connect"
echo ""
echo "💾 Original icons backed up to: backup_icons/"
