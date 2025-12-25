# Sticker Maker

<div align="center">

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

**사진과 비디오로 멋진 스티커와 GIF를 만드는 iOS 앱**

</div>

## ✨ 주요 기능

### 🎨 스티커 만들기
- **AI 배경 제거**: Vision 프레임워크를 사용한 자동 배경 제거
- **이미지 편집**: 크기 조정, 회전, 필터, 텍스트/이모지 추가
- **투명 PNG 저장**: 배경이 없는 깔끔한 스티커 저장

### 📸 사진 GIF
- **여러 사진 결합**: 최대 10장의 사진으로 GIF 생성
- **프레임 속도 조절**: 0.1~1.0초 사이 조절
- **배경 제거 옵션**: 투명 배경 GIF 생성

### 🎬 비디오 GIF
- **구간 선택**: 비디오의 원하는 부분만 GIF로 변환
- **프레임 수 조절**: 5~30 프레임 선택
- **프레임 딜레이**: 0.03~0.5초 정밀 조절
- **배경 제거**: 각 프레임의 배경 제거 지원

### 📦 스티커팩 관리
- **스티커 컬렉션**: 여러 스티커를 팩으로 관리
- **공유 기능**: 스티커팩을 쉽게 공유

## 🚀 기술 스택

- **SwiftUI**: 모던한 선언형 UI
- **Vision Framework**: AI 기반 배경 제거
- **AVFoundation**: 비디오 처리 및 프레임 추출
- **CoreImage**: 이미지 필터 및 효과
- **Photos Framework**: 사진 라이브러리 접근 및 저장
- **Combine**: 반응형 프로그래밍

## 📱 시스템 요구사항

- iOS 17.0 이상
- Xcode 15.0 이상
- Swift 5.9 이상

## 🎯 UI/UX 특징

### 🌈 디자인 시스템
- **컬러 팔레트**: 그라데이션 기반의 현대적인 컬러
- **타이포그래피**: Rounded 폰트로 친근한 느낌
- **카드 UI**: 깔끔한 카드 기반 레이아웃
- **커스텀 버튼**: Primary/Secondary 버튼 스타일

### 📐 적응형 레이아웃
- **세로/가로 모드**: 양방향 완벽 지원
- **반응형 디자인**: 다양한 화면 크기 대응
- **GeometryReader**: 동적 레이아웃 조정

## 🛠️ 설치 및 실행

```bash
# 저장소 클론
git clone git@github.com:yelerty/stickermaker.git
cd stickermaker

# Xcode로 프로젝트 열기
open stickermaker.xcodeproj

# 또는 명령줄로 빌드
xcodebuild -project stickermaker.xcodeproj -scheme stickermaker -configuration Debug build
```

## 📸 스크린샷

### 스티커 만들기
- 사진 선택 → 자동 배경 제거 → 편집 → 저장

### GIF 만들기
- 사진 또는 비디오 선택 → 옵션 설정 → GIF 생성 → 저장

## 🔒 권한

앱은 다음 권한이 필요합니다:
- **사진 라이브러리 접근**: 사진 및 비디오 불러오기
- **사진 라이브러리 저장**: 생성한 스티커와 GIF 저장

## 📄 Documentation

This repository includes documentation pages for App Store submission:

- **[Privacy Policy](docs/privacy-policy.html)** - Complete privacy policy explaining our zero data collection approach
- **[Terms of Service](docs/terms-of-service.html)** - Terms and conditions for using the app
- **[Support](docs/support.html)** - FAQ, troubleshooting guide, and contact information
- **[Landing Page](docs/index.html)** - Main promotional page for the app

These pages can be hosted via GitHub Pages for App Store review requirements.

## 🤝 기여

기여는 언제나 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이센스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일 참조

## 👨‍💻 개발자

**jihong** - [@yelerty](https://github.com/yelerty)

## 🙏 감사의 말

- Apple의 Vision Framework
- SwiftUI 커뮤니티
- 모든 오픈소스 기여자들

---

<div align="center">

**🤖 Powered by Claude Code**

Made with ❤️ for iOS

</div>
