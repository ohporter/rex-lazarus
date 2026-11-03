# rex-lazarus

Starts Claude Code, Neovim and other programs again in their Rex panes after the Rex server
restarts.

Rex brings back sessions, windows and panes when its server starts, and each pane keeps its
block ID. It does not bring back the programs. rex-lazarus does that for these programs:

| Program | Recorded | Typed into the pane at restore, then Enter |
| --- | --- | --- |
| Claude Code | directory, conversation ID (from `~/.claude/sessions/<pid>.json`) | `cd -- <dir> && claude --resume <id>` |
| Neovim | Neovim's directory and open files, current file first (from its RPC socket) | `cd -- <dir> && nvim -- <files>` |
| Programs in the replay allowlist | directory, command line (from `/proc/<pid>/cmdline`) | `cd -- <dir> && <command line>` |

If Neovim's socket can't be reached, the command line it was started with is used instead.

## Replay allowlist

For a program that is not Claude Code or Neovim, restore types its command line again. Only
programs in the allowlist are recorded, because a command such as `make` or `apt upgrade`
must not run again at server start. The allowlist is in `~/.config/rex-lazarus/replay`
(`$XDG_CONFIG_HOME` is used if it is set). Write one program name per line; text after `#`
is a comment. The name is compared with the last part of the program's first argument. If
the file does not exist, this list is used:

```
htop btop top watch tail journalctl less man ssh lazygit tig k9s
```

If the file exists, it replaces that list. It does not add to it.

Limits:

- The command line is the one the program got after the shell expanded it. Aliases,
  redirections and `VAR=value` prefixes are lost. For a pipeline, only the foreground
  program is recorded.
- State that the program keeps only in memory is lost, for example a filter typed into
  `htop`.
- `ssh host command` runs the command again on the remote host. Remove `ssh` from the list
  if you use ssh to run commands that change things.
- `mosh` is not in the list. Its foreground program is `mosh-client`, which can't be started
  again from its command line.

## How it works

- `rex-lazarus save` runs every 30 seconds from a systemd user timer. It records each pane
  whose foreground program is Claude Code, Neovim or in the replay allowlist, and drops panes
  that run anything else.
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

## License

MIT. See `LICENSE`.
