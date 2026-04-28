# Onboarding prompt — short briefing for any AI assistant

Paste this at the start of a new session if `CLAUDE.md` was not
auto-loaded by your tool.

---

You are joining the **Network-Disadoption** project, which compares
peer effects on adoption and disadoption between two longitudinal
panels: ADVANCE (e-cig in 1,047 California adolescents, 2020–2024,
8 waves) and KFP (Pill+Condom in 1,047 Korean women, 1964–1973,
10 years).

Before doing anything else, read these files in order:

1. `CLAUDE.md` — full project context, decisions made, conventions.
2. `docs/methodology.md` — the panel reconstruction algorithm and
   key definitions (Option II refined, FN classification, etc.).
3. `docs/disadoption-study.pdf` — the current report (v2).
4. `prompts/v3-instructions.md` — what the next iteration should
   change (if you are working toward v3).

Key things to internalise:

- KFP `fpt_p`/`byrt_p` are episode-indexed, NOT calendar-year-indexed.
  v1 of this analysis got this wrong and produced spurious findings.
  The current panel construction (in `R/01-kfp-panel.R`) is correct.
- Use "community" not "cluster" in user-facing text from v3 onward.
- For V coefficients, report both per-unit and per-10pp interpretations.
- Substitution from PC to other modern methods is right-censured,
  not counted as a disadoption event.

Then ask the user what they want to work on.
