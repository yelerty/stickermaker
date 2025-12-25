# App Store Submission Checklist

Use this checklist to ensure you have everything ready for App Store submission.

## Pre-Submission Requirements

### Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Enrolled in Apple Developer Program
- [ ] Certificates and provisioning profiles configured

### App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] Bundle ID registered (e.g., com.yourcompany.stickermaker)
- [ ] App icon uploaded (1024x1024 PNG, no alpha channel)
- [ ] Primary language selected (English or Korean)

---

## Build & Archive

### Xcode Configuration
- [ ] Version number set (e.g., 1.0)
- [ ] Build number set (e.g., 1)
- [ ] Deployment target: iOS 17.0
- [ ] Signing configured (Automatic or Manual)
- [ ] App icon configured in Assets.xcassets
- [ ] Launch screen configured

### Build Process
- [ ] Archive created in Xcode (Product > Archive)
- [ ] Archive validated successfully
- [ ] Archive uploaded to App Store Connect
- [ ] Processing completed (wait for email notification)

### Testing
- [ ] App tested on physical device
- [ ] All features working correctly
- [ ] No crashes or major bugs
- [ ] UI looks good on different screen sizes
- [ ] Dark mode tested
- [ ] Both languages tested (EN/KO)
- [ ] Photo library permissions working
- [ ] All tabs functional

---

## Metadata - English (en-US)

### Required Fields
- [ ] **App Name:** "Sticker Maker - GIF Creator" (30 chars)
- [ ] **Subtitle:** "Stickers & GIFs Made Easy" (30 chars)
- [ ] **Promotional Text:** [See metadata.txt] (170 chars)
- [ ] **Description:** [See metadata.txt] (4000 chars)
- [ ] **Keywords:** [See metadata.txt] (100 chars)
- [ ] **Support URL:** https://yelerty.github.io/stickermaker/support.html
- [ ] **Marketing URL:** https://yelerty.github.io/stickermaker/
- [ ] **Privacy Policy URL:** https://yelerty.github.io/stickermaker/privacy-policy.html

### What's New
- [ ] Version 1.0 release notes written [See metadata.txt]

### Categories
- [ ] **Primary:** Photo & Video
- [ ] **Secondary:** Graphics & Design

---

## Metadata - Korean (ko)

### Required Fields
- [ ] **App Name:** "스티커 메이커 - GIF 제작" (30 chars)
- [ ] **Subtitle:** "쉽고 빠른 스티커 & GIF 제작" (30 chars)
- [ ] **Promotional Text:** [See metadata.txt] (170 chars)
- [ ] **Description:** [See metadata.txt] (4000 chars)
- [ ] **Keywords:** [See metadata.txt] (100 chars)
- [ ] Support URL (same as English)
- [ ] Marketing URL (same as English)
- [ ] Privacy Policy URL (same as English)

### What's New
- [ ] Version 1.0 release notes written [See metadata.txt]

---

## Screenshots

### iPhone 6.7" Display (Required)
- [ ] Screenshot 1: Sticker Maker / Background Removal (1290x2796)
- [ ] Screenshot 2: Photo GIF Creation (1290x2796)
- [ ] Screenshot 3: Video to GIF (1290x2796)
- [ ] Screenshot 4: Background Compositor (1290x2796)
- [ ] Screenshot 5: Image Editor (1290x2796)
- [ ] Screenshot 6 (Optional): Privacy/Features (1290x2796)

### iPad Pro 12.9" (Optional but Recommended)
- [ ] Screenshot 1-5 (2048x2732)

### Screenshot Quality Check
- [ ] All screenshots are correct dimensions
- [ ] High resolution and not blurry
- [ ] UI in correct language for each locale
- [ ] No debug UI or placeholders visible
- [ ] Professional and appealing content
- [ ] Demonstrates key features clearly

---

## App Preview Video (Optional)

