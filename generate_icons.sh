#!/bin/bash

# Script pour générer toutes les icônes iOS à partir du logo Ilium
echo "🎨 Génération des icônes iOS pour Ilium..."

# Répertoire source et destination
SOURCE_LOGO="assets/images/Logo_Ilium-removebg-preview.png"
IOS_ICONS_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Vérifier que le logo source existe
if [ ! -f "$SOURCE_LOGO" ]; then
    echo "❌ Erreur : Logo source non trouvé : $SOURCE_LOGO"
    exit 1
fi

echo "📱 Génération des icônes iPhone..."

# iPhone icons
sips -z 40 40 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-20x20@2x.png"
sips -z 60 60 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-20x20@3x.png"
sips -z 29 29 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-29x29@1x.png"
sips -z 58 58 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-29x29@2x.png"
sips -z 87 87 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-29x29@3x.png"
sips -z 80 80 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-40x40@2x.png"
sips -z 120 120 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-40x40@3x.png"
sips -z 120 120 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-60x60@2x.png"
sips -z 180 180 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-60x60@3x.png"

echo "📱 Génération des icônes iPad..."

# iPad icons
sips -z 20 20 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-20x20@1x.png"
sips -z 40 40 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-40x40@1x.png"
sips -z 76 76 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-76x76@1x.png"
sips -z 152 152 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-76x76@2x.png"
sips -z 167 167 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-83.5x83.5@2x.png"

echo "🏪 Génération de l'icône App Store..."

# App Store icon
sips -z 1024 1024 "$SOURCE_LOGO" --out "$IOS_ICONS_DIR/Icon-App-1024x1024@1x.png"

echo "✅ Génération des icônes terminée !"
echo "📂 Icônes générées dans : $IOS_ICONS_DIR"
echo ""
echo "🔧 Prochaines étapes :"
echo "1. Vérifiez les icônes générées"
echo "2. Lancez 'flutter clean && flutter pub get'"
echo "3. Rebuild l'application iOS"