local markdown = require("hoverdown.markdown")
local config = require("hoverdown.config")

local M = {}

local function on_hover(_, result, ctx, options)
	options = options or {}
	options.focus_id = ctx.method

	-- Ignore result since buffer changed. This happens for slow language servers.
	if vim.api.nvim_get_current_buf() ~= ctx.bufnr then
		return
	end

	if not (result and result.contents) then
		if options.silent ~= true then
			vim.notify("No information available")
		end
		return
	end

	local ft = vim.bo[ctx.bufnr].filetype
	local contents = result.contents
	local lines = markdown.format(contents.kind, contents.value, { ft = ft })

	if vim.tbl_isempty(lines) then
		if options.silent ~= true then
			vim.notify("No information available")
		end
		return
	end

	return vim.lsp.util.open_floating_preview(lines, "markdown", options)
end

--- @param conf table
M.setup = function(conf)
	config.load(conf)

	vim.lsp.handlers["textDocument/hover"] = on_hover
end

return M
