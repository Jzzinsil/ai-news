#!/bin/zsh
# AI Daily 에디션 무인 갱신 (로컬) — 클라우드 루틴이 push 권한이 없어 실패할 때의 주 경로.
# origin에 오늘자 에디션 커밋이 이미 있으면 건너뛰므로, 클라우드 루틴이 살아나도 충돌하지 않는다.
set -uo pipefail
REPO="${AINEWS_REPO:-$HOME/Documents/developments/ai-news}"
LOG="${AINEWS_LOG:-$REPO/channel-sync/sync.log}"
CLAUDE="/opt/homebrew/bin/claude"

cd "$REPO" || exit 1
exec >>"$LOG" 2>&1
echo "=== $(date '+%F %T') edition start ==="

TODAY=$(TZ=Asia/Seoul date +%Y-%m-%d)
git fetch origin
if git log origin/main --oneline -20 | grep -q "AI Daily — $TODAY edition"; then
  echo "edition already published for $TODAY — skip"
  exit 0
fi
git pull --rebase origin main || { git rebase --abort 2>/dev/null; echo "EDITION-FAILED: pull conflict"; exit 1; }

PROMPT="AI Daily 무인 에디션 갱신. 이 레포의 .claude/commands/update-edition.md 를 읽고 '자동 루틴(무인) 모드' 절차를 정확히 수행하라:
1. TZ=Asia/Seoul date +%Y-%m-%d 로 오늘 날짜 확정 → EDITION.date.
2. WebSearch/WebFetch로 최근 24~48시간 AI 뉴스 리서치(5개 토픽 커버, 1차 출처 필수).
3. index.html의 EDITION 객체 통째 교체 + LEARNING.md의 todo 상위 2개를 learn[]으로 작성하고 done 처리.
4. 문서의 node 파싱 검증 스니펫과 URL 실접근 검증을 반드시 통과시켜라. 실패하면 커밋하지 말고 원인을 출력하고 중단.
5. git add index.html LEARNING.md → 커밋 메시지 'AI Daily — $TODAY edition' → git push origin main. non-fast-forward면 git pull --rebase 후 1회 재시도. push 후 git ls-remote origin refs/heads/main 의 SHA가 git rev-parse HEAD와 일치하는지 확인하고, 불일치하면 'PUSH-FAILED:'로 시작하는 줄과 전체 에러를 출력하라.
index.html의 EDITION 외 영역과 LEARNING.md 외 파일은 절대 수정하지 마라. 소셜 발언은 전부 오늘자 실제 발언으로, URL은 실존 원문만."

"$CLAUDE" -p "$PROMPT" --allowedTools "WebSearch,WebFetch,Read,Edit,Bash" --max-turns 100 || {
  echo "EDITION-FAILED: claude run error"
  exit 1
}

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git ls-remote origin refs/heads/main | cut -f1)
if [ "$LOCAL" = "$REMOTE" ] && git log -1 --oneline | grep -q "AI Daily — $TODAY edition"; then
  echo "edition pushed $LOCAL"
  echo "=== edition done ==="
else
  echo "PUSH-FAILED: local=$LOCAL remote=$REMOTE head=$(git log -1 --oneline)"
  exit 1
fi
