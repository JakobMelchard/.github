#!/usr/bin/env python3
"""Triage one feedback issue with opencode, in the repo checkout this runs in.

Env: GH_TOKEN, GH_REPO (owner/name), ISSUE (number), MODEL (provider/model), OPENCODE_CONFIG
(the read-only `triage` agent), PROMPT (path). The issue goes to `.agent/issue.json` for the agent
to read; the reply must contain a JSON verdict, which is applied with `gh`. Exit 1 on any failure
so the run shows red. Stdlib only.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

KINDS = ("bug", "enhancement", "question")
READY = "agent:ready"
TIMEOUT = 15 * 60


def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, check=True, **kw).stdout


def texts(node, out):
    """Every string under a key named `text`, in document order: opencode's JSON events carry the reply there."""
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "text" and isinstance(v, str):
                out.append(v)
            else:
                texts(v, out)
    elif isinstance(node, list):
        for v in node:
            texts(v, out)
    return out


def verdict(stdout):
    """The last JSON object with `title` and a known `kind` in what the agent said, else None."""
    parts = []
    for line in stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            texts(json.loads(line), parts)
        except ValueError:
            parts.append(line)
    text = "\n".join(parts)
    dec = json.JSONDecoder()
    found = None
    for m in re.finditer(r"\{", text):
        try:
            o, _ = dec.raw_decode(text, m.start())
        except ValueError:
            continue
        if isinstance(o, dict) and isinstance(o.get("title"), str) and o.get("kind") in KINDS:
            found = o
    return found


def main():
    repo, n, model = os.environ["GH_REPO"], os.environ["ISSUE"], os.environ["MODEL"]
    issue = sh(["gh", "issue", "view", n, "--repo", repo, "--json", "number,title,body,labels"])
    Path(".agent").mkdir(exist_ok=True)
    Path(".agent/issue.json").write_text(issue)
    prompt = Path(os.environ["PROMPT"]).read_text()
    args = ["opencode", "run", "--agent", "triage", "--format", "json", "-m", model, prompt]
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        sys.exit(f"opencode: no reply within {TIMEOUT}s")
    if p.returncode:
        sys.exit(f"opencode exit {p.returncode}\n{(p.stdout + p.stderr)[-3000:]}")
    v = verdict(p.stdout)
    if not v:
        sys.exit(f"opencode gave no verdict\n{(p.stdout + p.stderr)[-3000:]}")

    kind, scoped = v["kind"], v.get("scoped") is True
    labels = [kind] + ([READY] if scoped else [])
    for label in labels:  # gh refuses to add a label that does not exist yet
        subprocess.run(["gh", "label", "create", label, "--repo", repo, "--force"], capture_output=True)
    sh(["gh", "issue", "edit", n, "--repo", repo, "--title", v["title"][:120], "--add-label", ",".join(labels)])
    files = "\n".join(f"- `{f}`" for f in v.get("files", []) if isinstance(f, str))
    body = f"**Triage** ({kind}, {'scoped: an agent can pick this up' if scoped else 'needs a human look'})\n\n{v.get('summary', '').strip()}"
    if files:
        body += f"\n\n{files}"
    subprocess.run(["gh", "issue", "comment", n, "--repo", repo, "--body-file", "-"], input=body, text=True, check=True)
    print(f"{repo}#{n}: {v['title']} [{', '.join(labels)}]")


if __name__ == "__main__":
    main()
