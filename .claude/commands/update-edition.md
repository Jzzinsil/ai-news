---
description: 오늘자 AI 뉴스를 리서치·요약해 index.html의 EDITION을 갱신하고 배포
---

# /update-edition — AI Daily 오늘자 에디션 갱신

`index.html`의 `EDITION` 객체를 **오늘 날짜(KST) 기준** 최신 AI 뉴스로 교체한다.
사이트는 정적 페이지이며 `EDITION` 블록(`index.html` 안 `const EDITION = { ... };`)만 바꾸면 화면 전체가 갱신된다.
날짜 라벨·요일은 `EDITION.date`에서 자동 계산되므로 `date` 문자열만 정확히 넣으면 된다.

## 절차

1. **오늘 날짜 확정** — 세션 컨텍스트의 `currentDate`(KST 기준)를 사용한다. `date: "YYYY-MM-DD"`.

2. **리서치** — WebSearch/WebFetch로 **최근 24~48시간** 내 AI 관련 소식을 폭넓게 수집한다. 5개 토픽을 고루 커버:
   - `physical-ai` — 피지컬 AI, 휴머노이드·로봇 실배치, 임바디드 AI
   - `ai` — 프론티어 모델/랩(OpenAI·Anthropic·Google DeepMind·xAI 등), 제품·정책·인물
   - `robotics` — 로보틱스 하드웨어/산업 배치
   - `security` — AI 보안, 침해·취약점·악용 사례
   - `chips` — AI 반도체/인프라(엔비디아·AMD·TSMC·데이터센터)
   각 항목은 **1차 출처(원문 기사 URL)** 를 확보한다. 출처 없는 소문·미확인 주장은 제외한다.

3. **요약 작성 (하우스 톤)** — 기존 EDITION 항목들의 문체를 그대로 따른다:
   - 한국어, 간결하고 밀도 높은 정보형. 과장·감탄사·이모지 금지.
   - `title`: 핵심을 담은 한 줄. `summary`: 2~3문장, 숫자·고유명사 구체적으로.
   - 번역투 최소화, 원문의 사실만 옮기고 추측 덧붙이지 않기.

4. **EDITION 교체** — 아래 스키마에 맞춰 세 배열을 새로 채운다. Edit로 `const EDITION = {` 부터 닫는 `};` 까지 통째로 교체한다.

   ```
   date: "YYYY-MM-DD"
   news[]:    { source, topics:[…], title, summary, url }
   social[]:  { name, handle, initials, topics:[…], quote, context, url }   // 업계 인물의 실제 X/공개 발언. quote는 원문(영어면 영어) 그대로, context는 한국어 해설. **매일 전부 새 발언으로 교체한다 — 어제 항목 재탕 금지.** 그날 뉴스에 대한 실제 반응/발언을 출처(트윗 URL 등) 확인해 넣는다.
   company[]: { company, logo, type, topics:[…], title, summary, url }      // logo는 1~3자 약자, type은 "빅테크 · 반도체" 형식
   ```
   - `topics` 값은 반드시 5종(`physical-ai|ai|robotics|security|chips`) 중에서만.
   - 분량 가이드(기존 기준): news 8~10, social 4~6, company 4~6. 좋은 소재가 부족하면 억지로 채우지 말 것.

5. **검토 제시** — 교체 후, 새 항목 목록(제목+출처)을 사용자에게 요약해 보여주고 **톤/정확도 확인을 요청**한다. 사용자가 수정 요청하면 반영한다.

6. **배포** — 사용자가 승인하면:
   ```
   git add index.html
   git commit -m "AI Daily — <YYYY-MM-DD> edition"
   git push
   ```
   Vercel이 git 연동으로 자동 배포한다. **승인 전에는 push하지 않는다.**

## 주의
- `index.html`의 EDITION 외 마크업/스크립트/CSS는 건드리지 않는다.
- URL은 실제 접근 가능한 원문이어야 한다(가짜 링크 금지). 확인 안 되면 그 항목을 뺀다.
- 같은 날 재실행 시 기존 오늘자 내용을 덮어쓴다.

## 자동 루틴(무인) 모드
클라우드 예약 루틴이 사람 없이 실행할 때는 위 절차를 그대로 따르되 **5번 '검토 제시'를 건너뛰고**, 4번 EDITION 교체 → node 검증 통과 후 곧바로 6번 커밋·push를 수행한다.
- 오늘 날짜: `TZ=Asia/Seoul date +%Y-%m-%d`
- 검증(교체 후 필수): node로 EDITION 객체가 정상 파싱되는지, topics가 5종 이내인지, 모든 항목에 http(s) URL이 있는지 확인. 실패하면 **커밋하지 말고** 무엇이 틀렸는지 출력한다.
- 커밋 메시지: `AI Daily — <오늘 KST 날짜> edition`, 이후 `origin main`으로 push (→ Vercel 자동 배포).
- 소셜은 매일 전부 그날 뉴스에 대한 실제 발언으로 교체(어제 재탕 금지).
