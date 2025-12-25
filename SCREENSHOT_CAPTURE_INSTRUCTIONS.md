# Screenshot Capture Instructions

## ✅ Setup Complete!

The app is now running on **iPhone 17 Pro Max simulator** (1290 x 2796 pixels - perfect for App Store).

## 📸 How to Capture Screenshots

### Method 1: Using Simulator (Recommended)

1. **Focus on Simulator window**
2. **Press `Cmd + S`** to capture screenshot
3. Screenshot will be saved to your **Desktop**
4. Move screenshots to appropriate folder later

### Method 2: Using Simulator Menu

1. Click **File > New Screen Shot** in Simulator menu
2. Or right-click simulator window > **Save Screen**

## 🎯 Screenshots Needed (In Order)

### English Version (en-US) - 6 Screenshots

#### Screenshot 1: Sticker Maker - Background Removal ✂️
**What to show:**
- [ ] Navigate to "Sticker" tab
- [ ] Tap "Select Photo" or "Create from Photo"
- [ ] Choose a photo with a clear person/object
- [ ] Wait for AI background removal to complete
- [ ] Show the result with transparent background
- [ ] Make sure "Save" button is visible

**Capture when:** Result is displayed with background removed

**Save as:** `01-sticker-background-removal.png`

---

#### Screenshot 2: Photo GIF Creation 📸
**What to show:**
- [ ] Navigate to "Photo GIF" tab
- [ ] Select 3-5 photos from library
- [ ] Show selected photos in the interface
- [ ] Display GIF settings (frame speed slider)
- [ ] Show "Remove Background" toggle
- [ ] "Create GIF" button visible

**Capture when:** Photos selected, settings panel visible

**Save as:** `02-photo-gif-creation.png`

---

#### Screenshot 3: Video to GIF 🎬
**What to show:**
- [ ] Navigate to "Video GIF" tab
- [ ] Select a video
- [ ] Show video thumbnail/preview
- [ ] Display timeline with start/end selection
- [ ] Show settings: Frame count, Frame delay
- [ ] Aspect ratio options visible
- [ ] "Create GIF" button shown

**Capture when:** Video loaded, all settings visible

**Save as:** `03-video-to-gif.png`

---

#### Screenshot 4: Background Compositor 🖼️
**What to show:**
- [ ] Navigate to "Background" tab
- [ ] Select person photo (background removed)
- [ ] Select background image
- [ ] Show composed result
- [ ] Display adjustment sliders (Person Size, Position)
- [ ] "Save" button visible

**Capture when:** Composition complete with sliders visible

**Save as:** `04-background-compositor.png`

---

#### Screenshot 5: Image Editor 🎨
**What to show:**
- [ ] Open image editor (from Sticker or any feature)
- [ ] Show editing interface
- [ ] Display filter options (Noir, Chrome, Fade, etc.)
- [ ] Show sliders (Brightness, Contrast, Saturation)
- [ ] Text/emoji tools visible (if possible)
- [ ] Apply button shown

**Capture when:** Editor open with all tools visible

**Save as:** `05-image-editor.png`

---

#### Screenshot 6: Dark Mode / Privacy Features (Optional) 🌓
**Option A - Dark Mode:**
- [ ] Enable dark mode: Settings app > Appearance > Dark
- [ ] Reopen app
- [ ] Show main interface in dark mode
- [ ] Capture any main tab

**Option B - Feature List (Create manually):**
- Create a simple screen showing:
  - 🔒 Zero Data Collection
  - ⚡ All Processing On-Device
  - 🌓 Dark Mode Support
  - 🌍 Multi-Language (EN/KO)
  - 📦 Sticker Pack Manager

**Save as:** `06-dark-mode.png` or `06-privacy-features.png`

---

### Korean Version (ko) - Same 6 Screenshots

**Steps:**
1. **Change iOS language to Korean:**
   - Open Simulator **Settings** app
   - Go to **General > Language & Region**
   - Change **iPhone Language** to **한국어 (Korean)**
   - Tap **Done** and confirm
   - Device will restart with Korean

2. **Reopen Sticker Maker app**

3. **Capture same 6 screenshots** as English version

4. **Save with same naming:**
   - `01-sticker-background-removal.png`
   - `02-photo-gif-creation.png`
   - `03-video-to-gif.png`
   - `04-background-compositor.png`
   - `05-image-editor.png`
   - `06-dark-mode.png`

---

## 📁 Organizing Screenshots

### After Capturing All Screenshots:

1. **Find screenshots on Desktop** (named like "Screenshot 2024-12-25 at...png")

2. **Move to appropriate folders:**

```bash
# For English screenshots:
mv ~/Desktop/Screenshot*.png appstore-metadata/screenshots/en-US/

# Rename them:
cd appstore-metadata/screenshots/en-US/
mv "Screenshot 2024-12-25 at 22.59.00.png" 01-sticker-background-removal.png
mv "Screenshot 2024-12-25 at 23.00.00.png" 02-photo-gif-creation.png
# ... etc
```

