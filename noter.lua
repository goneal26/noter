VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")

function init()
  config.MakeCommand("gf", click_link, config.NoComplete)
end

-- test_on_underscores

-- returns the word under the cursor as a string, or empty string
function get_word_under_cursor(bp)
    bp:Save()
    local c = bp.Cursor
    c:SelectWord()
    if c:HasSelection() then
      local word = util.String(c:GetSelection())
      c:Deselect(false)
      return word
    else
      return ""
    end
end

function click_link(bp)
  local word = get_word_under_cursor(bp)
  micro.InfoBar():Message("Got: <" .. word .. ">")
end
