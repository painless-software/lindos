# Lindos – Documentation

## Product

1. Locally running (tray-icon desktop) application with (locally running)
   [voice control][handy], (local) LLMs, and skills.
2. User interface inspired by [Claude Cowork][cowork] and
   [Home Assistant][ha:home] ([apps][ha:apps]).
3. The interface evolves intelligently on its own (e.g. dashboards, thumbnail-icon
   links), so you immediately find what is currently relevant (e.g. what you worked
   on yesterday, what needs attention).
4. Agent server that can carry out tasks autonomously.
   All data sources are connected here so the server can reach them.

## Architecture (C4 Model)

The folder [architecture/](architecture/) contains the C4 model of Lindos.
The [Structurizr DSL][dsl] file `workspace.dsl`
is the single source of truth — Context, Containers, and Components
(Desktop + Agent) live in one file, with implied relationships and
inspector validation. Edit only this file.

`just diagrams` exports the views to [C4-PlantUML][c4:puml] under
`architecture/generated/`. The `.puml` files are committed so they render
directly on GitLab; the much larger `.svg` files are gitignored.

| File | What it covers |
|---|---|
| `c4-context.puml` | Level 1 – System Context |
| `c4-container.puml` | Level 2 – Containers |
| `c4-component-desktop.puml` | Level 3 – Components of the Desktop App |
| `c4-component-agent.puml` | Level 3 – Components of the Agent Server |

## Rendering

All commands run via Docker — no local Java, Graphviz, or PlantUML
install required. Run from the repository root:

| Command | Purpose |
|---|---|
| `just diagrams` | Export `workspace.dsl` to PlantUML and render to SVG |
| `just diagrams-serve` | Run Structurizr locally for live editing |
| `just clean` | Remove all generated artifacts |

The interactive server (`diagrams-serve`) auto-reloads `workspace.dsl`
on save and runs the inspector — fastest feedback loop while iterating
on the model.

[c4:puml]: https://github.com/plantuml-stdlib/C4-PlantUML
[cowork]: https://claude.com/product/cowork
[dsl]: https://docs.structurizr.com/dsl
[ha:apps]: https://companion.home-assistant.io/
[ha:home]: https://www.home-assistant.io/dashboards
[handy]: https://handy.computer/docs/models
