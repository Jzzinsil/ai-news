---
description: 오늘 아침 자동화(채널 싱크 + 뉴스 루틴 + 배포)가 잘 돌았는지 점검
---

# /check-daily — 아침 자동화 상태 점검

오늘 아침 자동 파이프라인이 정상 작동했는지 아래를 순서대로 점검하고, 결과를 표로 보고한다. 문제가 발견되면 원인 층위(싱크/루틴/push권한/배포)를 짚고 해법을 제시한다.

## 점검 항목

1. **오늘 날짜(KST)** — `TZ=Asia/Seoul date +%Y-%m-%d`

2. **라이브 사이트** — `curl -s https://dailyaialert.vercel.app` 로:
   - `date: "<오늘>"` 포함 여부 (핵심 판정)
   - 학습 카드의 진행 카운터(`N/전체`)가 어제보다 +2 전진했는지

3. **git 커밋 도착** — `git fetch origin && git log origin/main --oneline -5` 로:
   - `AI Daily — <오늘> edition` 커밋 존재 여부 (클라우드 루틴)
   - `channel-sync:` 커밋 존재 여부 (있으면 신규 영상이 있었던 것 — 없어도 정상일 수 있음)

4. **채널 싱크 로그** — `tail -30 ~/Library/Logs/ainews-channelsync.log`:
   (launchd는 TCC 때문에 ~/Documents를 못 읽으므로 ~/Library/ainews-sync/의 미러 클론에서 돌고, 로그도 ~/Library/Logs에 남는다)
   - 오늘 06:35 전후(또는 Mac이 깨어난 직후) `launchd-run start` / `sync start` 기록이 있는가
   - `no new videos`(정상) / `pushed`(신규 반영) / `PUSH-FAILED` 또는 `captions MISSING`(문제) 구분
   - 기록 자체가 없으면: Mac이 하루 종일 잠들어 있었거나 launchd 미등록 — `launchctl list | grep ainews` 로 등록 확인 (마지막 종료코드가 0이 아니면 문제)

5. **LEARNING.md 진행** — done 개수가 어제보다 2 늘었는지 (`grep -c "| done |" LEARNING.md`)

## 실패 시 원인별 안내

- **사이트가 어제 날짜** + `AI Daily` 커밋 없음 → 클라우드 루틴 실패. https://claude.ai/code/routines 의 "AI Daily — 아침 에디션 갱신" 실행 로그에서 `PUSH-FAILED:` 확인. 루틴에는 레포 전용 deploy key 폴백(push 방법 5b/5c)이 심어져 있으므로 인증 실패 시 GitHub 레포 Settings → Deploy keys에 `ainews-cloud-routine-deploy` 키가 살아있는지(write 권한) 확인. 삭제됐다면 새 키를 만들어 루틴 프롬프트를 갱신한다.
- **커밋은 있는데 사이트가 그대로** → Vercel 배포 문제. `vercel ls` 로 최근 배포 상태 확인.
- **learn이 어제와 동일한데 뉴스는 갱신됨** → 루틴이 LEARNING.md 커밋을 누락했는지 `git show origin/main --stat` 확인.
- **싱크 로그에 `PUSH-FAILED`** → 로컬 git 인증 확인(`git -C . ls-remote origin`).
