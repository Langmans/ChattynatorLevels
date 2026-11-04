-- Loaded once by busted before the spec files (see .busted). Reads the .toc's file list the way the
-- client does and defines NewClient (tests/wow.lua). busted runs from the repository root.

local sh = require("tests.sh")

-- The addon's own files in load order.
TOC_FILES = {}
for line in sh.read("ChattynatorLevels.toc"):gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$"):gsub("\\", "/")
    if line ~= "" and not line:match("^#") then TOC_FILES[#TOC_FILES + 1] = line end
end

dofile("tests/wow.lua")
