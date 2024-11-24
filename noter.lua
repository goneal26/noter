VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")
local buffer = import("micro/buffer")

function init()
  config.MakeCommand("tt", wikilink_text, config.NoComplete)
  config.TryBindKey("Alt-y", "command:tt", false)
end

-- log text inside of a [[wikilink]] at the cursor 
function wikilink_text(bp)
  bp:Save() -- is this needed?
  
  local line = bp.Buf:Line(bp.Cursor.Loc.Y) -- get line as string
  if line == "" or line == nil then return nil end

  local link_text = extract_path(line, bp.Cursor.Loc.X)

  -- TODO just log it for now, later open file at that path
  if not link_text or link_text == "" then 
    micro.InfoBar():Message("got: nil")
  else 
    micro.InfoBar():Message("got: <"..link_text..">")
  end
end

-- given a string (line in file) get the inner text of the [[wikilink]] at index
-- inner text will be trimmed of leading/trailing whitespace
-- if not a wikilink or no inner text, returns nil
function extract_path(line, index)
  -- nearest opening brackets before or at index
  local opening_start, opening_end
  for start, finish in line:gmatch("()%[%[()") do
    if start <= index then
      opening_start, opening_end = start, finish
    else
      break
    end
  end

  -- return nil if no opening brackets found before index
  if not opening_start then return nil end

  -- nearest closing brackets after the index
  local closing_start, closing_end = line:find("%]%]", opening_end)

  -- return nil if no closing brackets found after index
  if not closing_start or closing_start < index then return nil end

  -- return the content between the brackets
  local path = line:sub(opening_end, closing_start - 1)
  return (path:match("^%s*(.-)%s*$")) -- trims leading and trailing whitespace
end
