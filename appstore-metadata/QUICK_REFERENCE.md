# Quick Reference Card

## 📱 App Information

| Field | Value |
|-------|-------|
| **App Name (EN)** | Sticker Maker - GIF Creator |
| **App Name (KO)** | 스티커 메이커 - GIF 제작 |
| **Bundle ID** | com.yourcompany.stickermaker |
| **Version** | 1.0 |
| **Build** | 1 |
| **iOS Requirement** | 17.0+ |
| **Category** | Photo & Video |
| **Price** | Free |
| **Age Rating** | 4+ |

## 🌐 URLs

| Type | URL |
|------|-----|
| **Website** | https://yelerty.github.io/stickermaker/ |
| **Privacy Policy** | https://yelerty.github.io/stickermaker/privacy-policy.html |
| **Terms of Service** | https://yelerty.github.io/stickermaker/terms-of-service.html |
| **Support** | https://yelerty.github.io/stickermaker/support.html |
| **Email** | support@stickermaker.app |
| **GitHub** | https://github.com/yelerty/stickermaker |

## 📸 Screenshot Sizes

| Device | Size (pixels) | Count |
|--------|---------------|-------|
| **iPhone 6.7"** | 1290 x 2796 | 5-6 |
| **iPhone 6.5"** | 1242 x 2688 | 5-6 |
| **iPad Pro 12.9"** | 2048 x 2732 | 5-6 |

## 🎨 App Icon

- **Size:** 1024 x 1024 pixels
- **Format:** PNG (no transparency)
- **Location:** Assets.xcassets/AppIcon

## 📝 Character Limits

| Field | Limit | Current (EN) | Current (KO) |
|-------|-------|--------------|--------------|
| App Name | 30 | 29 | 21 |
| Subtitle | 30 | 27 | 21 |
| Promo Text | 170 | ~170 | ~170 |
| Description | 4000 | ~3500 | ~3500 |
| Keywords | 100 | ~95 | ~95 |

## 🔑 Keywords (Copy-Paste Ready)

**English:**
```
sticker,gif,background,remover,photo,editor,animation,meme,creator,transparent
```

**Korean:**
```
스티커,gif,배경,제거,사진,편집기,애니메이션,밈,제작,투명
```

## 📋 Required Files Checklist

- [x] `en-US/metadata.txt` - English metadata
- [x] `ko/metadata.txt` - Korean metadata
- [ ] `screenshots/en-US/*.png` - English screenshots (5-6 images)
- [ ] `screenshots/ko/*.png` - Korean screenshots (5-6 images)
- [x] App icon (1024x1024)
- [x] Privacy policy (live URL)
- [x] Support page (live URL)

## 🚀 Submission Steps (Ultra-Quick)

1. ✅ Build app in Xcode
2. ✅ Archive (Product > Archive)
3. ✅ Upload to App Store Connect
4. ✅ Create screenshots (see SCREENSHOT_GUIDE.md)
5. ✅ Fill metadata in App Store Connect
6. ✅ Submit for review
7. ⏳ Wait 1-3 days
8. 🎉 Approved!

## 🎯 Key Features (for Reference)

- ✂️ AI Background Removal
- 📸 Photo to GIF (up to 10 photos)
- 🎬 Video to GIF
- 🖼️ Background Compositor
- 🎨 Image Editor (filters, adjustments, text)
- 🌓 Dark Mode
- 🌍 English & Korean
- 🔒 100% Private (zero data collection)

## 📊 Privacy Settings

| Question | Answer |
|----------|--------|
| Do you collect data? | NO |
| Do you track users? | NO |
| Account required? | NO |
| Third-party analytics? | NO |
| Data linked to user? | NO |
| Processing location? | On-device only |

## 📧 Contact Information

**Support Email:** support@stickermaker.app
**Developer Name:** [Your Name/Company]
**Developer Location:** [Your Location]

## 🎬 App Preview Video (Optional)

- **Length:** 15-30 seconds
- **Size:** 1290 x 2796 (iPhone 6.7")
- **Format:** MOV or MP4
- **Content:**
  1. App icon + name (2-3s)
  2. Background removal demo (5-8s)
  3. GIF creation demo (5-8s)
  4. Feature highlights (5-8s)
  5. "Download Now" (2-3s)

## 🏷️ Version History

### Version 1.0 (Initial Release)
- AI-powered background removal
- Photo to GIF creation
- Video to GIF conversion
- Background compositor
- Image editor with filters
- Dark mode support
- English & Korean localization
- 100% privacy-focused

## ⚡ Quick Commands

### Build for Simulator
```bash
xcodebuild -project stickermaker.xcodeproj \
  -scheme stickermaker \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max'
```

### Capture Screenshot in Simulator
- Press `Cmd + S`
- Screenshots saved to Desktop

### Add Photos to Simulator
```bash
xcrun simctl addmedia booted /path/to/photo.jpg
```

## 📱 Test Devices

Test on these simulators before submission:
- [ ] iPhone 15 Pro Max (6.7")
- [ ] iPhone 15 Pro (6.1")
- [ ] iPad Pro 12.9" (6th gen)
- [ ] iPhone SE (smallest screen)

Test these features:
- [ ] Photo library permission
- [ ] Background removal
- [ ] Photo GIF creation
- [ ] Video GIF creation
- [ ] Background compositor
- [ ] Image editor
- [ ] Dark mode toggle
- [ ] Language switching (EN/KO)

## 🎨 Color Palette (for Marketing)

Primary gradient: `#667eea` → `#764ba2`

Use for:
- Website headers
- Marketing materials
- Social media graphics
- Email templates

## 📈 ASO (App Store Optimization) Tips

1. **Title:** Include main keyword "Sticker Maker"
2. **Subtitle:** Highlight "GIF Creator" benefit
3. **Keywords:** Focus on "sticker", "gif", "background remover"
4. **Description:** Front-load features in first 3 lines
5. **Screenshots:** Show before/after results
6. **Reviews:** Encourage users to review (in-app prompt in future update)

## 🔗 Marketing Links (Update After Approval)

App Store Link Format:
```
https://apps.apple.com/app/id[APP_ID]
```

Short Link (Create after approval):
```
https://itunes.apple.com/app/id[APP_ID]
```

QR Code Generator:
```
https://qr.io/ (use App Store link)
```

## 📅 Launch Checklist

**Day of Approval:**
- [ ] Download and test app from App Store
- [ ] Update GitHub README with App Store badge
- [ ] Update website with "Download" button
- [ ] Post on social media
- [ ] Send press release
- [ ] Email newsletter (if applicable)
- [ ] Update docs/ pages with actual App Store link

**Week 1:**
- [ ] Monitor reviews and ratings
- [ ] Respond to user feedback
- [ ] Track downloads in App Store Connect
- [ ] Check crash reports
- [ ] Plan first update based on feedback

## 💡 Tips

- **Screenshot quality matters** - Use high-res, appealing photos
- **Description first 3 lines** - Most users only read these
- **Keywords** - Research competitors for inspiration
- **Promo text** - Update this frequently (no review needed)
- **Reviews** - Respond to all reviews promptly

---

Print this page and keep it handy during submission! 📋
