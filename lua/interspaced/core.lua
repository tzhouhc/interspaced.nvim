---@class CoreModule
---@field remove fun(start_line: integer, start_col: integer, end_line: integer, end_col: integer): boolean, string?
---@field insert fun(line: integer, col: integer, text: string): boolean, string?
local M = {}

---@class SpacingContext
---@field before_text string
---@field after_text string
---@field removed_text string
---@field inserted_text string

---@class SpacingRules
---@field aggressive_spacing boolean Whether to always ensure single spaces
---@field preserve_tabs boolean Whether to preserve tab characters
---@field max_operation_size integer Maximum text size for automatic spacing
---@field timeout_ms integer Operation timeout in milliseconds
---@field no_space_after table List of punctuation that should not have space after
---@field no_space_before table List of punctuation that should not have space before
---@field always_space_after table List of punctuation that should always have space after
---@field always_space_before table List of punctuation that should always have space before

---@type SpacingRules
M.default_rules = {
  aggressive_spacing = true,
  preserve_tabs = false,
  max_operation_size = 100 * 1024, -- 100KB
  timeout_ms = 100,
  no_space_after = { ",", ".", "!", "?", ";", ":", ")", "]", "}", "'", '"', "-", "_" },
  no_space_before = { ",", ".", "!", "?", ";", ":", "(", "[", "{", "'", '"', "-", "_" },
  always_space_after = { "(", "[", "{" },
  always_space_before = { ")", "]", "}" },
}

---Remove text in the specified range and adjust spacing
---@param start_line integer Starting line number (1-indexed)
---@param start_col integer Starting column number (0-indexed)
---@param end_line integer Ending line number (1-indexed)
---@param end_col integer Ending column number (0-indexed)
---@return boolean success True if operation succeeded
---@return string? error Error message if operation failed
function M.remove(start_line, start_col, end_line, end_col)
  -- Validate input
  if start_line < 1 or end_line < 1 then
    return false, "Invalid line number"
  end

  if start_col < 0 or end_col < 0 then
    return false, "Invalid column number"
  end

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    return false, "Start position must be before end position"
  end

  -- Get the text to be removed
  local removed_text, err = M._get_text_range(start_line, start_col, end_line, end_col)
  if err then
    return false, "Failed to get text range: " .. err
  end

  -- Get text before and after the removal range
  local before_text, before_err = M._get_text_range(start_line, 0, start_line, start_col)
  if before_err then
    return false, "Failed to get text before range: " .. before_err
  end

  local after_text, after_err
  if start_line == end_line then
    -- Same line, get text after on same line
    local line_text = vim.api.nvim_buf_get_lines(0, end_line - 1, end_line, false)[1] or ""
    after_text = line_text:sub(end_col + 1)
  else
    -- Different lines, get text from end line
    after_text, after_err = M._get_text_range(end_line, end_col, end_line, -1)
    if after_err then
      return false, "Failed to get text after range: " .. after_err
    end
  end

  -- Normalize spacing
  local normalized_before, normalized_after, needs_space =
    M._normalize_spacing(before_text, after_text, removed_text, nil)

  -- Construct new text with appropriate spacing
  local new_text
  if needs_space and normalized_before ~= "" and normalized_after ~= "" then
    new_text = normalized_before .. " " .. normalized_after
  else
    new_text = normalized_before .. normalized_after
  end

  -- Calculate new range for replacement
  local replacement_start_line = start_line
  local replacement_start_col = 0
  local replacement_end_line = end_line
  local replacement_end_col = -1

  if start_line == end_line then
    -- Single line replacement
    replacement_end_col = -1 -- To end of line
  end

  -- Replace the text
  local success = pcall(function()
    vim.api.nvim_buf_set_text(
      0,
      replacement_start_line - 1,
      replacement_start_col,
      replacement_end_line - 1,
      replacement_end_col,
      { new_text }
    )
  end)

  if not success then
    return false, "Failed to replace text in buffer"
  end

  return true, nil
end

