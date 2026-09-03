#!/bin/zsh
# 아침 자동화 오케스트레이터 — launchd 래퍼(run.sh)가 미러 클론 준비 후 이 스크립트를 실행한다.
# 1) 채널 싱크(sync.sh) → 2) 오늘자 에디션 갱신(edition-run.sh) 순차 실행.
set -uo pipefail
REPO="${AINEWS_REPO:-$HOME/Documents/developments/ai-news}"
LOG="${AINEWS_LOG:-$REPO/channel-sync/sync.log}"
exec >>"$LOG" 2>&1

/bin/zsh "$REPO/channel-sync/sync.sh"
echo "daily-run: sync exit=$?"

/bin/zsh "$REPO/channel-sync/edition-run.sh"
echo "daily-run: edition exit=$?"
