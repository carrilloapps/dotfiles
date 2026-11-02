#!/bin/sh
# Common pattern across all hooks: AI co-authorship or attribution lines.
# Used with: awk ($0 !~ re) in strip_ai_attribution and grep -iE in pre-push.
AI_ATTRIBUTION_RE='^[[:space:]]*co-authored-by:.*(claude|anthropic|copilot|openai|codex|chatgpt|gemini|cursor|aider)|generated (with|by) .*(claude|copilot|chatgpt|codex|gemini|cursor|aider)|^[[:space:]]*claude-session:|noreply@anthropic[.]com'

strip_ai_attribution() {
  # $1 = commit message file. Strips matching lines and trailing blank lines.
  awk -v re="$AI_ATTRIBUTION_RE" 'BEGIN{IGNORECASE=1} tolower($0) !~ re' "$1" \
    | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$1.tmp" && mv "$1.tmp" "$1"
}
