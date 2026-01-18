🚀 RepoRead
A visual workspace for generating, organizing & previewing structured content

RepoRead is a desktop application built with Flutter that acts as a visual workspace for managing structured data and generating output — such as README files, documentation, release notes, or project overviews.

Originally built for Dart / pub.dev packages, RepoRead is designed to be generic, extensible, and workflow-oriented.

Think of it as a lightweight, offline, drag-and-drop documentation builder.

✨ Key Features
🧩 Modular Workspace

Dockable panels (drag & rearrange freely)

Resizable split views

Persistent layout (restored on launch)

📦 Item-Based Workflow

Manage items (packages, entries, snippets)

Reorder via drag & drop

Detect duplicates

Add / remove items dynamically

📝 Live README / Output Generator

Auto-generates Markdown

Live preview with Markdown rendering

Raw Markdown view

Copy-ready output

🧠 Smart Preview System

Preview rendered Markdown

View raw source

Drag items into preview for quick actions

⚡ Action Panel

Generate output

Trigger custom actions

Future-ready for Git / export / automation

🗂 Repo / Project Handling

Store repository paths

Persist settings locally

Reload & update state

📜 Logging Panel

Timestamped logs

Visual status indicators

Debug-friendly

🧠 What Is RepoRead Really?

RepoRead is not just a README generator.

It is a:

📚 Documentation builder

🧩 Modular workspace

🧠 Idea & structure organizer

🛠️ Generator engine

📄 Markdown authoring tool

⚙️ Future automation hub

It can be adapted for:

README / CHANGELOG generation

Project documentation

Package management

Portfolio generation

Knowledge bases

Snippet collections

Static content generation

Developer dashboards

🖥 UI Overview
┌────────────────────────────┐
│ Repo / Workspace / Preview│
├──────────────┬─────────────┤
│ Packages     │ Preview     │
│ Actions      │ Markdown    │
├──────────────┴─────────────┤
│ Log Panel                  │
└────────────────────────────┘


✔ Drag panels
✔ Resize splits
✔ Live preview
✔ Modular layout

🧱 Architecture Overview
Core Concepts
Concept	Description
Item	A data unit (package, file, entry, etc.)
Panel	UI container (Workspace, Preview, Log)
Template	Output generator
Renderer	Preview format (Markdown, text, etc.)
Command	Action or automation
Layout	User-defined panel layout
🧩 Current Capabilities

✔ Drag & drop UI
✔ Markdown rendering
✔ Live preview
✔ Layout persistence
✔ Package management
✔ Duplicate detection
✔ Badge generation
✔ Modular panel system

🔮 Planned / Possible Features

🔌 Plugin system (Templates / Renderers)

📦 Support for npm / PyPI / GitHub

📤 Export to file / clipboard

🔄 Git integration

🧠 Template presets

🗂 Workspace profiles

🎨 Theme customization

📜 Changelog generator

🧱 JSON / YAML support

🧩 Custom commands

🛠 Tech Stack

Flutter (Desktop)

Material 3

flutter_markdown

SharedPreferences

Custom layout & drag system

Pure Dart logic

No backend.
No cloud.
No telemetry.

🎯 Philosophy

Simple tools that stay out of your way.

RepoRead is designed to help you think, organize, and generate —
not to force a workflow on you.

🚧 Status

🟡 Active development / Prototype
✔ Core functionality works
🧪 Layout and UX being refined
🔜 Modularization & plugin system

📌 Future Name Ideas (Optional)

If you ever want to rebrand:

Forgepad

Builddeck

Docforge

Workbench

Stacknote

Modulr

Draftkit

📄 License

MIT (recommended)
