#!/usr/bin/env bash
# Claude Code Game Studios: Technica Edition — Status Line
# Receives JSON on stdin, outputs a single-line status.
#
# Segments: ctx% | model | production stage [| Epic > Feature > Task]

input=$(cat)

# DEBUG: dump raw JSON to inspect field names
echo "$input" > /tmp/statusline-debug.json

# --- Parse JSON (jq → python → grep fallback) ---
# Find a working Python (skips Windows Store stubs that fail silently)
_py=""
for _candidate in python3 python; do
  if command -v "$_candidate" &>/dev/null && "$_candidate" -c "" 2>/dev/null; then
    _py="$_candidate"; break
  fi
done
if command -v jq &>/dev/null; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  rl_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
  wl_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
  rl_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  wl_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
elif [ -n "$_py" ]; then
  _parse=$(echo "$input" | "$_py" -c "
import sys, json
d = json.load(sys.stdin)
rl = d.get('rate_limits', {})
fh = rl.get('five_hour', {})
sd = rl.get('seven_day', {})
cw = d.get('context_window', {})
ws = d.get('workspace', {})
print(d.get('model', {}).get('display_name', 'Unknown'))
print(cw.get('used_percentage', ''))
print(fh.get('used_percentage', ''))
print(sd.get('used_percentage', ''))
print(fh.get('resets_at', ''))
print(sd.get('resets_at', ''))
print(ws.get('current_dir', d.get('cwd', '')))
" 2>/dev/null)
  model=$(echo "$_parse" | sed -n '1p')
  used_pct=$(echo "$_parse" | sed -n '2p')
  rl_pct=$(echo "$_parse" | sed -n '3p')
  wl_pct=$(echo "$_parse" | sed -n '4p')
  rl_reset=$(echo "$_parse" | sed -n '5p')
  wl_reset=$(echo "$_parse" | sed -n '6p')
  cwd=$(echo "$_parse" | sed -n '7p')
  [ -z "$model" ] && model="Unknown"
else
  model=$(echo "$input" | grep -oE '"display_name"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  used_pct=$(echo "$input" | grep -oE '"used_percentage"\s*:\s*[0-9]+' | head -1 | sed 's/.*: *//')
  rl_pct=$(echo "$input" | grep -oE '"five_hour"\s*:\s*\{[^}]+\}' | grep -oE '"used_percentage"\s*:\s*[0-9]+' | grep -oE '[0-9]+$')
  wl_pct=$(echo "$input" | grep -oE '"seven_day"\s*:\s*\{[^}]+\}' | grep -oE '"used_percentage"\s*:\s*[0-9]+' | grep -oE '[0-9]+$')
  rl_reset=$(echo "$input" | grep -oE '"five_hour"\s*:\s*\{[^}]+\}' | grep -oE '"resets_at"\s*:\s*([0-9]+|"[^"]+")' | sed 's/.*:\s*//;s/"//g')
  wl_reset=$(echo "$input" | grep -oE '"seven_day"\s*:\s*\{[^}]+\}' | grep -oE '"resets_at"\s*:\s*([0-9]+|"[^"]+")' | sed 's/.*:\s*//;s/"//g')
  cwd=$(echo "$input" | grep -oE '"current_dir"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$model" ] && model="Unknown"
fi

# Normalize Windows paths
cwd=$(echo "$cwd" | sed 's|\\|/|g')
[ -z "$cwd" ] && cwd="."

# --- Colored percentage label (50-80% yellow, >80% red) ---
pct_label() {
  local prefix="$1" val="$2"
  if [ -z "$val" ]; then printf "%s: --" "$prefix"; return; fi
  if [ "$val" -ge 80 ] 2>/dev/null; then
    printf "\033[1;31m%s: %s%%\033[0m" "$prefix" "$val"
  elif [ "$val" -ge 50 ] 2>/dev/null; then
    printf "\033[33m%s: %s%%\033[0m" "$prefix" "$val"
  else
    printf "\033[1;32m%s: %s%%\033[0m" "$prefix" "$val"
  fi
}

ctx_label=$(pct_label "ctx" "$used_pct")
rl_label=$(pct_label "5h" "$rl_pct")
wl_label=$(pct_label "7d" "$wl_pct")

# --- Relative reset time ---
relative_reset() {
  local reset_at="$1"
  if [ -z "$reset_at" ]; then printf '%s' '--'; return; fi
  local reset_epoch now_epoch diff

  # Epoch integer: use directly (avoids OS-specific date syntax)
  # ISO string: GNU date (Linux/Windows), BSD date (macOS), Python fallback
  if echo "$reset_at" | grep -qE '^[0-9]+$'; then
    reset_epoch=$reset_at
  else
    reset_epoch=$(date -d "$reset_at" +%s 2>/dev/null) \
      || reset_epoch=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$reset_at" +%s 2>/dev/null) \
      || reset_epoch=$(python3 -c "import datetime; print(int(datetime.datetime.fromisoformat('${reset_at%Z}+00:00').timestamp()))" 2>/dev/null) \
      || reset_epoch=$(python -c "import datetime; print(int(datetime.datetime.fromisoformat('${reset_at%Z}+00:00').timestamp()))" 2>/dev/null) \
      || { printf '%s' '--'; return; }
  fi

  now_epoch=$(date +%s 2>/dev/null) || { printf "--"; return; }
  diff=$((reset_epoch - now_epoch))
  if [ "$diff" -le 0 ]; then printf "now"; return; fi
  local hours=$(( diff / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$hours" -ge 24 ]; then
    printf "%dd %dh" $(( hours / 24 )) $(( hours % 24 ))
  elif [ "$hours" -ge 1 ]; then
    printf "%dh %dm" "$hours" "$mins"
  else
    printf "%dm" "$mins"
  fi
}

rl_reset_label=$(relative_reset "$rl_reset")
wl_reset_label=$(relative_reset "$wl_reset")

# --- Production stage ---
# Priority 1: Explicit stage from stage.txt
stage_file="$cwd/production/stage.txt"
stage=""
if [ -f "$stage_file" ]; then
  stage=$(head -1 "$stage_file" | tr -d '\r\n')
fi

# Priority 2: Auto-detect from artifacts
if [ -z "$stage" ]; then
  concept_file="$cwd/design/gdd/game-concept.md"
  systems_file="$cwd/design/gdd/systems-index.md"
  tech_prefs="$cwd/.claude/docs/technical-preferences.md"

  has_concept=false
  has_systems=false
  engine_configured=false
  src_count=0

  [ -f "$concept_file" ] && has_concept=true
  [ -f "$systems_file" ] && has_systems=true

  # Check if engine is configured (not placeholder)
  if [ -f "$tech_prefs" ]; then
    engine_line=$(grep -m1 '^\*\*Engine\*\*:' "$tech_prefs" 2>/dev/null || true)
    if [ -n "$engine_line" ] && ! echo "$engine_line" | grep -q "TO BE CONFIGURED"; then
      engine_configured=true
    fi
  fi

  # Count source files (language-agnostic)
  if [ -d "$cwd/src" ]; then
    src_count=$(find "$cwd/src" -type f \( -name "*.gd" -o -name "*.cs" -o -name "*.cpp" -o -name "*.h" -o -name "*.py" -o -name "*.rs" -o -name "*.lua" -o -name "*.tscn" -o -name "*.tres" \) 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Check for ADRs (signals Pre-Production phase)
  has_adrs=false
  if ls "$cwd/docs/architecture/"adr-*.md 2>/dev/null | head -1 | grep -q .; then
    has_adrs=true
  fi

  # Determine stage (check from most-advanced backward)
  if [ "$src_count" -ge 10 ] 2>/dev/null; then
    stage="Production"
  elif [ "$has_adrs" = true ]; then
    stage="Pre-Production"
  elif [ "$engine_configured" = true ]; then
    stage="Technical Setup"
  elif [ "$has_systems" = true ]; then
    stage="Systems Design"
  elif [ "$has_concept" = true ]; then
    stage="Concept"
  else
    stage="Concept"
  fi
fi

# --- Epic/Feature/Task breadcrumb (Production+ only) ---
breadcrumb=""
if [ "$stage" = "Production" ] || [ "$stage" = "Polish" ] || [ "$stage" = "Release" ]; then
  state_file="$cwd/production/session-state/active.md"
  if [ -f "$state_file" ]; then
    # Parse structured STATUS block
    in_block=false
    epic="" feature="" task=""
    while IFS= read -r line; do
      case "$line" in
        *"<!-- STATUS -->"*) in_block=true; continue ;;
        *"<!-- /STATUS -->"*) break ;;
      esac
      if [ "$in_block" = true ]; then
        case "$line" in
          Epic:*) epic=$(echo "$line" | sed 's/^Epic: *//') ;;
          Feature:*) feature=$(echo "$line" | sed 's/^Feature: *//') ;;
          Task:*) task=$(echo "$line" | sed 's/^Task: *//') ;;
        esac
      fi
    done < "$state_file"

    # Build breadcrumb from whatever is set
    parts=""
    [ -n "$epic" ] && parts="$epic"
    [ -n "$feature" ] && parts="${parts:+$parts > }$feature"
    [ -n "$task" ] && parts="${parts:+$parts > }$task"
    [ -n "$parts" ] && breadcrumb=" | $parts"
  fi
fi

# --- Assemble ---
printf "%s\n%s" \
  "${model} | ${stage}${breadcrumb}" \
  "${ctx_label} | ${rl_label} ${rl_reset_label} | ${wl_label} ${wl_reset_label}"
