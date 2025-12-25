# App Store Screenshot Guide

## Required Sizes

### iPhone 6.7" Display (iPhone 15 Pro Max, 14 Pro Max, etc.)
- **Required:** 1290 x 2796 pixels
- **Orientation:** Portrait
- **Screenshots needed:** 3-10 (recommended: 5-6)

### iPhone 6.5" Display (iPhone 11 Pro Max, XS Max, etc.)
- **Required:** 1242 x 2688 pixels
- **Orientation:** Portrait
- **Screenshots needed:** 3-10 (recommended: 5-6)

### iPad Pro (12.9-inch) 3rd gen
- **Required:** 2048 x 2732 pixels
- **Orientation:** Portrait
- **Screenshots needed:** 3-10 (recommended: 5-6)

## Screenshot Order & Content

### Screenshot 1: Main Feature - Sticker Maker
**Title:** "Instant Background Removal" / "즉시 배경 제거"
- Show the Sticker tab with a photo selected
- Display the auto-removed background result
- Show before/after if possible
- Highlight the "Save" button

**Key Elements:**
- Clear, professional photo with person/object
- Clean UI visible
- Background successfully removed
- Save button prominently displayed

---

### Screenshot 2: Photo GIF Creation
**Title:** "Create Animated GIFs" / "애니메이션 GIF 제작"
- Show the Photo GIF tab
- Display 3-5 selected photos
- Show GIF settings (frame speed, remove background toggle)
- Display preview of the GIF animation

**Key Elements:**
- Multiple photos selected
- Settings panel visible
- "Create GIF" button shown
- Toggle for background removal visible

---

### Screenshot 3: Video to GIF
**Title:** "Video to GIF Converter" / "비디오 GIF 변환"
- Show the Video GIF tab
- Display video thumbnail with timeline
- Show start/end time selection
- Display frame count and delay settings
- Show aspect ratio options

**Key Elements:**
- Video selected with clear thumbnail
- Timeline with selection handles
- Settings panel with all options
- Professional, clear interface

---

### Screenshot 4: Background Compositor
**Title:** "Custom Backgrounds" / "배경 합성"
- Show the Background tab
- Display person photo with background removed
- Show custom background image
- Display size and position sliders
- Show the composed result

**Key Elements:**
- Clear person cutout
- Attractive background image
- Adjustment sliders visible
- Professional result

---

### Screenshot 5: Image Editor
**Title:** "Powerful Editing Tools" / "강력한 편집 도구"
- Show the image editor interface
- Display filter options
- Show brightness/contrast/saturation sliders
- Display text/emoji options

**Key Elements:**
- Filter previews
- Editing controls
- Clear before/after comparison
- Professional interface

---

### Screenshot 6 (Optional): Privacy & Features
**Title:** "100% Private & Offline" / "100% 프라이빗 & 오프라인"
- Create a feature highlights screen
- List key features with icons:
  - 🔒 Zero data collection
  - ⚡ All processing on device
  - 🌓 Dark mode support
  - 🌍 Multi-language
  - 📦 Sticker pack manager

**Key Elements:**
- Clean, minimal design
- Feature list with icons
- Privacy-focused messaging
- Professional layout

---

## Screenshot Best Practices

### General Guidelines
1. **Use Real Content:** Show actual app functionality, not mockups
2. **High Quality:** Use high-resolution photos for demos
3. **Clean UI:** Ensure no bugs, glitches, or placeholder text
4. **Consistent Language:** All text in screenshots should match the locale (English or Korean)
5. **Status Bar:** Include realistic status bar (time, battery, signal)
6. **Light Mode:** Use light mode for consistency (unless showing dark mode feature)

### Content Selection
1. **Use Appealing Photos:** Choose colorful, high-quality images
2. **Demonstrate Value:** Show successful results, not empty states
3. **Show Key Features:** Each screenshot should highlight a unique feature
4. **Clear Call-to-Action:** Make it obvious what the app does

