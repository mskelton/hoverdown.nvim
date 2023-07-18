local config = require("hoverdown.config")

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

---@param text any
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

---@param kind any
---@param text any
function M.parse(kind, text)
	-- local text = vim.lsp.util.convert_input_to_markdown_lines(contents)
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
				table.insert(ret, { type = "line", value = "" })
			end
		elseif M.is_code_block(line) then
			local lang = line:match("```(%S+)") or kind or "text"
			local block = {
				type = "code_block",
				lang = lang,
				code = {},
			}

			while lines[line_idx + 1] and not M.is_code_block(lines[line_idx + 1]) do
				table.insert(block.code, lines[line_idx + 1])
				line_idx = line_idx + 1
			end

			local prev = ret[#ret]
			if prev and not M.is_rule(prev.value) then
				table.insert(ret, { type = "line", value = "" })
			end

			table.insert(ret, block)
			line_idx = line_idx + 1
			eat_nl()
		elseif M.is_rule(line) then
			table.insert(ret, { type = "line", value = "---" })
			eat_nl()
		else
			local prev = ret[#ret]
			if prev and prev.code then
				table.insert(ret, { type = "line", value = "" })
			end
			table.insert(ret, { type = "line", value = line })
		end

		line_idx = line_idx + 1
	end

	return ret
end

--- @param contents any
M.format = function(contents)
	if type(contents) ~= "table" or not vim.tbl_islist(contents) then
		contents = { contents }
	end

	local parts = {}

	for _, content in ipairs(contents) do
		if type(content) == "string" then
			table.insert(parts, content)
		elseif content.language then
			local lang = content.language
			table.insert(parts, ("```%s\n%s\n```"):format(lang, content.value))
		elseif content.kind == "markdown" then
			table.insert(parts, content.value)
		elseif content.kind == "plaintext" then
			table.insert(parts, ("```\n%s\n```"):format(content.value))
		elseif vim.tbl_islist(content) then
			vim.list_extend(parts, M.format(content))
		else
			error("Unknown markup " .. vim.inspect(content))
		end
	end

	return vim.split(table.concat(parts, "\n"), "\n")
end

return M
