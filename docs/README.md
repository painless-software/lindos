# Lindos – Documentation

## Product

1. Locally running (tray-icon desktop) application with (locally running)
   [voice control](https://handy.computer/docs/models), (local) LLMs, and skills.
2. User interface inspired by [Claude Cowork](https://claude.com/product/cowork)
   and [Home Assistant](https://www.home-assistant.io/dashboards)
   ([apps](https://companion.home-assistant.io/)).
3. The interface evolves intelligently on its own (e.g. dashboards, thumbnail-icon
   links), so you immediately find what is currently relevant (e.g. what you worked
   on yesterday, what needs attention).
4. Agent server that can carry out tasks autonomously.
   All data sources are connected here so the server can reach them.

## Architecture (C4 Model)

The folder [architecture/](architecture/) contains the C4 model of Lindos
in two complementary formats:

<!-- pyml disable-num-lines 6 line-length-->
| File | Format | What it covers |
|---|---|---|
| `workspace.dsl` | [Structurizr DSL](https://docs.structurizr.com/dsl) | Single source of truth — Context, Containers, and Components (Desktop + Agent) in one file, with implied relationships and inspector validation |
| `c4-context.puml` | [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) | Level 1 – System Context |
| `c4-container.puml` | C4-PlantUML | Level 2 – Containers |
| `c4-component-desktop.puml` | C4-PlantUML | Level 3 – Components of the Desktop App |

The DSL is the recommended editing target (richer model, interactive
preview, validation). The handwritten `.puml` files are a static backup
that renders without a Structurizr server.

## Rendering

All commands run via Docker — no local Java, Graphviz, or PlantUML
install required. Run from the repository root:

<!-- pyml disable-num-lines 7 line-length-->
| Command | Purpose |
|---|---|
| `just diagrams` | Render everything to SVG (PlantUML + Structurizr) |
| `just diagrams-puml` | Render `c4-*.puml` → `c4-*.svg` |
| `just diagrams-dsl` | Export `workspace.dsl` to PlantUML, then to `workspace-*.svg` |
| `just diagrams-serve` | Open Structurizr at <http://localhost:8080> for live editing |
| `just clean` | Remove all generated artifacts |

The interactive server (`diagrams-serve`) auto-reloads `workspace.dsl`
on save and runs the inspector — fastest feedback loop while iterating
on the model.