---Insert text at the specified position and adjust spacing
---@param line integer Line number (1-indexed)
---@param col integer Column number (0-indexed)
---@param text string Text to insert
---@return boolean success True if operation succeeded
---@return string? error Error message if operation failed
function M.insert(line, col, text)
  -- Validate input
  if line < 1 then
    return false, "Invalid line number"
  end

  if col < 0 then
    return false, "Invalid column number"
  end

  if text == "" then
    return true, nil -- Nothing to insert
  end

  -- Get text before and after insertion point
  local before_text, before_err = M._get_text_range(line, 0, line, col)
  if before_err then
    return false, "Failed to get text before insertion: " .. before_err
  end

  local after_text, after_err = M._get_text_range(line, col, line, -1)
  if after_err then
    return false, "Failed to get text after insertion: " .. after_err
  end

  -- Normalize spacing with inserted text
  local normalized_before, normalized_after, needs_space = M._normalize_spacing(before_text, after_text, nil, text)

  -- Construct new text with inserted content
  local new_text
  if normalized_before == "" then
    -- Inserting at beginning of line
    new_text = text .. normalized_after
  elseif normalized_after == "" then
    -- Inserting at end of line
    new_text = normalized_before .. text
  else
    -- Inserting in middle of line
    -- We need to decide spacing around the inserted text
    local text_to_insert = text

    -- Check spacing before insertion
    local needs_space_before = needs_space
    local last_before = normalized_before:sub(-1)
    local first_text = text:sub(1, 1)

    -- Override based on specific punctuation rules
    if M._is_punctuation(last_before) and M._is_punctuation(first_text) then
      needs_space_before = false
    elseif M._is_punctuation(last_before) then
      -- Check if this punctuation allows space after
      local no_space_after = { ",", ".", "!", "?", ";", ":", ")", "]", "}", "'", '"', "-", "_" }
      for _, p in ipairs(no_space_after) do
        if last_before == p then
          needs_space_before = false
          break
        end
      end
    end

    -- Check spacing after insertion
    local needs_space_after = needs_space
    local last_text = text:sub(-1)
    local first_after = normalized_after:sub(1, 1)

    -- Override based on specific punctuation rules
    if M._is_punctuation(last_text) and M._is_punctuation(first_after) then
      needs_space_after = false
    elseif M._is_punctuation(first_after) then
      -- Check if this punctuation allows space before
      local no_space_before = { ",", ".", "!", "?", ";", ":", "(", "[", "{", "'", '"', "-", "_" }
      for _, p in ipairs(no_space_before) do
        if first_after == p then
          needs_space_after = false
          break
        end
      end
    end

    -- Apply spacing to inserted text
    if needs_space_before then
      text_to_insert = " " .. text_to_insert
    end
    if needs_space_after then
      text_to_insert = text_to_insert .. " "
    end

    new_text = normalized_before .. text_to_insert .. normalized_after
  end

  -- Replace the line with new text
  local success = pcall(function()
    vim.api.nvim_buf_set_lines(0, line - 1, line, false, { new_text })
  end)

  if not success then
    return false, "Failed to insert text in buffer"
  end

  return true, nil
end

---Analyze spacing context around a text range
---@param start_line integer
---@param start_col integer
---@param end_line integer
---@param end_col integer
---@return SpacingContext? context Spacing context information
---@return string? error Error message if analysis failed
function M._analyze_context(start_line, start_col, end_line, end_col)
  -- TODO: Implement context analysis
  return nil, "Not implemented"
end

---Normalize spacing according to rules
---@param before string Text before the operation
---@param after string Text after the operation
---@param removed string? Text being removed (for removal operations)
---@param inserted string? Text being inserted (for insertion operations)
---@return string normalized_before Normalized text before
---@return string normalized_after Normalized text after
function M._normalize_spacing(before, after, removed, inserted)
  -- Apply space collapsing if enabled
  local before_processed = before
  local after_processed = after

  if M._should_collapse_spaces(before) then
    before_processed = M._collapse_spaces(before)
  end

  if M._should_collapse_spaces(after) then
    after_processed = M._collapse_spaces(after)
  end

  -- Trim whitespace from ends
  local before_trimmed = before_processed:gsub("^%s+", ""):gsub("%s+$", "")
  local after_trimmed = after_processed:gsub("^%s+", ""):gsub("%s+$", "")

  -- Handle empty cases
  if before_trimmed == "" and after_trimmed == "" then
    return "", "", false
  end

  if before_trimmed == "" then
    -- Text at beginning of line
    return "", after_trimmed, false
  end

  if after_trimmed == "" then
    -- Text at end of line
    return before_trimmed, "", false
  end

  -- Determine if we need space between before_trimmed and after_trimmed
  local needs_space = true

  -- Check last character of before
  local last_before = before_trimmed:sub(-1)
  local first_after = after_trimmed:sub(1, 1)

  -- Apply spacing rules
  local rules = M.default_rules

  -- Check if we should always have space after last_before
  for _, p in ipairs(rules.always_space_after) do
    if last_before == p then
      needs_space = true
      break
    end
  end

  -- Check if we should never have space after last_before
  for _, p in ipairs(rules.no_space_after) do
    if last_before == p then
      needs_space = false
      break
    end
  end

  -- Check if we should always have space before first_after
  for _, p in ipairs(rules.always_space_before) do
    if first_after == p then
      needs_space = true
      break
    end
  end

  -- Check if we should never have space before first_after
  for _, p in ipairs(rules.no_space_before) do
    if first_after == p then
      needs_space = false
      break
    end
  end

  -- Special case: if both are punctuation and neither has explicit rules, default to no space
  if M._is_punctuation(last_before) and M._is_punctuation(first_after) then
    local has_explicit_rule = false
    for _, p in ipairs(rules.always_space_after) do
      if last_before == p then
        has_explicit_rule = true
        break
      end
    end
    for _, p in ipairs(rules.always_space_before) do
      if first_after == p then
        has_explicit_rule = true
        break
      end
    end

    if not has_explicit_rule then
      needs_space = false
    end
  end

  -- For removal: if removed text had spaces, we need to ensure proper spacing
  if removed then
    local removed_trimmed = removed:gsub("^%s+", ""):gsub("%s+$", "")
    if removed_trimmed ~= removed then
      -- Removed text had surrounding whitespace, need to ensure spacing
      needs_space = true
    end
  end

  -- For insertion: consider the inserted text's boundaries
  if inserted then
    local inserted_trimmed = inserted:gsub("^%s+", ""):gsub("%s+$", "")
    if inserted_trimmed ~= inserted then
      -- Inserted text has surrounding whitespace in the input
      -- This might affect spacing decisions
    end

    local first_inserted = inserted_trimmed:sub(1, 1)
    local last_inserted = inserted_trimmed:sub(-1)

    -- If inserted text starts with punctuation, no space before it
    if M._is_punctuation(first_inserted) then
      -- But we're not inserting here, we're deciding spacing between before and after
      -- This affects whether we need space between before and the insertion point
    end

    -- If inserted text ends with punctuation, no space after it
    if M._is_punctuation(last_inserted) then
      -- This affects whether we need space between insertion point and after
    end
  end

  -- Return texts with appropriate spacing indicator
  -- The caller needs to handle the actual spacing based on this flag
  return before_trimmed, after_trimmed, needs_space
