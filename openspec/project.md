# Project Context

## Purpose
Interspaced.nvim is a Neovim plugin that ensures cut and paste operations always leave the result properly spaced. The plugin automatically adjusts spacing around text when cutting or pasting to maintain consistent formatting and readability in Neovim buffers.

## Tech Stack
- **Primary Language**: Lua 5.1 (Neovim LuaJIT)
- **Plugin Framework**: Native Neovim plugin structure
- **Formatting**: Stylua for Lua code formatting
- **Testing**: plenary.nvim and busted (planned, not yet implemented)
- **Documentation**: panvimdoc for vimdoc generation
- **CI/CD**: GitHub Actions with cross-platform testing
- **Package Management**: LuaRocks for distribution

## Project Conventions

### Code Style
- **Indentation**: 2 spaces (configured in `.stylua.toml`)
- **Line width**: 120 characters maximum
- **Line endings**: Unix (LF)
- **Quote style**: AutoPreferDouble (double quotes preferred)
- **Function calls**: Always use parentheses (`no_call_parentheses = false`)
- **Type annotations**: Use Lua type annotations (`---@type`, `---@param`, `---@class`) for documentation
- **Module pattern**: `local M = {}` for main module table
- **Naming**: snake_case for variables and functions, PascalCase for classes/types

### Architecture Patterns
- **Plugin structure**: Follows nvim-plugin-template conventions
- **Configuration**: Uses `vim.tbl_deep_extend("force", ...)` for merging user config with defaults
- **Module organization**: Main module at `lua/interspaced/init.lua`, plugin loader at `plugin/interspaced.lua`
- **Error handling**: Graceful fallbacks with Neovim API compatibility checks
- **State management**: Minimal state, focus on pure functions where possible

### Testing Strategy
- **Test framework**: plenary.nvim and busted (planned implementation)
- **Test location**: `tests/` directory with `tests/interspaced/interspaced_spec.lua` pattern
- **Minimal init**: Use `tests/minimal_init.lua` for isolated test environment
- **CI testing**: Cross-platform tests on Ubuntu, macOS, Windows with both stable and nightly Neovim
- **Test coverage**: Focus on core spacing logic and edge cases

### Git Workflow
- **Branching**: Main branch for stable releases, feature branches for development
- **Commit conventions**: Use conventional commit messages with prefixes
- **Issue tracking**: GitHub Issues with structured templates (bug: , feature: prefixes)
- **Pull requests**: Required for all changes, reviewed before merging
- **Release process**: Automated via GitHub Actions with LuaRocks publishing

## Domain Context
- **Neovim plugin ecosystem**: Follows standard Neovim plugin patterns and conventions
- **Text editing operations**: Focus on cut (`d`, `c`, `x`) and paste (`p`, `P`) commands
- **Spacing rules**: Context-aware spacing based on surrounding text and cursor position
- **Buffer operations**: Works with Neovim buffers, windows, and text objects
- **User experience**: Non-intrusive, automatic spacing adjustments that feel natural

## Important Constraints
- **Neovim compatibility**: Must work with Neovim stable (0.9+) and nightly versions
- **Performance**: Minimal performance impact on editing operations
- **Backwards compatibility**: Maintain compatibility with existing user workflows
- **Configuration**: Support user customization while providing sensible defaults
- **Cross-platform**: Must work on Linux, macOS, and Windows
- **Dependencies**: Minimal external dependencies, prefer Neovim built-in APIs

## External Dependencies
- **Neovim**: Primary runtime environment (0.9+ required)
- **Stylua**: Code formatting and linting (development dependency)
- **plenary.nvim**: Testing framework (development dependency, planned)
- **busted**: Test runner (development dependency, planned)
- **panvimdoc**: Documentation generation (CI dependency)
- **GitHub Actions**: CI/CD pipeline automation
- **LuaRocks**: Package distribution and publishing