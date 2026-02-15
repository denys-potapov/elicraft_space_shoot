# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpaceShoot is a Phoenix 1.8.3 web application built with Elixir (~> 1.15), Phoenix LiveView (~> 1.1.0), Tailwind CSS v4, and esbuild. It uses Bandit as the HTTP adapter and Jason for JSON.

## Commands

```bash
# Initial setup
mix setup                     # Install deps + build assets

# Development server
mix phx.server                # Start on localhost:4000
iex -S mix phx.server         # Start with interactive shell

# Testing
mix test                      # Run all tests
mix test test/path/file.exs   # Run specific test file
mix test --failed             # Re-run previously failed tests

# Pre-commit (run before committing - compiles with warnings-as-errors, formats, tests)
mix precommit

# Code formatting
mix format

# Assets
mix assets.build              # Dev asset compilation
mix assets.deploy             # Production assets (minified + digested)
```

The `precommit` alias runs in the `:test` environment (configured in `cli/0`).

## Architecture

```
SpaceShoot.Application (OTP Supervisor)
├── SpaceShootWeb.Telemetry
├── DNSCluster
├── Phoenix.PubSub (name: SpaceShoot.PubSub)
└── SpaceShootWeb.Endpoint (Bandit HTTP + LiveView WebSocket)
    └── SpaceShootWeb.Router
        ├── :browser pipeline (HTML)
        └── :api pipeline (JSON)
```

- **`lib/space_shoot/`** - Domain/business logic (contexts)
- **`lib/space_shoot_web/`** - Web layer (controllers, LiveViews, components, router)
- **`lib/space_shoot_web.ex`** - Macros providing `use SpaceShootWeb, :controller/:html/:live_view/:live_component`; also contains `html_helpers` for app-wide template imports
- **`lib/space_shoot_web/components/core_components.ex`** - Reusable UI components (`<.button>`, `<.flash>`, `<.icon>`, `<.input>`, etc.)
- **`lib/space_shoot_web/components/layouts.ex`** - Layout components including `Layouts.app`, `flash_group`, theme toggle
- **`test/support/conn_case.ex`** - Test case module for connection tests

## Key Conventions (from AGENTS.md)

Read `AGENTS.md` for the full set of rules. Critical points:

### Phoenix & LiveView
- LiveView templates must begin with `<Layouts.app flash={@flash} ...>` wrapping all content
- `Layouts` is already aliased in `space_shoot_web.ex` - no extra alias needed
- Use `<.icon name="hero-x-mark">` for icons (from core_components), never Heroicons modules directly
- Use `<.input field={@form[:field]}>` for form inputs (from core_components)
- Use `to_form/2` to create forms, never pass changesets directly to templates
- Use streams for collections (`stream/3`, `stream_delete/3`), never deprecated `phx-update="append"/"prepend"`
- Avoid LiveComponents unless there's a strong specific need
- LiveView routes: scope alias is already `SpaceShootWeb`, so use `live "/path", MyLive`
- `<.flash_group>` must only be called inside `layouts.ex`

### Templates (HEEx)
- Use `{...}` for interpolation in tag attributes and values; use `<%= %>` only for block constructs (if/cond/case/for)
- Class attributes must use list syntax: `class={["px-2", @flag && "py-5"]}`
- No `<% Enum.each %>` - use `<%= for item <- @collection do %>`
- No inline `<script>` tags - use colocated hooks (`:type={Phoenix.LiveView.ColocatedHook}`) with `.` prefixed names
- Comments: `<%!-- comment --%>`

### Elixir
- No index access on lists (`mylist[i]` is invalid) - use `Enum.at/2`
- Bind results of block expressions (`socket = if ... do ... end`)
- Never nest multiple modules in the same file
- No map access syntax on structs - use dot access (`my_struct.field`)
- Predicate functions: end with `?`, don't start with `is_`

### CSS/JS
- Tailwind CSS v4 (no tailwind.config.js) - uses `@import "tailwindcss"` syntax in `app.css`
- Manually write Tailwind-based components instead of using daisyUI components directly
- No `@apply` in raw CSS
- Only `app.js` and `app.css` bundles are supported - vendor deps must be imported into these
- No external `<script src>` or `<link href>` in layouts

### Testing
- Use `start_supervised!/1` for process lifecycle in tests
- Avoid `Process.sleep/1` - use `Process.monitor/1` + `assert_receive {:DOWN, ...}` or `:sys.get_state/1`
- Use `LazyHTML` for HTML assertions, test against element IDs not raw HTML
- Test outcomes, not implementation details

### HTTP Client
- Use `Req` for HTTP requests if an HTTP client is needed - avoid HTTPoison, Tesla, httpc
