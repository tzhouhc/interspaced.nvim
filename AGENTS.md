<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# AGENTS.md - Interspaced.nvim

This document provides essential information for AI agents working with the Interspaced.nvim Neovim plugin repository.

## Project Overview

**Interspaced.nvim** is a Neovim plugin for making cut and paste operations always leave the result properly spaced. It's built using 100% Lua and follows the nvim-plugin-template structure.

## Project Structure

```
.
├── lua/interspaced/          # Main Lua module
│   └── init.lua             # Plugin entry point and configuration
├── plugin/                  # Neovim plugin loader
│   └── interspaced.lua     # Plugin initialization file
├── doc/                    # Documentation
│   └── my-template-docs.txt # Auto-generated vimdoc
├── .github/                # GitHub workflows and templates
│   ├── workflows/
│   │   ├── lint-test.yml   # CI for linting and testing
│   │   ├── docs.yml        # Auto-generates documentation
│   │   └── release.yml     # Release automation
│   └── ISSUE_TEMPLATE/
├── .stylua.toml            # Lua formatting configuration
├── README.md               # Project documentation
└── LICENSE                 # MIT License
```

## Essential Commands

### Formatting
- **Check formatting**: `stylua --check lua/`
- **Format code**: `stylua lua/`

### Testing
- **Run tests**: `make test` (as referenced in CI workflow)
- Note: Test files are not yet implemented in this repository

### Documentation
- **Generate vimdoc**: Automatically handled by GitHub Actions using panvimdoc

## Code Style & Conventions

### Lua Style Guide
- **Indentation**: 2 spaces (configured in `.stylua.toml`)
- **Line width**: 120 characters
- **Line endings**: Unix (LF)
- **Quote style**: AutoPreferDouble
- **Function calls**: Always use parentheses (`no_call_parentheses = false`)

### Module Structure
- Lua modules follow Neovim plugin conventions
- Main module is `lua/interspaced/init.lua`
- Plugin loader is `plugin/interspaced.lua`
- Configuration uses `vim.tbl_deep_extend("force", ...)` for merging

### Naming Conventions
- Module names: `M` for main module table
- Configuration: `config` table with type annotations
- Functions: Use descriptive names with snake_case

## Development Workflow

### CI/CD Pipeline
1. **Linting**: Stylua formatting check on every push/pull request
2. **Testing**: Cross-platform tests on Ubuntu, macOS, Windows with stable and nightly Neovim
3. **Documentation**: Auto-generated vimdoc on pushes to main branch
4. **Releases**: Automated release workflow (requires LUAROCKS_API_KEY)

### Testing Strategy
- Uses plenary.nvim and busted for testing (as per template)
- Tests should be placed in `tests/` directory
- Minimal init file pattern: `tests/minimal_init.lua`
- Test files follow pattern: `tests/interspaced/interspaced_spec.lua`

## Important Patterns

### Plugin Initialization
```lua
-- plugin/interspaced.lua
require("interspaced").setup()
```

### Module Setup Pattern
```lua
-- lua/interspaced/init.lua
local M = {}
M.config = { ... }
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end
return M
```

### Type Annotations
The project uses Lua type annotations (`---@type`, `---@param`, `---@class`) for better documentation and tooling support.

## Gotchas & Non-Obvious Patterns

1. **Template Project**: This is based on nvim-plugin-template, so many files (like test structure) are placeholders
2. **No Makefile**: Unlike the template, this project doesn't have a Makefile yet
3. **Empty Tests**: Test directory structure exists in template docs but not yet implemented
4. **Documentation**: Vimdoc is auto-generated from README.md using panvimdoc

## GitHub Integration

### Issue Templates
- **Bug reports**: Use `bug: ` prefix with structured template
- **Feature requests**: Structured template for new features

### Workflows
- All workflows run on Ubuntu latest
- Stylua version: latest
- Neovim versions tested: stable and nightly

## Development Notes

- This is a **new plugin** with minimal implementation
- The main functionality (spacing for cut/paste) needs to be implemented
- Follow existing patterns from the template for adding features
- When adding tests, follow the structure shown in `doc/my-template-docs.txt`

## References

- **Template**: ellisonleao/nvim-plugin-template
- **Stylua**: JohnnyMorganz/StyLua for formatting
- **Testing**: plenary.nvim and busted
- **Documentation**: panvimdoc for vimdoc generation