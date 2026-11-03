# rex-lazarus

Starts Claude Code and Neovim again in their Rex panes after the Rex server restarts.

Rex brings back sessions, windows and panes when its server starts, and each pane keeps its
block ID. It does not bring back the programs. rex-lazarus does that for two programs:

| Program | Recorded | Typed into the pane at restore, then Enter |
| --- | --- | --- |
| Claude Code | directory, conversation ID (from `~/.claude/sessions/<pid>.json`) | `cd -- <dir> && claude --resume <id>` |
| Neovim | Neovim's directory and open files, current file first (from its RPC socket) | `cd -- <dir> && nvim -- <files>` |

If Neovim's socket can't be reached, the command line it was started with is used instead.

## How it works

- `rex-lazarus save` runs every 30 seconds from a systemd user timer. It records each pane
  whose foreground program is Claude Code or Neovim, and drops panes that run anything else.
  If the server can't be reached, it keeps the last record. After a server restart it does
  not save until restore has run, so the new, empty panes never replace the record.
- `rex-lazarus restore --background` runs from `rex_lazarus.lua`, which `init.lua` loads,
  when the server starts. It waits for the server, then for each recorded pane that still
  exists, waits until the pane's shell has finished starting and types the command and Enter.
  It restores once per server start, never on `rex config reload`. If two panes were in one
  Claude conversation, only the first is resumed.
- `rex-lazarus show` prints what restore would type into each pane.
- `rex-lazarus restore --force` restores again by hand.

State and the log are in `~/.local/state/rex-lazarus/` (`state.json`, `rex-lazarus.log`).
Every rex call names the server with `-S` and uses `--autostart=false`.

## Install

```sh
./install.sh
```

The script installs `rex-lazarus` in `~/.local/bin`, installs and starts the systemd user
timer, and puts `rex_lazarus.lua` beside the Rex config file. It adds
`require("rex_lazarus")` to `init.lua` if that line is not there. It finds the Rex config
file as Rex does: `$REX_CONFIG`, else `$XDG_CONFIG_HOME/rex/init.lua`, else
`~/.config/rex/init.lua`. It is safe to run the script again.

Requirements: Python 3.10 or later (standard library only), Rex with API revision 9 or later.

