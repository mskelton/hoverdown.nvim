local markdown = require("hoverdown.markdown")

local M = {}

local function on_hover(_, result, _, config)
	local silent = config and config.silent

	if not (result and result.contents) then
		if silent ~= true then
			vim.notify("No information available")
		end
		return
	end

	local contents = result.contents
	local lines = markdown.format(contents.kind, contents.value)

	if vim.tbl_isempty(lines) then
		if silent ~= true then
			vim.notify("No information available")
		end
		return
	end

	return vim.lsp.util.open_floating_preview(lines, "markdown", config)
end

M.setup = function()
	vim.lsp.handlers["textDocument/hover"] = on_hover
end

return M
