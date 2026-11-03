#!/bin/sh
# SPDX-License-Identifier: MIT
# Install rex-lazarus for the current user. It is safe to run this script again.
set -eu

cd -- "$(dirname -- "$0")"

# The directory of the Rex config file, found the same way as Rex finds it.
rex_init="${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}"
rex_dir="$(dirname -- "$rex_init")"
systemd_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

install -Dm755 rex-lazarus "$HOME/.local/bin/rex-lazarus"
install -Dm644 -t "$systemd_dir" systemd/rex-lazarus-save.service systemd/rex-lazarus-save.timer
install -Dm644 rex_lazarus.lua "$rex_dir/rex_lazarus.lua"

line='require("rex_lazarus")'
if ! grep -qxF "$line" "$rex_init" 2>/dev/null; then
  printf '%s\n' "$line" >> "$rex_init"
fi

systemctl --user daemon-reload
systemctl --user enable --now rex-lazarus-save.timer
