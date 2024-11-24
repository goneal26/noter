VERSION = "1.0.0"
PLUGIN = "noter"

local micro = import("micro")
local config = import("micro/config")
local os = import("os")
local buffer = import("micro/buffer")

function init()
  -- by default, don't open link in new tab
  config.RegisterGlobalOption(PLUGIN, "openinnewtab", false)

  -- by default, these commands can only be used in markdown files
  config.RegisterGlobalOption(PLUGIN, "markdownonly", true)

  -- registering commands
  config.MakeCommand("wikilink", wikilink, config.NoComplete)

  -- tries binding to Alt-o by default (TODO support for double-click?)
  local _, err = config.TryBindKey("Alt-o", "command:wikilink", false)
  if err then micro.InfoBar():Error(PLUGIN..": "..err) end

  -- adding help files
  config.AddRuntimeFile(PLUGIN, config.RTHelp, "help/noter.md")
end

-- open wikilink command logic
function wikilink(bp)
  -- check markdown only setting
  if (bp.Settings["filetype"] ~= "markdown") and 
    (config.GetGlobalOption(PLUGIN..".markdownonly")) then return
  end

  -- get wikilink text
  local linktext = link_under_cursor()
  if not linktext then 
    micro.InfoBar():Message(PLUGIN..": No wikilink under cursor")
    return 
  end

  -- determine filepath based on wikilink text
  -- TODO this probably won't work on windows
  local current_dir = bp.Buf.Path:match("^(.-)/[^/]+$")
  local path
  if not current_dir then path = linktext..".md"
    else path = current_dir.."/"..linktext..".md" 
  end
  -- NOTE we assume markdown file
  
  bp:Save() -- save current buffer before opening note
  
  -- try to open a new buffer
  local _, filenotfound = os.Stat(path)
  if filenotfound then -- prompt to create new note
    local msg = PLUGIN..": Create "..path.."? (y,n,esc) "
    micro.InfoBar():YNPrompt(msg, new_note(path))
  else open_note(path) end
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
  local b, err = buffer.NewBufferFromFile(path)
  
  if config.GetGlobalOption(PLUGIN..".openinnewtab") then 
    micro.CurPane():AddTab()
    micro.CurPane():NextTab()
  end

  if err then 
    micro.InfoBar():Error(PLUGIN..": "..err)
    return
  end

  micro.CurPane():OpenBuffer(b)
  micro.InfoBar():Message(PLUGIN..": Opened note "..path)
end

-- get the inner text of the [[wikilink]] at the cursor's position as a string
-- inner text will be trimmed of leading/trailing whitespace
-- if cursor is not on a wikilink, or the wikilink is empty, returns nil
function link_under_cursor()
  local bp = micro.CurPane()
  
  local line = bp.Buf:Line(bp.Cursor.Loc.Y)
  if not line then return nil end
  
  local index = bp.Cursor.Loc.X

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
