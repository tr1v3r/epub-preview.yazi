-- Offline test for main.lua's preload() wiring: no Yazi, no PyMuPDF, no network.
-- The plugin API is stubbed and the renderer is faked, so this asserts only the
-- contract main.lua itself is responsible for.
--
-- Run from the repository root:  lua test/preload_test.lua

local CACHE = os.tmpname()
os.remove(CACHE)

local seen, mode = {}, "ok"

Url = function(s) return s end
Err = function(fmt, ...) return string.format(fmt, ...) end
rt = { preview = { max_width = 1800, max_height = 2700, image_delay = 0 } }

local cached = false
ya = {
	file_cache = function() return CACHE end,
	image_precache = function(src, dst)
		seen.precache = { src = src, dst = dst }
		return true
	end,
}
fs = { cha = function(p) return (cached and p == CACHE) and {} or nil end }

local Cmd = {}
Cmd.__index = Cmd
function Cmd:arg(a) self.args = a; return self end
function Cmd:output()
	seen.cmd, seen.args = self.path, self.args
	if mode == "fail" then
		return { status = { success = false }, stdout = "", stderr = "boom\n" }, nil
	end
	local f = assert(io.open(self.args[3], "w"))
	f:write("fake png")
	f:close()
	return { status = { success = true }, stdout = "", stderr = "" }, nil
end
Command = function(p) return setmetatable({ path = p }, Cmd) end

local M = dofile("main.lua")

local failed = 0
local function check(label, cond)
	print((cond and "ok   " or "FAIL ") .. label)
	if not cond then failed = failed + 1 end
end

local job = { file = { path = "/books/mythical.epub", url = "/books/mythical.epub" } }

-- 1. cold render goes through `sh`, because `ya pkg` seals files read-only and
--    an executable bit would not survive installation.
local ok, err = M:preload(job)
check("cold preload succeeds", ok == true and err == nil)
check("runs through `sh`", seen.cmd == "sh")
check("passes the renderer path", seen.args[1] == M:renderer())
check("passes the book path", seen.args[2] == "/books/mythical.epub")
check("passes the png destination", seen.args[3] == CACHE .. ".png")
check("passes the pixel budget", seen.args[4] == "1800")
check("precaches into Yazi's cache path", seen.precache.dst == CACHE and seen.precache.src == CACHE .. ".png")

-- 2. A cached page must not spawn the renderer again.
cached, seen.cmd = true, nil
local ok2 = M:preload(job)
check("warm cache short-circuits", ok2 == true and seen.cmd == nil)

-- 3. Failures surface the renderer's stderr instead of a traceback.
cached, mode, seen.precache = false, "fail", nil
local ok3, err3 = M:preload(job)
check("failure is reported", ok3 == true and type(err3) == "string")
check("failure carries stderr", err3 ~= nil and err3:find("boom", 1, true) ~= nil)
check("failure precaches nothing", seen.precache == nil)

-- 4. setup() overrides, and the default still points into the plugin directory.
M:setup({ renderer = "/custom/render.sh", size = 512 })
check("setup overrides the renderer", M:renderer() == "/custom/render.sh")
check("setup overrides the size", M:size() == 512)
M:setup({})
check("default renderer is inside the plugin dir",
	M:renderer():find("/plugins/epub-preview.yazi/assets/render.sh", 1, true) ~= nil)
check("default size follows the preview pane", M:size() == 1800)

os.remove(CACHE .. ".png")
os.remove(CACHE)

if failed > 0 then
	print(("\n%d check(s) failed"):format(failed))
	os.exit(1)
end
print("\nall checks passed")
