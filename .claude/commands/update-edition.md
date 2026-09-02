---
description: 오늘자 AI 뉴스를 리서치·요약해 index.html의 EDITION을 갱신하고 배포
---

# /update-edition — AI Daily 오늘자 에디션 갱신

`index.html`의 `EDITION` 객체를 **오늘 날짜(KST) 기준** 최신 AI 뉴스로 교체한다.
사이트는 정적 페이지이며 `EDITION` 블록(`index.html` 안 `const EDITION = { ... };`)만 바꾸면 화면 전체가 갱신된다.
날짜 라벨·요일은 `EDITION.date`에서 자동 계산되므로 `date` 문자열만 정확히 넣으면 된다.

## 절차

1. **오늘 날짜 확정** — `TZ=Asia/Seoul date +%Y-%m-%d` 명령으로 구한다(세션 컨텍스트 날짜는 UTC일 수 있으므로 신뢰하지 않는다). `date: "YYYY-MM-DD"`.

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
   learn[]:   { term, full?, category, topics:[…], summary, angle, url }    // '오늘의 학습' 탭 — 아래 규칙 참조
   ```
   - `topics` 값은 반드시 5종(`physical-ai|ai|robotics|security|chips`) 중에서만.
   - 분량 가이드(기존 기준): news 8~10, social 4~6, company 4~6, learn 2. 좋은 소재가 부족하면 억지로 채우지 말 것.

4-1. **learn[] (오늘의 학습) 규칙** — 사용자는 로보틱스/피지컬 AI 스타트업 rlwrld로 이직 예정인 비로보틱스 출신(테슬라→AI SW). 매일 이 분야 핵심 개념을 2개씩 익혀 X/LinkedIn 엔지니어 대상 콘텐츠를 만들 수 있게 하는 섹션이다.
   - 레포 루트의 **`LEARNING.md`** 커리큘럼에서 `status`가 `todo`인 항목을 **위에서부터 2개** 골라 작성하고, 그 두 항목의 status를 `done`으로 바꿔 **LEARNING.md도 함께 커밋**한다.
   - `term`: 용어(예: "VLA"), `full`: 풀네임/원어(예: "Vision-Language-Action"), `category`: **LEARNING.md 해당 행의 분류 값을 그대로 쓰고 뒤에 진행 카운터를 붙인다** — 형식 `"<분류> · <항목번호>/<전체수>"` (예: `"핵심개념 · 3/58"` — 전체수는 LEARNING.md 항목 수).
   - `summary`: 4~6문장. 소프트웨어 엔지니어 출신이 바로 이해할 수 있게 비유·대비(예: "LLM의 ~에 해당") 활용. LEARNING.md의 정의를 기반으로 하되 최신 맥락(그날 뉴스와 연결되면 금상첨화)을 보강.
   - `angle`: X/LinkedIn 콘텐츠로 쓸 때의 훅 1~2문장(예: 반직관적 사실, 숫자, 논쟁 지점).
   - `url`: 해당 개념의 대표 1차 자료(공식 문서/논문/프로젝트 페이지). 실존 URL만.
   - `topics`: 보통 `physical-ai` 또는 `robotics`, 칩 관련이면 `chips`.
   - LEARNING.md의 todo가 소진되면 심화 항목을 커리큘럼에 추가한 뒤 진행한다.

5. **검토 제시** — 교체 후, 새 항목 목록(제목+출처)을 사용자에게 요약해 보여주고 **톤/정확도 확인을 요청**한다. 사용자가 수정 요청하면 반영한다.

6. **배포** — 사용자가 승인하면:
   ```
   git add index.html LEARNING.md
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
- 검증(교체 후 필수):
  - node 파싱 검증은 아래 스니펫을 그대로 사용한다 (실패 시 커밋 금지):
    ```js
    // node -e '<이 코드>'
    const s=require("fs").readFileSync("index.html","utf8");
    [...s.matchAll(/<script>([\s\S]*?)<\/script>/g)].forEach(m=>new Function(m[1]));
    const a=s.indexOf("const EDITION = {"),b=s.indexOf("const TOPIC_LABEL");
    const E=new Function(s.slice(a,b).replace("const EDITION = ","return ")+"\nreturn EDITION;")();
    const ok=new Set(["physical-ai","ai","robotics","security","chips"]);
    for(const k of ["news","social","company","learn"]) for(const it of E[k]){
      if(!it.topics.every(t=>ok.has(t))) throw "bad topic in "+k;
      if(!/^https?:\/\//.test(it.url)) throw "bad url in "+k;
    }
    console.log("OK",E.date,E.news.length,E.social.length,E.company.length,E.learn.length);
    ```
  - **URL 실접근 검증**: 새로 넣은 URL 전부를 `curl -s -o /dev/null -w '%{http_code}' -L --max-time 12`로 확인. 2xx/3xx가 아니면: news/social/company는 항목 제외 또는 교체(단, x.com과 주요 언론사의 봇차단 403은 원문을 WebFetch로 이미 읽었다면 유지 허용), **learn은 제외 불가 — URL만 다른 1차 자료로 교체**한다(매일 2개 불변식 유지).
  - 어느 검증이든 실패하면 **커밋하지 말고** 무엇이 틀렸는지 출력한다.
- 커밋: `git add index.html LEARNING.md` → 메시지 `AI Daily — <오늘 KST 날짜> edition` → `git push origin main` (→ Vercel 자동 배포).
- **push 확인·재시도**: push가 non-fast-forward로 거부되면 `git pull --rebase origin main` 후 1회 재시도. rebase 충돌이 나면 `git rebase --abort` 후 `PUSH-FAILED:`로 중단한다. push 후 `git ls-remote origin refs/heads/main`의 SHA가 로컬 `git rev-parse HEAD`와 일치해야 성공이다. 불일치하거나 인증 오류면 `PUSH-FAILED:`로 시작하는 줄과 전체 에러를 출력하고 중단한다.
- 소셜은 매일 전부 그날 뉴스에 대한 실제 발언으로 교체(어제 재탕 금지).
- learn[]도 매일 2개 새로 진행(4-1 규칙): LEARNING.md에서 todo 상위 2개 → 작성 → status를 done으로 갱신.
