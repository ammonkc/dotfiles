#!/bin/bash
# scripts/nvim-treesitter-update.lua must reinstall parsers whose install was cut short before
# update() runs, because update() raises an error for every installed language that has no
# parser-info/<lang>.revision file. Uses a real Neovim with stubbed nvim-treesitter modules.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v nvim >/dev/null 2>&1; then
  printf 'Neovim not installed; skipping the treesitter update check.\n'
  exit 0
fi
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

cat > "$scratch/driver.lua" <<LUA
local site = arg[1]
local calls = {}
package.preload["nvim-treesitter.config"] = function()
  return {
    get_install_dir = function(name)
      local dir = site .. "/" .. name
      vim.fn.mkdir(dir, "p")
      return dir
    end,
    -- Same shape as the real one: names from queries/ as they are, names from parser/ without extension.
    get_installed = function()
      local seen, out = {}, {}
      for f in vim.fs.dir(site .. "/queries") do
        if not seen[f] then seen[f] = true; out[#out + 1] = f end
      end
      for f in vim.fs.dir(site .. "/parser") do
        local name = vim.fn.fnamemodify(f, ":r")
        if not seen[name] then seen[name] = true; out[#out + 1] = name end
      end
      return out
    end,
  }
end
package.preload["nvim-treesitter.parsers"] = function()
  local info = { install_info = { revision = "abc", url = "https://example.invalid" } }
  -- ecma only ships queries shared by other languages, so it has no install_info.
  return { lua = info, json = info, typescript = info, ecma = {} }
end
local function task() return { wait = function() end } end
package.preload["nvim-treesitter"] = function()
  return {
    install = function(langs, opts)
      table.sort(langs)
      calls[#calls + 1] = "install:" .. table.concat(langs, ",") .. (opts and opts.force and ":force" or "")
      return task()
    end,
    update = function()
      calls[#calls + 1] = "update"
      return task()
    end,
  }
end
dofile("$root/scripts/nvim-treesitter-update.lua")
io.stdout:write(table.concat(calls, " "))
LUA

fixture() {
  rm -rf "$scratch/site"
  mkdir -p "$scratch/site/parser" "$scratch/site/parser-info" "$scratch/site/queries/lua" "$scratch/site/queries/ecma"
  : > "$scratch/site/parser/lua.so"
  printf 'abc' > "$scratch/site/parser-info/lua.revision"
}
run() {
  nvim --headless -u NONE -l "$scratch/driver.lua" "$scratch/site" 2>&1 | tail -n 1
}

# Everything installed completely: nothing is reinstalled, update still runs.
fixture
test "$(run)" = "update"
test -e "$scratch/site/parser/lua.so"

# json has its .so but no revision (interrupted after the library was copied), and typescript has
# only queries (interrupted before the parser was). Both are removed and reinstalled before update.
fixture
: > "$scratch/site/parser/json.so"
mkdir -p "$scratch/site/queries/json" "$scratch/site/queries/typescript"
test "$(run)" = "install:json,typescript:force update"
test ! -e "$scratch/site/parser/json.so"
test ! -e "$scratch/site/queries/typescript"

# Completed parsers and the queries-only language are left alone.
test -e "$scratch/site/parser/lua.so"
test -e "$scratch/site/parser-info/lua.revision"
test -d "$scratch/site/queries/lua"
test -d "$scratch/site/queries/ecma"

printf 'Interrupted treesitter parsers are reinstalled before update.\n'
