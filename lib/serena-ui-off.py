"""Force Serena's web dashboard + GUI log window off in ~/.serena/serena_config.yml.
Missing keys fall back to Serena's defaults, so a partial file is valid when none exists yet."""
import os, re, sys

path = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/.serena/serena_config.yml")
KEYS = ("gui_log_window", "web_dashboard", "web_dashboard_open_on_launch")
text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
for key in KEYS:
    pat = re.compile(rf"^{key}:.*$", re.M)
    text = pat.sub(f"{key}: false", text) if pat.search(text) else text.rstrip("\n") + f"\n{key}: false\n"
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, "w", encoding="utf-8").write(text.lstrip("\n"))
print(f"  serena UI off: {path}")
