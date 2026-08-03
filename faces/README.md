---
title: Dataface
---

# Welcome to Dataface

This is your project's landing page. Everything under `faces/` becomes a
served page — edit the files here to build dashboards, reports, and docs
for your data project.

## Authoring modes

**YAML (`.yaml`)** — structured dashboards with queries, charts, and layout.
See the [dataface guide](guide) for a working example covering queries, charts, and variables.

**Markdown (`.md`)** — prose pages like this one. Add YAML frontmatter for
queries and charts, then embed them inline with `{% raw %}{{ chart my_chart }}{% endraw %}`.

## Next steps

1. Open `faces/guide.yaml` and tweak the content.
2. Run `dft serve` and open the URL it prints.
3. Add new `.yaml` or `.md` files under `faces/` — they appear automatically.
4. Run `dft validate` to validate your face YAML for errors.
