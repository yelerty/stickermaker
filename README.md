# 집단소송 정보센터

대한민국에서 참여 가능한 모든 집단소송 정보를 제공하는 정적 웹사이트입니다.

## 기능

- 📋 집단소송 목록 및 상세 정보 제공
- 🔍 검색 및 필터링 기능
- 📱 반응형 디자인 (모바일 최적화)
- 💰 Google AdSense 광고 연동
- ⚡ Vercel 무료 호스팅

## 기술 스택

- HTML5
- CSS3
- Vanilla JavaScript
- Vercel (호스팅)
- Google AdSense

## 배포 방법

### Vercel 배포

1. Vercel 계정 생성 (https://vercel.com)
2. GitHub 저장소 연동
3. 프로젝트 import
4. 자동 배포 완료!

또는 Vercel CLI 사용:

```bash
npm i -g vercel
vercel --prod
```

## Google AdSense 설정

1. Google AdSense 계정 생성 (https://www.google.com/adsense)
2. 사이트 추가 및 승인 대기
3. `index.html`에서 다음 부분을 본인의 AdSense 코드로 교체:
   - `ca-pub-XXXXXXXXXXXXXXXX` → 본인의 게시자 ID
   - `data-ad-slot="XXXXXXXXXX"` → 광고 단위 ID

### AdSense 코드 위치

```html
<!-- 1. Head 태그 내 -->
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-XXXXXXXXXXXXXXXX"
     crossorigin="anonymous"></script>

<!-- 2. 광고 단위 (3군데) -->
<ins class="adsbygoogle"
     data-ad-client="ca-pub-XXXXXXXXXXXXXXXX"
     data-ad-slot="XXXXXXXXXX">
</ins>
```

## 소송 데이터 업데이트

`script.js` 파일의 `lawsuits` 배열을 수정하여 소송 정보를 추가/수정할 수 있습니다:

```javascript
{
    id: 1,
    title: "소송 제목",
    company: "기업명",
    status: "진행중", // 진행중, 모집중, 완료
    description: "소송 설명",
    date: "2024.01",
    link: "https://example.com"
}
```

## 라이선스

MIT License

## 주의사항

- 본 사이트는 정보 제공 목적으로만 운영됩니다
- 법률 자문을 제공하지 않습니다
- 실제 소송 참여 전 법률 전문가와 상담하시기 바랍니다

## 문의

이슈 및 문의사항은 GitHub Issues를 통해 제출해주세요.
