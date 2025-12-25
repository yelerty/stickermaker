#!/bin/bash

# Screenshot Verification Script
# Checks dimensions and counts for App Store screenshots

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          App Store Screenshot Verification                    ║"
echo "╔════════════════════════════════════════════════════════════════╗"
echo ""

REQUIRED_WIDTH=1290
REQUIRED_HEIGHT=2796

# Function to check screenshot dimensions
check_dimensions() {
    local dir=$1
    local lang=$2

    echo "📂 Checking $lang screenshots in: $dir"
    echo "─────────────────────────────────────────────────────────────"

    if [ ! -d "$dir" ]; then
        echo "❌ Directory not found: $dir"
        return 1
    fi

    local count=0
    local valid=0
    local invalid=0

    for file in "$dir"/*.png; do
        if [ -f "$file" ]; then
            count=$((count + 1))
            filename=$(basename "$file")

            # Get dimensions using sips
            width=$(sips -g pixelWidth "$file" | grep pixelWidth | awk '{print $2}')
            height=$(sips -g pixelHeight "$file" | grep pixelHeight | awk '{print $2}')

            if [ "$width" -eq "$REQUIRED_WIDTH" ] && [ "$height" -eq "$REQUIRED_HEIGHT" ]; then
                echo "✅ $filename - ${width}x${height}"
                valid=$((valid + 1))
            else
                echo "❌ $filename - ${width}x${height} (Expected: ${REQUIRED_WIDTH}x${REQUIRED_HEIGHT})"
                invalid=$((invalid + 1))
            fi
        fi
    done

    echo "─────────────────────────────────────────────────────────────"
    echo "Total: $count | Valid: $valid | Invalid: $invalid"

    if [ "$count" -lt 5 ]; then
        echo "⚠️  Warning: Need at least 5 screenshots (found $count)"
    elif [ "$count" -gt 10 ]; then
        echo "⚠️  Warning: Maximum 10 screenshots allowed (found $count)"
    else
        echo "✅ Screenshot count is good ($count)"
    fi

    echo ""
}

# Check English screenshots
check_dimensions "appstore-metadata/screenshots/en-US" "English"

# Check Korean screenshots
check_dimensions "appstore-metadata/screenshots/ko" "Korean"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Required Screenshot Specifications                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Device:     iPhone 6.7\" (iPhone 17 Pro Max)"
echo "  Size:       1290 x 2796 pixels"
echo "  Count:      5-10 screenshots per language"
echo "  Format:     PNG"
echo ""
echo "  English:    appstore-metadata/screenshots/en-US/"
echo "  Korean:     appstore-metadata/screenshots/ko/"
echo ""

# List expected screenshots
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Expected Screenshots                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  01-sticker-background-removal.png"
echo "  02-photo-gif-creation.png"
echo "  03-video-to-gif.png"
echo "  04-background-compositor.png"
echo "  05-image-editor.png"
echo "  06-dark-mode.png (optional)"
echo ""

# Check if specific files exist
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          File Existence Check                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

check_file_exists() {
    local dir=$1
    local lang=$2

    echo "📂 $lang:"
    for i in {1..6}; do
        case $i in
            1) name="01-sticker-background-removal.png" ;;
            2) name="02-photo-gif-creation.png" ;;
            3) name="03-video-to-gif.png" ;;
            4) name="04-background-compositor.png" ;;
            5) name="05-image-editor.png" ;;
            6) name="06-dark-mode.png" ;;
        esac

        if [ -f "$dir/$name" ]; then
            echo "  ✅ $name"
        else
            if [ $i -eq 6 ]; then
                echo "  ⚪ $name (optional)"
            else
                echo "  ❌ $name (missing)"
            fi
        fi
    done
    echo ""
}

check_file_exists "appstore-metadata/screenshots/en-US" "English"
check_file_exists "appstore-metadata/screenshots/ko" "Korean"

echo "════════════════════════════════════════════════════════════════"
echo "✅ Verification complete!"
echo "════════════════════════════════════════════════════════════════"
