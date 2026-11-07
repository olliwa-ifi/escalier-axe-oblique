#!/bin/bash

# ==============================================================================
# Script de build et d'installation pour Stair Square Generator (.rbz)
# ==============================================================================

PLUGIN_BASE_NAME="stair_plugin_square"
SOURCE_DIR="src"
CONSTANTS_FILE="$SOURCE_DIR/$PLUGIN_BASE_NAME/config.rb"

# Chemin vers le dossier Plugins de SketchUp 2020 (Format Git Bash pour Windows)
SKETCHUP_PLUGINS_DIR="$APPDATA/SketchUp/SketchUp 2020/SketchUp/Plugins"

echo "------------------------------------------------------------"
echo "📦 Building $PLUGIN_BASE_NAME"
echo "------------------------------------------------------------"

# 1. Extraction de la version depuis config.rb
if [ -f "$CONSTANTS_FILE" ]; then
    echo "✅ Found $CONSTANTS_FILE"
    VERSION=$(grep "VERSION =" "$CONSTANTS_FILE" | awk -F'"' '{print $2}' | tr -d '\r\n ')
else
    echo "❌ Error: $CONSTANTS_FILE not found."
    exit 1
fi

if [ -z "$VERSION" ]; then
    echo "❌ Error: Could not extract VERSION from $CONSTANTS_FILE"
    exit 1
fi

echo "Version detected: $VERSION"
FINAL_FILENAME="${PLUGIN_BASE_NAME}_v${VERSION}.rbz"

# 2. Création du dossier release
mkdir -p release

# 3. Compression (7z)
echo "Compressing..."
(
    cd "$SOURCE_DIR" && \
    7z a -tzip "../release/$FINAL_FILENAME" "$PLUGIN_BASE_NAME.rb" "$PLUGIN_BASE_NAME/"
)

# 4. Installation (Dézippage dans SketchUp 2020)
if [ $? -eq 0 ]; then
    echo "------------------------------------------------------------"
    echo "✅ Success! Generated: release/$FINAL_FILENAME"
    echo "------------------------------------------------------------"
    
    echo "🚚 Installing to SketchUp 2020 Plugins folder..."
    
    if [ -d "$SKETCHUP_PLUGINS_DIR" ]; then
        # -y force l'écrasement des fichiers existants sans validation
        7z x "release/$FINAL_FILENAME" "-o$SKETCHUP_PLUGINS_DIR" -y
        
        if [ $? -eq 0 ]; then
            echo "✅ Plugin successfully installed (forced) to: $SKETCHUP_PLUGINS_DIR"
        else
            echo "❌ Error: Extraction failed during installation."
        fi
    else
        echo "❌ Error: SketchUp 2020 Plugins directory not found at $SKETCHUP_PLUGINS_DIR"
    fi
else
    echo "❌ Error: Compression failed."
    exit 1
fi



cd ../
