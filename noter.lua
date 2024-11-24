VERSION = "1.1.0-nightly"
PLUGIN = "noter"

local micro = import("micro")
local config = import("micro/config")
local os = import("os")
local buffer = import("micro/buffer")

-- a stack that holds all of the links the user has gone to 
linkstack = {}
function pushlink(path) table.insert(linkstack, path) end
function poplink()
  if #linkstack <= 0 then return nil 
  else return table.remove(linkstack, #linkstack) end
end

function init() -- [[README]]
  -- by default, don't open link in new tab
  config.RegisterGlobalOption(PLUGIN, "openinnewtab", false)

  -- by default, these commands can only be used in markdown files
  config.RegisterGlobalOption(PLUGIN, "markdownonly", true)

  -- registering commands
  config.MakeCommand("wikilink", wikilink, config.NoComplete)
  config.MakeCommand("back", back, config.NoComplete)

  -- tries binding wikilink Alt-o by default (TODO support for double-click?)
  local _, err = config.TryBindKey("Alt-o", "command:wikilink", false)
  if err then micro.InfoBar():Error(PLUGIN..": "..err) end

  -- tries binding back to Alt-< by default (TODO will probably change)
  local _, err = config.TryBindKey("Alt-<", "command:back", false)
  if err then micro.InfoBar():Error(PLUGIN..": "..err) end

  -- adding help files
  config.AddRuntimeFile(PLUGIN, config.RTHelp, "help/noter.md")
end

-- open wikilink command logic
function wikilink(bp)
  -- check markdown only setting
  if (bp.Buf.Settings["filetype"] ~= "markdown") and 
  (config.GetGlobalOption(PLUGIN..".markdownonly")) then
    micro.InfoBar():Message(PLUGIN..": current filetype not md (see option "..PLUGIN..".markdownonly)")
    return
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
    local msg = PLUGIN..": Create "..path.."? (y,n,esc)"
    micro.InfoBar():YNPrompt(msg, new_note(path))
  else open_note(path) end
end

-- go back to previous note in stack [[nonexistant]]
function back(bp)
  if bp.Buf:Modified() then -- prompt to save?
    local msg = "Save changes to "..bp.Buf.Path.." before going back? (y,n,esc)"
    micro.InfoBar():YNPrompt(msg, save_then_back(bp.Buf))
  else
    go_back()
  end
end

-- return callback, save, then go back
function save_then_back(buff)
  micro.InfoBar():Reset()
  return (function(y, esc)
    if esc then return end
    if y then buff:Save() end
    go_back()
  end)
end

-- logic for going back to previous note TODO
function go_back()
  local prev_path = poplink()
  if not prev_path then
    micro.InfoBar():Error(PLUGIN..": Cannot go back, previous path not found.")
    return
  end
  
  -- TODO rework for better use of tabs
  local b, err = buffer.NewBufferFromFile(prev_path)
  if err then 
    micro.InfoBar():Error(PLUGIN..": "..err)
    return
  end
  
  micro.CurPane():OpenBuffer(b)
  micro.InfoBar():Message(PLUGIN..": returned back to "..prev_path)
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

  -- before opening new note, push current path to linkstack
  local currentpath = micro.CurPane().Buf.Path
  if currentpath then pushlink(currentpath) end

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
