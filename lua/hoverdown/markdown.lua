local M = {}

function M.is_rule(line)
	return line and line:find("^%s*[%*%-_][%*%-_][%*%-_]+%s*$")
end

function M.is_code_block(line)
	return line and line:find("^%s*```")
end

function M.is_empty(line)
	return line and line:find("^%s*$")
end

---@param text string
function M.html_entities(text)
	local entities = {
		nbsp = "",
		lt = "<",
		gt = ">",
		amp = "&",
		quot = '"',
		apos = "'",
		ensp = " ",
		emsp = " ",
	}

	for entity, char in pairs(entities) do
		text = text:gsub("&" .. entity .. ";", char)
	end

	return text
end

---@param ft string
---@param text string
function M.parse(ft, text)
	text = text:gsub("</?pre>", "```"):gsub("\r", "")
	text = M.html_entities(text)

	local ret = {}
	local lines = vim.split(text, "\n")
	local line_idx = 1

	local function eat_nl()
		while M.is_empty(lines[line_idx + 1]) do
			line_idx = line_idx + 1
		end
	end

	while line_idx <= #lines do
		local line = lines[line_idx]

		if M.is_empty(line) then
			local is_start = line_idx == 1
			eat_nl()
			local is_end = line_idx == #lines

			if
				not (
					M.is_code_block(lines[line_idx + 1])
					or M.is_rule(lines[line_idx + 1])
					or is_start
					or is_end
				)
			then
				table.insert(ret, { line = "" })
			end
		elseif M.is_code_block(line) then
			local lang = line:match("```(%S+)") or ft or "text"
			local block = { lang = lang, code = {} }

			while lines[line_idx + 1] and not M.is_code_block(lines[line_idx + 1]) do
				table.insert(block.code, lines[line_idx + 1])
				line_idx = line_idx + 1
			end

			local prev = ret[#ret]
			if prev and not M.is_rule(prev.line) then
				table.insert(ret, { line = "" })
			end

			table.insert(ret, block)
			line_idx = line_idx + 1
			eat_nl()
		elseif M.is_rule(line) then
			table.insert(ret, { line = "---" })
			eat_nl()
		else
			local prev = ret[#ret]
			if prev and prev.code then
				table.insert(ret, { line = "" })
			end
			table.insert(ret, { line = line })
		end

		line_idx = line_idx + 1
	end

	return ret
end

--- @param ft string
--- @param text string
M.format = function(ft, text)
	local parsed = M.parse(ft, text)
	local ret = {}

	for _, block in ipairs(parsed) do
		if block.code then
			table.insert(ret, "```" .. block.lang)

			for _, line in ipairs(block.code) do
				table.insert(ret, line)
			end

			table.insert(ret, "```")
		else
			table.insert(ret, block.line)
		end
	end

	return ret
end

return M
