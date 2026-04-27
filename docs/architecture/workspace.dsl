workspace "Lindos" "Lokaler Desktop-Assistent mit autonomem Agent-Server." {

    !identifiers hierarchical

    properties {
        "structurizr.workspace.scope" "SoftwareSystem"
    }

    model {
        !impliedRelationships true

        user = person "Mitarbeiter" "Erteilt Sprachbefehle, delegiert Aufgaben, konsumiert die adaptive UI."

        lindos = softwareSystem "Lindos" "Lokaler Desktop-Assistent (Tray) plus autonomer Agent-Server." {

            desktop = container "Desktop App (Tray)" "Lokal laufende Tray-Anwendung, lokale Sprachsteuerung, lokale LLMs, lokale Skills, adaptive UI." "Rust / WebView" {
                tray         = component "Tray Shell" "Systemtray-Icon, Fenster-Lifecycle, OS-Integration" "Rust"
                uiShell      = component "UI Shell" "Layout-Container für Dashboards & Panels" "WebView"
                dashboards   = component "Dashboard Renderer" "Karten, Thumbnails, Quick-Links — Stil Claude Cowork + Home Assistant" "Web"
                focusFeed    = component "Focus Feed" "‘Woran du gestern gearbeitet hast’, ‘Benötigt Aufmerksamkeit’" "Web"
                commandBar   = component "Command Bar" "Universelle Eingabe (Text + Sprache)" "Web"
                stt          = component "STT" "Speech-to-Text, lokal — selbes Modell wie Handy-App" "Parakeet V3 (NVIDIA NeMo)"
                tts          = component "TTS" "Text-to-Speech, lokal" "Piper"
                intent       = component "Intent Router" "Routet zu Skill / lokalem LLM / Agent-Server" "Rust"
                localLLM     = component "Lokales LLM Runtime" "Inferenz mit kleinem Modell" "llama.cpp / ONNX"
                rag          = component "Local RAG" "Embeddings + Retrieval" "Rust"
                skillHost    = component "Skill Host" "Sandbox für Skills" "Rust / WASM"
                skillsLib    = component "Skills Library" "Datei, Kalender lokal, OS-Aktionen, Shortcuts" "Plugins"
                adaptive     = component "Adaptive UI Engine" "Sammelt Signale, lernt Relevanz, generiert Layouts" "Rust"
                signals      = component "Signal Collector" "Lokale Nutzungs­telemetrie" "Rust"
                localStore   = component "Local Store" "Verlauf, Präferenzen, Embeddings, Cache" "SQLite + Vector"
                agentClient  = component "Agent Server Client" "WebSocket/HTTPS, mTLS, Streaming" "Rust"
            }

            agent = container "Agent Server" "Autonome, mehrstufige Aufgaben­ausführung mit Zugriff auf alle Unternehmens­datenquellen." "Service" {
                agentCore  = component "Agent Orchestrator" "Plant Aufgaben, ruft Tools auf, führt autonom aus" "Service"
                connectors = component "Connector Registry" "Tool-Anbindungen an Datenquellen (MCP-Stil)" "Service"
                serverLLM  = component "Server-LLM Backend" "Stärkeres Modell für Reasoning & Tool-Use" "Self-hosted / vermittelt"
                memory     = component "Agent Memory" "Langzeit­gedächtnis, Aufgaben-Historie, Audit" "Vector DB + Event-Log"
                scheduler  = component "Task Scheduler" "Wiederkehrende & verzögerte Läufe" "Service"
            }
        }

        email   = softwareSystem "E-Mail / Kalender" "M365, Google Workspace, IMAP" "External"
        files   = softwareSystem "Dateispeicher" "SharePoint, Drive, Nextcloud, S3" "External"
        crm     = softwareSystem "CRM" "Kunden, Leads, Opportunities" "External"
        erp     = softwareSystem "ERP" "Aufträge, Rechnungen, Stammdaten" "External"
        wiki    = softwareSystem "Wiki" "Confluence, Notion, internes Wiki" "External"
        tickets = softwareSystem "Ticketing / DevOps" "Jira, GitLab, GitHub" "External"
        chat    = softwareSystem "Chat / Kollaboration" "Slack, Teams" "External"

        # ------------------------------------------------------------
        # Beziehungen — nur am tiefsten Level, höhere via !impliedRelationships
        # Format: source -> destination "Description" "Technology"
        # ------------------------------------------------------------

        # Person-Touchpoints (Komponenten der Desktop App)
        user        -> lindos.desktop.commandBar  "Tippt / spricht"        "Sprache, Tastatur"
        user        -> lindos.desktop.dashboards  "Klickt Thumbnails"      "Maus / Touch"
        lindos.desktop.tts -> user                "Spricht Antwort"        "Audio Out"

        # Internes Wiring der Desktop App
        lindos.desktop.tray       -> lindos.desktop.uiShell       "Steuert Fenster"          "OS-API"
        lindos.desktop.uiShell    -> lindos.desktop.dashboards    "Mountet Panel"            "WebView IPC"
        lindos.desktop.uiShell    -> lindos.desktop.focusFeed     "Mountet Panel"            "WebView IPC"
        lindos.desktop.uiShell    -> lindos.desktop.commandBar    "Mountet Panel"            "WebView IPC"
        lindos.desktop.uiShell    -> lindos.desktop.signals       "Sendet Events"            "WebView IPC"
        lindos.desktop.commandBar -> lindos.desktop.stt           "Audio-Stream"             "Audio Pipe"
        lindos.desktop.stt        -> lindos.desktop.intent        "Transkript"               "In-Process"
        lindos.desktop.commandBar -> lindos.desktop.intent        "Text"                     "In-Process"
        lindos.desktop.intent     -> lindos.desktop.localLLM      "Lokales Reasoning"        "In-Process"
        lindos.desktop.intent     -> lindos.desktop.skillHost     "Skill ausführen"          "In-Process"
        lindos.desktop.intent     -> lindos.desktop.agentClient   "Komplexe Aufgabe"         "In-Process"
        lindos.desktop.localLLM   -> lindos.desktop.rag           "Kontext-Retrieval"        "In-Process"
        lindos.desktop.localLLM   -> lindos.desktop.tts           "Antworttext"              "In-Process"
        lindos.desktop.rag        -> lindos.desktop.localStore    "Vektor-Suche"             "SQLite/Vector"
        lindos.desktop.skillHost  -> lindos.desktop.skillsLib     "Lädt Plugin"              "WASM Runtime"
        lindos.desktop.skillsLib  -> lindos.desktop.localStore    "Liest/schreibt"           "SQLite/FS"
        lindos.desktop.signals    -> lindos.desktop.adaptive      "Push Telemetrie"          "In-Process"
        lindos.desktop.adaptive   -> lindos.desktop.localStore    "Liest/schreibt Signale"   "SQLite/Vector"
        lindos.desktop.adaptive   -> lindos.desktop.dashboards    "Layout-Update"            "WebView IPC"
        lindos.desktop.adaptive   -> lindos.desktop.focusFeed     "Inhalts-Update"           "WebView IPC"

        # Cross-Container: Desktop → Agent Server
        lindos.desktop.agentClient -> lindos.agent.agentCore      "Delegiert Aufgaben"       "HTTPS / WebSocket, mTLS"

        # Internes Wiring des Agent Servers
        lindos.agent.scheduler   -> lindos.agent.agentCore        "Triggert Läufe"           "In-Process"
        lindos.agent.agentCore   -> lindos.agent.serverLLM        "Reasoning, Tool-Choice"   "HTTP/JSON"
        lindos.agent.agentCore   -> lindos.agent.connectors       "Tool-Aufrufe"             "In-Process"
        lindos.agent.agentCore   -> lindos.agent.memory           "Liest/schreibt Kontext"   "Vector DB Driver"

        # Agent → externe Unternehmens­datenquellen
        lindos.agent.connectors  -> email   "Liest & schreibt"  "OAuth / REST"
        lindos.agent.connectors  -> files   "Liest & schreibt"  "OAuth / REST"
        lindos.agent.connectors  -> crm     "Liest"             "REST"
        lindos.agent.connectors  -> erp     "Liest"             "REST"
        lindos.agent.connectors  -> wiki    "Liest"             "REST"
        lindos.agent.connectors  -> tickets "Liest & schreibt"  "REST"
        lindos.agent.connectors  -> chat    "Liest & schreibt"  "REST / WebSocket"
    }

    views {
        systemContext lindos "c4-context" {
            include *
            autoLayout lr
        }

        container lindos "c4-container" {
            include *
            autoLayout lr
        }

        component lindos.desktop "c4-component-desktop" {
            include *
            autoLayout tb
        }

        component lindos.agent "c4-component-agent" {
            include *
            autoLayout tb
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
