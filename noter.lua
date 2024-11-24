VERSION = "0.1.0"
PLUGIN = "noter"

local micro = import("micro")
local config = import("micro/config")
local os = import("os")
local buffer = import("micro/buffer")

function init()
  -- by default, don't open link in new tab
  config.RegisterGlobalOption(PLUGIN, "openinnewtab", false)
  config.MakeCommand("wikilink", wikilink, config.NoComplete)
end

-- log text inside of a [[testy]] at the cursor [[README]]
function wikilink(bp)
  local linktext = link_under_cursor(bp)
  if not linktext then return end

  -- TODO this probably won't work on windows
  local current_dir = bp.Buf.Path:match("^(.-)/[^/]+$")
  local path
  if not current_dir then path = linktext..".md"
    else path = current_dir.."/"..linktext..".md" 
  end
  -- NOTE assume link is to a markdown file
  
  bp:Save() -- save before opening
  
  -- try to open a buffer
  local _, filenotfound = os.Stat(path)
  if filenotfound then -- prompt to create new note
    micro.InfoBar():YNPrompt("Create note "..path.."? (y,n,esc) ", 
      new_note(path))
  else
    open_note(path)
  end
end

-- returns a callback function that creates a new note at the path
function new_note(path)
  micro.InfoBar():Reset()
  return (function(y, esc)
    if esc or (not y) then return else open_note(path) end
  end)
end

-- opens note at path
function open_note(path)
  local bp = micro.CurPane()
  local b, err = buffer.NewBufferFromFile(path)
  
  if config.GetGlobalOption(PLUGIN..".openinnewtab") then 
    bp:AddTab()
    bp:NextTab()
  end
  
  if not err then micro.CurPane():OpenBuffer(b) end
  micro.InfoBar():Message("Opened note "..path)
end

-- get the inner text of the [[wikilink]] at the cursor's position as a string
-- inner text will be trimmed of leading/trailing whitespace
-- if cursor is not on a wikilink, or the wikilink is empty, returns nil
function link_under_cursor(bp)
  local line = bp.Buf:Line(bp.Cursor.Loc.Y) -- get line cursor is on
  if not line then return nil end -- return nil if empty line
  local index = bp.Cursor.Loc.X -- get cursor position in line

  -- nearest opening brackets before or at index
  local opening_start, opening_end
  for start, finish in line:gmatch("()%[%[()") do
    if start <= index then opening_start, opening_end = start, finish 
      else break
    end
  end
  if not opening_start then return nil end

  -- nearest closing brackets after the index
  local closing_start, closing_end = line:find("%]%]", opening_end)
  if not closing_start or closing_start < index then return nil end

  -- grab the content between the brackets
  local text = line:sub(opening_end, closing_start - 1)
  return (text:match("^%s*(.-)%s*$")) -- trims leading/trailing whitespace
end