### Design Tips
1. **Add Captions (Optional):** Consider adding text overlays to highlight features
2. **Use Frames (Optional):** Device frames can make screenshots more professional
3. **Consistent Style:** Maintain visual consistency across all screenshots
4. **Contrast:** Ensure text and UI elements are clearly visible

---

## How to Capture Screenshots

### Using Xcode Simulator

1. **Launch Simulator:**
   ```bash
   xcodebuild -project stickermaker.xcodeproj -scheme stickermaker -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' build
   ```

2. **Run App in Simulator:**
   - Open Xcode
   - Select iPhone 15 Pro Max (6.7" display)
   - Run the app (Cmd + R)

3. **Set Up Content:**
   - Grant photo library permissions
   - Add sample photos to simulator
   - Navigate to each feature
   - Ensure UI is in correct language

4. **Capture Screenshots:**
   - Use: `Cmd + S` in Simulator
   - Or: Screenshot tool in menu bar
   - Screenshots saved to Desktop

5. **Verify Size:**
   - Check image is 1290 x 2796 pixels
   - Rename with descriptive names

### Adding Photos to Simulator

1. **Via Drag & Drop:**
   - Drag photos from Finder to Simulator window
   - Photos app will open automatically

2. **Via Command Line:**
   ```bash
   xcrun simctl addmedia booted /path/to/photo.jpg
   ```

---

## Screenshot Naming Convention

Use clear, descriptive names:

```
en-US/
  01-sticker-maker-background-removal.png
  02-photo-gif-creation.png
  03-video-to-gif-converter.png
  04-background-compositor.png
  05-image-editor-tools.png
  06-privacy-features.png

ko/
  01-스티커-메이커-배경-제거.png
  02-사진-gif-제작.png
  03-비디오-gif-변환.png
  04-배경-합성.png
  05-이미지-편집-도구.png
  06-프라이빗-기능.png
```

---

## Screenshot Frames (Optional)

Consider using tools to add device frames:

1. **Screenshots.pro** - https://screenshots.pro
2. **App Store Screenshot Generator** - https://www.appstorescreenshot.com
3. **Figma Templates** - Search for "App Store Screenshot Template"

---

## Testing Checklist

Before submitting screenshots:

- [ ] All screenshots are correct size (1290 x 2796 for iPhone 6.7")
- [ ] Screenshots show app in correct language (EN/KO)
- [ ] No placeholder text or lorem ipsum
- [ ] No debug UI or developer tools visible
- [ ] Status bar looks realistic
- [ ] All features work correctly in screenshots
- [ ] Images are high quality (not blurry or pixelated)
- [ ] UI is clean and professional
- [ ] Screenshots demonstrate clear value to users
- [ ] Consistent visual style across all screenshots

---

## App Preview Video (Optional)

If creating an app preview video:

- **Duration:** 15-30 seconds
- **Size:** Same as screenshots
- **Content:**
  1. Show app icon and name (2-3 sec)
  2. Background removal demo (5-8 sec)
  3. GIF creation demo (5-8 sec)
  4. Quick feature highlights (5-8 sec)
  5. End with "Download Now" screen (2-3 sec)

**Tools:**
- iMovie
- Final Cut Pro
- Screen recording in Simulator (Cmd + R to record)

---

## Quick Screenshot Script

Save this as `capture_screenshots.sh`:

```bash
#!/bin/bash

# Build and run app in simulator
xcodebuild -project stickermaker.xcodeproj \
  -scheme stickermaker \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
  build

# Open simulator (if not already open)
open -a Simulator

echo "Simulator ready. Capture screenshots with Cmd+S"
echo "Screenshots will be saved to Desktop"
```

---

## Resources

- [App Store Screenshot Specifications](https://help.apple.com/app-store-connect/#/devd274dd925)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines - Screenshots](https://developer.apple.com/design/human-interface-guidelines/app-store)
