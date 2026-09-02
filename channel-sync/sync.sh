#!/bin/zsh
# AI Daily — 유튜브 채널 싱크 (매일 아침 launchd 실행)
# 신규 영상 감지 → 자막(cc) 추출 → headless Claude로 증류 → LEARNING.md 갱신 → push
set -uo pipefail

REPO="$HOME/Documents/developments/ai-news"
YTDLP="/opt/homebrew/bin/yt-dlp"
CLAUDE="/opt/homebrew/bin/claude"
KNOWN="$REPO/channel-sync/known_ids.txt"
LOG="$REPO/channel-sync/sync.log"
CHANNELS=(
  "https://www.youtube.com/@sudoremove/videos"
  "https://www.youtube.com/@engiuniverse/videos"
)

cd "$REPO" || exit 1
exec >>"$LOG" 2>&1
echo "=== $(date '+%F %T') sync start ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1) 신규 영상 감지 (각 채널 최신 15개만 훑으면 충분)
: > "$TMP/new.txt"
for ch in "${CHANNELS[@]}"; do
  "$YTDLP" --flat-playlist --playlist-end 15 --print "%(id)s|%(title)s" "$ch" 2>/dev/null |
  while IFS='|' read -r id title; do
    [ -n "$id" ] || continue
    grep -q "^${id}$" "$KNOWN" || printf '%s|%s|%s\n' "$id" "$title" "$ch" >> "$TMP/new.txt"
  done
done

if [ ! -s "$TMP/new.txt" ]; then
  echo "no new videos"
  exit 0
fi
echo "new videos:"; cat "$TMP/new.txt"

# 2) 자막(cc) 추출 → 플레인 텍스트
while IFS='|' read -r id title ch; do
  "$YTDLP" --skip-download --write-auto-subs --write-subs --sub-langs "ko,en" \
    --sub-format vtt -o "$TMP/$id" "https://www.youtube.com/watch?v=$id" >/dev/null 2>&1
  vtt=$(ls "$TMP/$id".*.vtt 2>/dev/null | head -1)
  if [ -n "$vtt" ]; then
    sed -e '/^WEBVTT/d' -e '/^Kind:/d' -e '/^Language:/d' -e '/-->/d' \
        -e 's/<[^>]*>//g' -e '/^[[:space:]]*$/d' "$vtt" | awk '!seen[$0]++' > "$TMP/$id.txt"
    echo "captions ok: $id ($(wc -l < "$TMP/$id.txt") lines)"
  else
    echo "captions MISSING: $id — 제목만으로 진행"
    printf '(자막 없음. 제목: %s)\n' "$title" > "$TMP/$id.txt"
  fi
done < "$TMP/new.txt"

# 3) headless Claude로 증류 → LEARNING.md 갱신
PROMPT="너는 AI Daily의 커리큘럼 관리자다. $TMP/new.txt 에 신규 유튜브 영상 목록(id|제목|채널)이 있고, 각 영상의 자막 텍스트가 $TMP/<id>.txt 에 있다.

작업: 각 영상에 대해 자막을 읽고 판단하라.
- 피지컬 AI/로보틱스 학습과 관련 있으면: LEARNING.md 의 'Phase 6 — 채널 신규분' 표에 새 행을 추가한다. 번호는 기존 마지막 번호+1 이어서, 형식은 기존 행과 동일(| # | 용어/주제 | 분류 | 한 줄 정의 | 왜 중요한가(콘텐츠 앵글) | todo |). 한 줄 정의에 출처 채널명 표기, 자막 속 구체 수치·주장 포함. 분류는 기존 커리큘럼의 분류 체계를 따른다. 이미 커리큘럼에 같은 주제가 있으면 중복 추가하지 말고 기존 행의 정의를 보강할지만 판단한다.
- 무관하면(일반 AI 뉴스, 결제/비즈니스 등): 표에 넣지 말고 Phase 6 아래의 '미반영(주제 무관)' 인용 블록에 제목을 추가한다.
- 채널 싱크 로그의 '마지막 싱크' 날짜를 오늘로 갱신한다.
LEARNING.md 외 다른 파일은 절대 수정하지 마라. 완료 후 무엇을 어떻게 처리했는지 한 줄씩 출력하라."

"$CLAUDE" -p "$PROMPT" --allowedTools "Read,Edit" --max-turns 30 || {
  echo "claude distill FAILED — known_ids 갱신 없이 종료(다음 실행에서 재시도)"
  exit 1
}

# 4) known_ids 갱신 + 커밋·push
cut -d'|' -f1 "$TMP/new.txt" >> "$KNOWN"
sort -u "$KNOWN" -o "$KNOWN"

git add LEARNING.md channel-sync/known_ids.txt
if git diff --cached --quiet; then
  echo "nothing to commit"
  exit 0
fi
TITLES=$(cut -d'|' -f2 "$TMP/new.txt" | head -3 | tr '\n' ';')
git commit -m "channel-sync: ${TITLES}" -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
git pull --rebase origin main || { git rebase --abort 2>/dev/null; echo "PUSH-FAILED: rebase conflict"; exit 1; }
git push origin main || { echo "PUSH-FAILED: push error"; exit 1; }
echo "pushed $(git rev-parse --short HEAD)"
echo "=== sync done ==="
