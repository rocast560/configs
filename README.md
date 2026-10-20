# configs

My Neovim and psmux configs for Windows.

```
nvim/    Neovim config (init.lua + vim.pack lockfile)
psmux/   psmux config and the two PowerShell scripts it calls
```

The live config locations are junctions into this repo, so editing a config edits the repo. Commit from here.

| Live location                 | Points to      |
| ----------------------------- | -------------- |
| `%LOCALAPPDATA%\nvim`         | `configs\nvim`  |
| `%USERPROFILE%\.config\psmux` | `configs\psmux` |

## Setup on a new machine

Requirements:

- Neovim 0.12+ (the config uses the built-in `vim.pack` plugin manager)
- The tree-sitter CLI and a C compiler, which nvim-treesitter's `main` branch needs to build parsers
- psmux: `winget install marlocarlo.psmux`

Clone the repo to `C:\Users\<you>\configs` and create the junctions in PowerShell. Junctions don't need admin rights, unlike symlinks.

```powershell
git clone https://github.com/rocast560/configs.git $HOME\configs

New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$HOME\configs\nvim"
New-Item -ItemType Directory -Force "$HOME\.config" | Out-Null
New-Item -ItemType Junction -Path "$HOME\.config\psmux" -Target "$HOME\configs\psmux"
```

Make sure `~/.psmux.conf`, `~/.psmuxrc` and `~/.tmux.conf` don't exist. psmux reads the first of those it finds and only falls back to `~/.config/psmux/psmux.conf` when none of them are there.

`psmux.conf` calls its scripts by absolute path (`C:\Users\rober\.config\psmux\...`). Change those paths if your user folder is different.

The first time Neovim starts, it clones the plugins and installs the Tree-sitter parsers.

## Neovim

- catppuccin mocha with Tree-sitter highlight groups, falling back to `habamax` if the plugin fails to load
- Tree-sitter parsers: cpp, c, python, lua, vim, vimdoc, markdown, markdown_inline, json, bash
- Tree-sitter highlighting, indentation and folding for any filetype that has a parser, with folds open by default

## psmux

The prefix is the default `Ctrl-b`.

| Keys               | Action                                             |
| ------------------ | -------------------------------------------------- |
| `v` / `s`          | Split side by side / top and bottom, in the current folder |
| `h` `j` `k` `l`    | Move between panes                                 |
| `H` `J` `K` `L`    | Resize pane by 5 (repeatable)                      |
| `y`                | Toggle synchronized input across panes (`sync.ps1`) |
| `Y`                | Turn synchronized input off                        |
| `C`                | Copy the whole pane history to the clipboard (`copyall.ps1`) |
| `r`                | Reload the config                                  |
| `S`                | Session and window picker                          |
| `Tab`              | Last window                                        |

A red **SYNC** label shows on the right of the status bar while panes are synchronized. Scrollback is 100,000 lines. Windows and panes are numbered from 1, and windows renumber when one closes.
