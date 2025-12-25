#!/bin/bash

# Screenshot Organization Script
# Helps move and rename screenshots from Desktop

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Screenshot Organization Tool                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check for screenshots on Desktop
DESKTOP="$HOME/Desktop"
SCREENSHOT_COUNT=$(ls "$DESKTOP"/Screenshot*.png 2>/dev/null | wc -l | tr -d ' ')

echo "Found $SCREENSHOT_COUNT screenshots on Desktop"
echo ""

if [ "$SCREENSHOT_COUNT" -eq 0 ]; then
    echo "❌ No screenshots found on Desktop."
    echo ""
    echo "To capture screenshots:"
    echo "  1. Focus on Simulator window"
    echo "  2. Press Cmd + S"
    echo "  3. Screenshot saved to Desktop"
    exit 0
fi

# List screenshots
echo "Screenshots found:"
ls -lt "$DESKTOP"/Screenshot*.png | head -20

echo ""
echo "─────────────────────────────────────────────────────────────"
echo "Choose language to organize:"
echo "  1) English (en-US)"
echo "  2) Korean (ko)"
echo "  3) List files and exit"
echo "─────────────────────────────────────────────────────────────"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        DEST_DIR="appstore-metadata/screenshots/en-US"
        LANG="English"
        ;;
    2)
        DEST_DIR="appstore-metadata/screenshots/ko"
        LANG="Korean"
        ;;
    3)
        echo ""
        echo "Screenshots on Desktop:"
        ls -lth "$DESKTOP"/Screenshot*.png
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Organizing $LANG screenshots to: $DEST_DIR"
echo ""

# Create destination directory if needed
mkdir -p "$DEST_DIR"

# Interactive rename
echo "─────────────────────────────────────────────────────────────"
echo "Rename and move screenshots:"
echo ""
echo "Screenshot names:"
echo "  1. 01-sticker-background-removal.png"
echo "  2. 02-photo-gif-creation.png"
echo "  3. 03-video-to-gif.png"
echo "  4. 04-background-compositor.png"
echo "  5. 05-image-editor.png"
echo "  6. 06-dark-mode.png"
echo ""

# List screenshots with numbers
i=1
for file in "$DESKTOP"/Screenshot*.png; do
    if [ -f "$file" ]; then
        echo "$i) $(basename "$file")"
        i=$((i + 1))
    fi
done

echo ""
echo "─────────────────────────────────────────────────────────────"
echo "Enter screenshot numbers to organize (space-separated):"
echo "Example: 1 2 3 4 5 (for 5 screenshots)"
echo "Or 'auto' to auto-organize the first 6 screenshots"
echo "─────────────────────────────────────────────────────────────"
read -p "Choice: " selection

if [ "$selection" == "auto" ]; then
    echo ""
    echo "Auto-organizing first 6 screenshots..."

    i=1
    for file in "$DESKTOP"/Screenshot*.png; do
        if [ -f "$file" ] && [ $i -le 6 ]; then
            case $i in
                1) name="01-sticker-background-removal.png" ;;
                2) name="02-photo-gif-creation.png" ;;
                3) name="03-video-to-gif.png" ;;
                4) name="04-background-compositor.png" ;;
                5) name="05-image-editor.png" ;;
                6) name="06-dark-mode.png" ;;
            esac

            echo "  Moving: $(basename "$file") → $name"
            mv "$file" "$DEST_DIR/$name"
            i=$((i + 1))
        fi
    done
else
    # Manual selection
    echo ""
    echo "Manual mode not implemented. Use 'auto' or move files manually."
fi

echo ""
echo "✅ Organization complete!"
echo ""
echo "Screenshots saved to: $DEST_DIR/"
ls -lh "$DEST_DIR"

echo ""
echo "Run ./verify_screenshots.sh to verify dimensions"
