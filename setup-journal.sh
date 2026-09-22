#!/usr/bin/env bash
set -e

echo "Setting up audit-journal folder structure..."

mkdir -p daily weekly evidence

TODAY=$(date +%Y-%m-%d)
if [ ! -f "daily/day-01.md" ]; then
  cat > daily/day-01.md << EOF
# Day 1 — Environment Setup

**Date:** ${TODAY}

## What I tackled
Setting up and verifying my Foundry toolchain before touching any real audit work.

## What I did
\`\`\`bash
forge --version
cast --version
anvil --version
forge init my-audit-practice
cd my-audit-practice
forge build
forge test -vvv
\`\`\`

## Evidence
![Foundry version check](../evidence/day-01/versions.png)
![forge test passing](../evidence/day-01/tests-passing.png)

## What I learned
A clean, verified dev environment is step zero for any real audit — you can't
trust findings from a toolchain you haven't confirmed works. Also learned the
difference between Forge (build/test), Cast (CLI for chain interaction), and
Anvil (local node).

## Links used
- [Foundry Book — Getting Started](https://book.getfoundry.sh/)
EOF
  mkdir -p evidence/day-01
  echo "Created daily/day-01.md and evidence/day-01/"
fi

if [ ! -f "README.md" ]; then
  cat > README.md << 'EOF'
# Smart Contract Security Audit — 30-Day Journal

A day-by-day documented journey through smart contract security fundamentals,
vulnerability classes, the professional audit toolchain, and a full independent
audit + live contest submission.

## Structure
- `/daily` — one entry per day, each self-contained (problem, actions, evidence, learning)
- `/weekly` — a recap written every 7 days, summarizing that week's daily entries
- `/evidence` — screenshots and terminal output backing up each daily entry
- `SUMMARY.md` — the one-page overview (added at the end of the challenge)

## Progress
- [ ] Week 1 — Foundations (Days 1–7)
- [ ] Week 2 — Vulnerability Catalog (Days 8–14)
- [ ] Week 3 — Tooling Fluency (Days 15–21)
- [ ] Week 4 — Portfolio Build (Days 22–30)

## Deliverables
- [ ] Independent audit report with proof-of-concept exploits
- [ ] CodeHawks First Flight submission
EOF
  echo "Created README.md"
fi

echo ""
echo "Done. Structure:"
find . -maxdepth 2 -not -path '*/.git*' | sort
