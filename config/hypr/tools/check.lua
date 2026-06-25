-- Smoke-test: load every config module against a universal no-op `hl` stub to
-- catch Lua syntax/load errors before installing. This does NOT validate hl API
-- semantics (that needs a real Hyprland session) -- it only proves the Lua loads.
--
--   luajit tools/check.lua   (or: lua tools/check.lua)

local meta = {}
meta.__index = function() return setmetatable({}, meta) end
meta.__call  = function() return setmetatable({}, meta) end
hl = setmetatable({}, meta)

local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
local root = here .. "../"

local ok, err = pcall(dofile, root .. "hyprland.lua")
if not ok then
    io.stderr:write("FAIL: " .. tostring(err) .. "\n")
    os.exit(1)
end
print("OK: all modules loaded cleanly")
