#!/bin/sh
# Patrón común a todos los hooks: líneas de atribución o coautoría de IA.
# Se usa con: awk ($0 !~ re) en strip_ai_attribution y grep -iE en pre-push.
AI_ATTRIBUTION_RE='^[[:space:]]*co-authored-by:.*(claude|anthropic|copilot|openai|codex|chatgpt|gemini|cursor|aider)|generated (with|by) .*(claude|copilot|chatgpt|codex|gemini|cursor|aider)|^[[:space:]]*claude-session:|noreply@anthropic[.]com'

strip_ai_attribution() {
  # $1 = archivo de mensaje. Borra las líneas y las líneas en blanco sobrantes al final.
  awk -v re="$AI_ATTRIBUTION_RE" 'BEGIN{IGNORECASE=1} tolower($0) !~ re' "$1" \
    | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$1.tmp" && mv "$1.tmp" "$1"
}
