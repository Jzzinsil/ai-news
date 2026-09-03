#!/bin/zsh
# 새 Mac에서 채널 싱크 재설치 — 레포 clone 후 이 스크립트 한 번만 실행
# 사용법: zsh channel-sync/install.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_SRC="$REPO/channel-sync/com.jzzinsil.ainews-channelsync.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.jzzinsil.ainews-channelsync.plist"

echo "== 의존성 확인 =="
MISSING=()
command -v yt-dlp >/dev/null || MISSING+=("yt-dlp (brew install yt-dlp)")
command -v claude >/dev/null || MISSING+=("claude (https://claude.com/claude-code 설치 후 claude login)")
command -v git    >/dev/null || MISSING+=("git")
if [ ${#MISSING[@]} -gt 0 ]; then
  printf '누락: %s\n' "${MISSING[@]}"
  echo "위 항목 설치 후 다시 실행하세요."
  exit 1
fi
echo "yt-dlp/claude/git OK"

echo "== git push 권한 확인 =="
git -C "$REPO" ls-remote origin >/dev/null || { echo "git 인증 필요 (gh auth login 또는 SSH 키 설정)"; exit 1; }
echo "origin 접근 OK"

echo "== 경로 확인 =="
# sync.sh는 \$HOME/Documents/developments/ai-news 를 가정한다. 다른 경로에 clone했다면 심링크로 맞춘다.
EXPECTED="$HOME/Documents/developments/ai-news"
if [ "$REPO" != "$EXPECTED" ]; then
  mkdir -p "$(dirname "$EXPECTED")"
  [ -e "$EXPECTED" ] || ln -s "$REPO" "$EXPECTED"
  echo "심링크 생성: $EXPECTED -> $REPO"
fi

echo "== launchd 실행 파일 설치 (~/Library — TCC 비보호 경로) =="
# launchd는 TCC 때문에 ~/Documents를 읽지 못한다. 실행 진입점을 ~/Library에 둔다.
mkdir -p "$HOME/Library/ainews-sync" "$HOME/Library/Logs"
cp "$REPO/channel-sync/launchd-run.sh" "$HOME/Library/ainews-sync/run.sh"
chmod +x "$HOME/Library/ainews-sync/run.sh"

echo "== launchd 등록 =="
cp "$PLIST_SRC" "$PLIST_DST"
launchctl bootout "gui/$(id -u)/com.jzzinsil.ainews-channelsync" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
launchctl list | grep ainews-channelsync && echo "등록 완료 — 매일 06:35 KST 실행"

echo ""
echo "설치 끝. 테스트하려면: zsh channel-sync/sync.sh (신규 영상 없으면 'no new videos'가 정상)"
echo "주의: yt-dlp의 실제 바이너리 경로가 /opt/homebrew/bin 이 아니면 sync.sh 상단의 YTDLP/CLAUDE 변수를 수정하세요 (Apple Silicon 기본값)."