- [ ] Video created (15-30 seconds)
- [ ] Correct size (1290x2796 for iPhone 6.7")
- [ ] Shows key features
- [ ] Professional quality
- [ ] No music copyright issues
- [ ] Uploaded to App Store Connect

---

## App Information

### General Information
- [ ] **Copyright:** "2024 Sticker Maker"
- [ ] **Version:** 1.0
- [ ] **SKU:** (Unique identifier, e.g., "stickermaker-001")

### Age Rating
- [ ] Completed Age Rating questionnaire
- [ ] **Expected Rating:** 4+
- [ ] No objectionable content
- [ ] No user-generated content
- [ ] No web browsing features

### Review Information
- [ ] **Contact Information:** Email, phone number
- [ ] **Notes for Reviewer:** [See metadata.txt for suggested text]
- [ ] Demo account info (if needed): N/A - no login required
- [ ] Any special instructions for testing

---

## App Privacy

### Privacy Details (App Store Connect)
- [ ] **Data Collection:** NO
- [ ] **Data Used to Track You:** NO
- [ ] **Data Linked to You:** NO
- [ ] Privacy policy URL provided
- [ ] Privacy practices verified

### Permissions
- [ ] **Photo Library:** Purpose string in Info.plist
  - "NSPhotoLibraryUsageDescription"
  - "NSPhotoLibraryAddUsageDescription"

---

## URLs & Documentation

### GitHub Pages (Verify all are live)
- [ ] Landing page: https://yelerty.github.io/stickermaker/
- [ ] Privacy policy: https://yelerty.github.io/stickermaker/privacy-policy.html
- [ ] Terms of service: https://yelerty.github.io/stickermaker/terms-of-service.html
- [ ] Support page: https://yelerty.github.io/stickermaker/support.html

### Email Setup
- [ ] support@stickermaker.app configured and monitored
- [ ] Auto-responder set up (optional)

---

## Pricing & Availability

### Pricing
- [ ] **Price:** Free
- [ ] No in-app purchases
- [ ] No subscriptions
- [ ] **Business Model:** Free app

### Availability
- [ ] Countries/regions selected (All or specific)
- [ ] Release timing: Automatic or Manual
- [ ] Pre-order option (if desired)

---

## Final Checks

### Code Quality
- [ ] No compiler warnings
- [ ] No crashes in testing
- [ ] Memory leaks checked
- [ ] Performance acceptable
- [ ] Battery usage reasonable

### App Store Guidelines Compliance
- [ ] App follows [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [ ] No private API usage
- [ ] Accurate metadata (no misleading info)
- [ ] App description matches functionality
- [ ] Screenshots show actual app (no mockups)
- [ ] Privacy policy complete and accurate

### Localization
- [ ] English metadata complete
- [ ] Korean metadata complete
- [ ] App UI works in both languages
- [ ] No hardcoded strings remaining

---

## Submission

### Submit for Review
- [ ] All metadata entered
- [ ] All screenshots uploaded
- [ ] Build selected
- [ ] Export compliance answered (usually "No" for this app)
- [ ] Content rights confirmed
- [ ] Advertising identifier usage (No)
- [ ] **Submit button clicked!**

### Post-Submission
- [ ] Confirmation email received
- [ ] Status changed to "Waiting for Review"
- [ ] Monitor App Store Connect for status updates
- [ ] Check email for any communication from Apple

---

## If Rejected

### Common Rejection Reasons
1. **Misleading metadata:** Ensure description matches functionality
2. **Privacy policy issues:** Make sure policy is complete
3. **Crashes:** Test thoroughly before resubmission
4. **Incomplete information:** Fill all required fields
5. **Design issues:** Follow Human Interface Guidelines

### Resubmission Process
- [ ] Read rejection message carefully
- [ ] Fix all issues mentioned
- [ ] Test fixes thoroughly
- [ ] Update metadata if needed
- [ ] Reply to reviewer with explanation (if appropriate)
- [ ] Submit new build (if code changes needed)
- [ ] Or update metadata and resubmit current build

---

## After Approval

### Launch Day
- [ ] App appears on App Store
- [ ] Test download and installation
- [ ] Verify all metadata displays correctly
- [ ] Check screenshots display properly
- [ ] Share on social media
- [ ] Update GitHub README with App Store link
- [ ] Update website with live App Store badge

### Monitoring
- [ ] Monitor reviews and ratings
- [ ] Respond to user feedback
- [ ] Track download numbers
- [ ] Monitor crash reports (if any)
- [ ] Plan for updates based on feedback

---

## Resources

- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Screenshot Specs](https://help.apple.com/app-store-connect/#/devd274dd925)
- [Marketing Resources](https://developer.apple.com/app-store/marketing/guidelines/)

---

## Timeline Estimate

- **Metadata & Screenshots:** 2-4 hours
- **Build & Upload:** 1-2 hours
- **Review Time:** 1-3 days (typically)
- **Total:** Plan for 1 week from start to approval

---

## Notes

- Keep this checklist and update it as you go
- Review time can vary (24 hours to 1 week)
- Be prepared to respond to questions from reviewers
- First submission may take longer than updates
- Weekend submissions may take longer to review

Good luck with your submission! 🚀
