#!/usr/bin/env python3
"""PreToolUse (Bash): rechaza comandos que meterían atribución o coautoría de IA
en commits, PRs, issues, releases o tags (git commit, gh pr/issue/release...).

Revisa el texto del comando y, si usa -F/--file/--body-file/--notes-file, el
contenido de ese archivo. Complementa al hook global de git en ~/.config/git/hooks.
"""
import json
import re
import shlex
import sys
from pathlib import Path

ATTRIBUTION = re.compile(
    r"co-authored-by:.*(claude|anthropic|copilot|openai|codex|chatgpt|gemini|cursor|aider)"
    r"|generated (with|by) .*(claude|copilot|chatgpt|codex|gemini|cursor|aider)"
    r"|claude-session:"
    r"|noreply@anthropic\.com",
    re.IGNORECASE,
)
# Comandos que publican texto escrito por el agente
PUBLISHES = re.compile(r"\b(git\s+(commit|tag|notes|merge|rebase)|gh\s+(pr|issue|release|api))\b")
FILE_FLAGS = {"-F", "--file", "--body-file", "--notes-file"}


def referenced_files(command: str, cwd: str):
    try:
        args = shlex.split(command, posix=True)
    except ValueError:
        return
    for i, arg in enumerate(args):
        value = None
        if arg in FILE_FLAGS and i + 1 < len(args):
            value = args[i + 1]
        else:
            for flag in FILE_FLAGS:
                if arg.startswith(flag + "="):
                    value = arg.split("=", 1)[1]
        if value and value != "-":
            p = Path(value).expanduser()
            yield p if p.is_absolute() else Path(cwd) / p


def main():
    data = json.load(sys.stdin)
    if data.get("tool_name") != "Bash":
        return
    command = data.get("tool_input", {}).get("command", "")
    if not PUBLISHES.search(command):
        return

    texts = [command]
    for path in referenced_files(command, data.get("cwd", ".")):
        try:
            texts.append(path.read_text(errors="ignore"))
        except OSError:
            pass

    if any(ATTRIBUTION.search(t) for t in texts):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    "Bloqueado: el texto incluye atribución o coautoría de IA "
                    "(Co-Authored-By, 'Generated with ...', Claude-Session). "
                    "El usuario no la permite: quita esas líneas y vuelve a intentarlo."
                ),
            }
        }))


if __name__ == "__main__":
    main()
