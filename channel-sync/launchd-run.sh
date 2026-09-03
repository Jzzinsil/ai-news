#!/bin/zsh
# launchd 진입점 — macOS TCC가 백그라운드 잡의 ~/Documents 접근을 막으므로
# ~/Library/ainews-sync/ 아래 미러 클론에서 sync.sh를 실행한다 (결과는 GitHub push로 반영).
# 설치 위치: $HOME/Library/ainews-sync/run.sh  (install.sh가 복사)
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

MIRROR="$HOME/Library/ainews-sync/ai-news"
export AINEWS_LOG="$HOME/Library/Logs/ainews-channelsync.log"

echo "=== $(date '+%F %T') launchd-run start ==="
if [ ! -d "$MIRROR/.git" ]; then
  mkdir -p "$(dirname "$MIRROR")"
  git clone https://github.com/Jzzinsil/ai-news.git "$MIRROR"
fi
cd "$MIRROR"
git fetch origin
git reset --hard origin/main

AINEWS_REPO="$MIRROR" exec /bin/zsh "$MIRROR/channel-sync/sync.sh"