```bash
# For Korean screenshots:
mv ~/Desktop/Screenshot*.png appstore-metadata/screenshots/ko/

# Rename them similarly
cd appstore-metadata/screenshots/ko/
mv "Screenshot 2024-12-25 at 23.10.00.png" 01-sticker-background-removal.png
# ... etc
```

---

## ✅ Screenshot Quality Checklist

Before finalizing, check each screenshot:

- [ ] **Correct size:** 1290 x 2796 pixels (iPhone 17 Pro Max)
- [ ] **High resolution:** Clear and sharp, not blurry
- [ ] **Correct language:** English screenshots show English UI, Korean show Korean UI
- [ ] **No debug UI:** No Xcode overlays or debug information
- [ ] **Professional content:** Use appealing, high-quality photos
- [ ] **Feature is clear:** Main feature of each screenshot is obvious
- [ ] **Status bar clean:** Realistic time, battery, signal
- [ ] **No placeholders:** All text is real, no "Lorem ipsum"

---

## 🎨 Tips for Great Screenshots

### Photo Selection:
- **Use colorful, high-quality images**
- **Clear subjects** (people, objects with good contrast)
- **Varied content** (different people, objects across screenshots)
- **Professional looking** (avoid silly/inappropriate content)

### UI State:
- **Show successful results**, not loading states
- **Feature should be obvious** in each screenshot
- **Buttons should be visible** (Save, Create GIF, etc.)
- **Settings/sliders shown** where applicable

### Composition:
- **Center the main content**
- **Avoid empty screens**
- **Show enough detail** to understand the feature
- **Consistent style** across all screenshots

---

## 🔧 Troubleshooting

### Problem: Screenshots are wrong size
**Solution:** Use iPhone 17 Pro Max simulator only

### Problem: Can't find screenshots
**Solution:** Check Desktop, or use File > Show in Finder

### Problem: App crashes or freezes
**Solution:**
```bash
# Reset simulator
xcrun simctl shutdown all
xcrun simctl boot "iPhone 17 Pro Max"
xcrun simctl launch booted yelerty.stickermaker
```

### Problem: Need to add photos to simulator
**Solution:**
```bash
# Drag photos to simulator window, or:
xcrun simctl addmedia booted /path/to/photo.jpg
```

### Problem: Language won't change
**Solution:**
- Settings > General > Language & Region > iPhone Language
- Select 한국어, tap Done, confirm restart
- Reopen app

---

## 📊 Verify Screenshot Dimensions

After capturing, verify sizes:

```bash
cd appstore-metadata/screenshots/en-US/
sips -g pixelWidth -g pixelHeight *.png
```

All should show:
```
pixelWidth: 1290
pixelHeight: 2796
```

---

## 🚀 Quick Capture Commands

```bash
# Check simulator status
xcrun simctl list | grep "iPhone 17 Pro Max"

# Relaunch app if needed
xcrun simctl launch booted yelerty.stickermaker

# Take screenshot programmatically
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# Add sample photos
xcrun simctl addmedia booted ~/Pictures/*.jpg
```

---

## 📝 Screenshot Checklist

### English (en-US):
- [ ] 01-sticker-background-removal.png (Sticker tab, background removed)
- [ ] 02-photo-gif-creation.png (Photo GIF tab, photos selected)
- [ ] 03-video-to-gif.png (Video GIF tab, video loaded)
- [ ] 04-background-compositor.png (Background tab, composition shown)
- [ ] 05-image-editor.png (Editor open, tools visible)
- [ ] 06-dark-mode.png or 06-privacy-features.png (Optional)

### Korean (ko):
- [ ] 01-sticker-background-removal.png (Korean UI)
- [ ] 02-photo-gif-creation.png (Korean UI)
- [ ] 03-video-to-gif.png (Korean UI)
- [ ] 04-background-compositor.png (Korean UI)
- [ ] 05-image-editor.png (Korean UI)
- [ ] 06-dark-mode.png (Korean UI)

---

## 🎉 When Complete

After all screenshots are captured and organized:

```bash
# Verify all files
ls -la appstore-metadata/screenshots/en-US/
ls -la appstore-metadata/screenshots/ko/

# Check dimensions
cd appstore-metadata/screenshots/en-US/
sips -g pixelWidth -g pixelHeight *.png

# Commit to git
git add appstore-metadata/screenshots/
git commit -m "Add App Store screenshots for English and Korean"
git push origin master
```

---

**Current Status:**
✅ Simulator running (iPhone 17 Pro Max)
✅ App launched and ready
✅ Screenshot directories created
⏳ Ready to capture - follow the guide above!

**Start with Screenshot #1 (Sticker - Background Removal)**
Press `Cmd + S` in Simulator to capture!
