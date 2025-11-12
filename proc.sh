#!/usr/bin/env bash
set -euo pipefail

# 依你的實際目錄改
IN="human_eval_play"       # 來源根，例如 AAA
OUT="human_eval_play_v2"   # 輸出根，例如 AAA_v2
CRF=22
PRESET="slow"
HEIGHT=360

# 先把 IN/OUT 正規化（去掉多餘的 ./ 和尾端 /）
IN="${IN#./}"; IN="${IN%/}"
OUT="${OUT#./}"; OUT="${OUT%/}"

# 遞迴處理 mp4
find "$IN" -type f -iname "*.mp4" -print0 | while IFS= read -r -d '' f; do
  # 確認輸入檔存在
  [[ -f "$f" ]] || { echo "Skip (not found): $f"; continue; }

  # 取得相對於 IN 的路徑（最穩）
  if rel=$(realpath --relative-to="$IN" "$f" 2>/dev/null); then
    :
  else
    # 萬一系統沒有 --relative-to，退回字串剝前綴（也做 ./ 正規化）
    f_clean="${f#./}"
    rel="${f_clean#"$IN"/}"
  fi

  out="$OUT/$rel"
  mkdir -p "$(dirname "$out")"

  # 若輸出已存在就跳過（要覆蓋就拿掉這段）
  if [[ -f "$out" ]]; then
    echo "Skip (exists): $out"
    continue
  fi

  echo "Transcoding (audio COPY): $f -> $out"
  ffmpeg -hide_banner -loglevel error -stats \
    -i "$f" \
    -map 0:v:0 -map 0:a? \
    -vf "scale=-2:${HEIGHT}:flags=lanczos,setsar=1" \
    -c:v libx264 -crf "$CRF" -preset "$PRESET" -pix_fmt yuv420p \
    -c:a copy \
    -movflags +faststart \
    "$out"
done
