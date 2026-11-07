# Screen PNG coverage and approval state

Every listed screen now has a filename-matched PNG and Markdown spec. The original 15 PNGs are *cropped directional storyboard references*, not approved full-resolution independent screen designs. The newly created 25 PNGs are clearly marked **SCHEMATIC ONLY** wireframes—not photorealistic UI approvals. For real production, Design Director must replace each with accurate individual high-fidelity phone-sized PNG using real licensed food/family photography, remove all scaffold labels, acquire owner approval, then QA must compare actual Flutter screenshots against the approved targets.

The presence of a PNG fulfills file pairing, **not** visual fidelity. `SCREEN_INDEX.csv` is authoritative for `visual_status` on each screen. No agent may label schematic/directional reference `approved` without explicit review evidence.