end

---Check if a character is punctuation
---@param char string Single character
---@return boolean
function M._is_punctuation(char)
  local punctuation = {
    ",",
    ".",
    "!",
    "?",
    ";",
    ":",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    "'",
    '"',
    "-",
    "_",
    "`",
    "~",
    "@",
    "#",
    "$",
    "%",
    "^",
    "&",
    "*",
    "+",
    "=",
    "|",
    "\\",
    "/",
    "<",
    ">",
  }
  for _, p in ipairs(punctuation) do
    if char == p then
      return true
    end
  end
  return false
end

---Check if a character is whitespace
---@param char string Single character
---@return boolean
function M._is_whitespace(char)
  return char == " " or char == "\t" or char == "\n" or char == "\r"
end

---Collapse multiple consecutive spaces to single spaces
---@param text string Input text
---@return string Collapsed text
function M._collapse_spaces(text)
  -- Collapse multiple spaces to single space
  local collapsed = text:gsub("%s+", " ")
  -- Remove leading/trailing spaces
  collapsed = collapsed:gsub("^%s+", ""):gsub("%s+$", "")
  return collapsed
end

---Check if text should have spaces collapsed based on rules
---@param text string
---@return boolean
function M._should_collapse_spaces(text)
  return M.default_rules.aggressive_spacing
end

---Get text from buffer range
---@param start_line integer
---@param start_col integer
---@param end_line integer
---@param end_col integer
---@return string? text
---@return string? error
function M._get_text_range(start_line, start_col, end_line, end_col)
  if start_line < 1 or end_line < 1 then
    return nil, "Invalid line number"
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil, "No text in range"
  end

  if start_line == end_line then
    -- Single line range
    local line = lines[1]
    if start_col < 0 then
      start_col = 0
    end
    if end_col < 0 then
      end_col = #line
    end
    if start_col > #line or end_col > #line then
      return nil, "Column out of bounds"
    end
    return line:sub(start_col + 1, end_col), nil
  else
    -- Multi-line range
    local result = {}
    for i, line in ipairs(lines) do
      if i == 1 then
        -- First line: from start_col to end
        if start_col < 0 then
          start_col = 0
        end
        if start_col > #line then
          return nil, "Start column out of bounds"
        end
        table.insert(result, line:sub(start_col + 1))
      elseif i == #lines then
        -- Last line: from beginning to end_col
        if end_col < 0 then
          end_col = #line
        end
        if end_col > #line then
          return nil, "End column out of bounds"
        end
        table.insert(result, line:sub(1, end_col))
      else
        -- Middle lines: entire line
        table.insert(result, line)
      end
    end
    return table.concat(result, "\n"), nil
  end
end

---Get surrounding text context
---@param line integer
---@param col integer
---@param before_len integer Number of characters to get before position
---@param after_len integer Number of characters to get after position
---@return string? before
---@return string? after
---@return string? error
function M._get_surrounding_text(line, col, before_len, after_len)
  if line < 1 then
    return nil, nil, "Invalid line number"
  end

  local lines = vim.api.nvim_buf_get_lines(0, line - 1, line, false)
  if #lines == 0 then
    return nil, nil, "Line not found"
  end

  local line_text = lines[1]
  local start_pos = math.max(0, col - before_len)
  local end_pos = math.min(#line_text, col + after_len)

  local before = line_text:sub(start_pos + 1, col)
  local after = line_text:sub(col + 1, end_pos)

  return before, after, nil
end

return M
