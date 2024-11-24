VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local os = import("os")
local buffer = import("micro/buffer")

-- add wikilink command 
function init()
  config.MakeCommand("wikilink", wikilink_text, config.NoComplete)
  config.TryBindKey("Alt-y", "command:wikilink", false)
end

-- log text inside of a [[wikilink]] at the cursor
function wikilink_text(bp)
  local line = bp.Buf:Line(bp.Cursor.Loc.Y) -- get line as string
  if line == "" or line == nil then return nil end -- ignore empty lines

  local innertext = extract_path(line, bp.Cursor.Loc.X)
  
  if not innertext or innertext == "" then 
    micro.InfoBar():Message("got: nil")
  else 
    local current_dir = bp.Buf.Path:match("^(.-)/[^/]+$")
    
    local path
    if not current_dir then path = innertext..".md"
      else path = current_dir.."/"..innertext..".md"
    end
    
    bp:Save()
    try_open(path, bp)
  end
end

-- test with [[README]]
function try_open(filepath, bp)
  local info, err = os.Stat(filepath)
  if os.IsNotExist(err) or info:IsDir() then 
    micro.InfoBar():Message("no file found: " .. filepath)
  else -- file exists, open it
    local buff, err = buffer.NewBufferFromFile(filepath)
    if err then 
      micro.InfoBar():Message("Error opening file")
      return
    else
      bp:OpenBuffer(buff) -- TODO option to open in new tab?
    end
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
