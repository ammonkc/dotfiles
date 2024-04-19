-- local function modToPrefix(mods, cmdKey, prefixKey)
-- 	return hs.hotkey.bind(mods, cmdKey, function()
-- 		hs.eventtap.keyStroke({ "ctrl" }, "b", 0)
-- 		hs.eventtap.keyStrokes(prefixKey)
-- 	end)
-- end
--
-- local function cmdToPrefix(cmdKey, prefixKey)
-- 	return modToPrefix({ "cmd" }, cmdKey, prefixKey)
-- end
--
-- local function cmdShiftToPrefix(cmdKey, prefixKey)
-- 	return modToPrefix({ "cmd", "shift" }, cmdKey, prefixKey)
-- end

-- - { chars: "\x02\x5b\x2f", key: F, mods: Command|Shift } # start tmux search mode
-- - { chars: "lfcd\n", key: F, mods: Command } # open file manager 'gokcehan/lf'
-- - { chars: "\x02\x54", key: J, mods: Command } # open t - tmux smart session manager
-- - { chars: "clear\n", key: K, mods: Command|Shift } # open interactive tmux session client
-- - { chars: "\x0f", key: LBracket, mods: Command } # navigate back (ctrl+o)
-- - { chars: "\x02p", key: LBracket, mods: Command|Shift } # switch to next tmux window
-- - { chars: ":GoToFile\n", key: P, mods: Command } # files
-- - { chars: ":GoToCommand\n", key: P, mods: Command|Shift } # commands
-- - { key: Period, mods: Command, chars: "\x1b\x20\x2e\x0a" } (causes popup to be unfocused)
-- - { chars: ":q\n", key: Q, mods: Command } # quit vim
-- - { chars: "\x1b\x5b\x41\x0a", key: R, mods: Command }
-- - { chars: "^R", key: R, mods: Command|Shift }
-- - { chars: "\x09", key: RBracket, mods: Command }
-- - { chars: "\x1b\x3a\x77\x0a", key: S, mods: Command } # save vim buffer
-- - { chars: ":wa\n", key: S, mods: Command|Shift } # save all

-- local tmuxBindings = {
-- 	cmdShiftToPrefix("[", "p"),
-- 	cmdShiftToPrefix("]", "n"),
-- 	cmdShiftToPrefix("e", "%"),
-- 	cmdToPrefix(";", ":"),
-- 	cmdToPrefix("e", "\\"),
-- 	cmdToPrefix("g", "g"),
-- 	cmdToPrefix("j", "T"),
-- 	cmdToPrefix("k", "s"),
-- 	cmdToPrefix("l", "L"),
-- 	cmdToPrefix("o", "u"),
-- 	cmdToPrefix("t", "c"),
-- 	cmdToPrefix("w", "x"),
-- 	cmdToPrefix("z", "z"),
-- }
--
-- for i = 1, 9 do
-- 	table.insert(tmuxBindings, cmdToPrefix(i, i))
-- end
--
-- local terminal = hs.window.filter.new("terminal")
--
-- terminal
-- 	:subscribe(hs.window.filter.windowFocused, function()
-- 		for _, cmd in ipairs(tmuxBindings) do
-- 			cmd:enable()
-- 		end
-- 	end)
-- 	:subscribe(hs.window.filter.windowUnfocused, function()
-- 		for _, cmd in ipairs(tmuxBindings) do
-- 			cmd:disable()
-- 		end
-- 	end)