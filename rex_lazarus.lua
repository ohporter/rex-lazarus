-- SPDX-License-Identifier: MIT
-- rex-lazarus: start the recorded programs again in their panes when the Rex server starts.
-- init.lua loads this file with require("rex_lazarus"). Rex runs init.lua again on
-- "rex config reload"; rex-lazarus restore finds that case and does nothing.

local home = os.getenv("HOME")
if not home then
  io.stderr:write("rex-lazarus: HOME is not set, restore not started\n")
  return
end

local r, err = rex.exec({ home .. "/.local/bin/rex-lazarus", "restore", "--background" })
if r == nil then
  io.stderr:write("rex-lazarus: restore not started: " .. tostring(err) .. "\n")
elseif not r.ok then
  io.stderr:write("rex-lazarus: restore failed: " .. (r.stderr or "") .. "\n")
end
