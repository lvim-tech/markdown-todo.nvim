local config = require("markdown-todo.config")

local M = {}

M.namespace = vim.api.nvim_create_namespace("LvimMarkdownUtilsStyle")

M.init = function()
	config.style.enabled = true
	config.style.md_query = vim.treesitter.query.parse("markdown", config.style.markdown_query)

	vim.schedule(M.refresh)

	vim.api.nvim_create_autocmd({
		"FileChangedShellPost",
		"ModeChanged",
		"Syntax",
		"TextChanged",
		"WinResized",
	}, {
		group = vim.api.nvim_create_augroup("LvimMarkdownUtilsRender", { clear = true }),
		callback = function()
			vim.schedule(M.refresh)
		end,
	})

	vim.api.nvim_create_user_command(
		"LvimMarkdownUtilsToggle",
		M.toggle,
		{ desc = "Switch between enabling & disabling render markdown plugin" }
	)
end

M.toggle = function()
	if config.style.enabled then
		config.style.enabled = false
		vim.schedule(M.clear)
	else
		config.style.enabled = true
		vim.schedule(M.refresh)
	end
end

M.refresh = function()
	if not config.style.enabled then
		return
	end
	if not vim.tbl_contains(config.style.file_types, vim.bo.filetype) then
		return
	end
	M.clear()
	if not vim.tbl_contains(config.style.render_modes, vim.fn.mode()) then
		return
	end
	vim.treesitter.get_parser():for_each_tree(function(tree, language_tree)
		local language = language_tree:lang()
		if language == "markdown" then
			M.markdown(tree:root())
		elseif language == "latex" then
			M.latex(tree:root())
		end
	end)
end

M.clear = function()
	vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)
end

M.markdown = function(root)
	local highlights = config.style.highlights
	for id, node in config.style.md_query:iter_captures(root, 0) do
		local capture = config.style.md_query.captures[id]
		local value = vim.treesitter.get_node_text(node, 0)
		local start_row, start_col, end_row, end_col = node:range()
		if capture == "heading" then
			local level = #value
			local heading = M.cycle(config.style.headings, level)
			local background = M.clamp_last(highlights.heading.backgrounds, level)
			local foreground = M.clamp_last(highlights.heading.foregrounds, level)
			local virt_text = { string.rep(" ", level - 1) .. heading, { foreground, background } }
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, 0, {
				end_row = end_row + 1,
				end_col = 0,
				hl_group = background,
				virt_text = { virt_text },
				virt_text_pos = "overlay",
				hl_eol = true,
			})
		elseif capture == "code" then
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, 0, {
				end_row = end_row,
				end_col = 0,
				hl_group = highlights.code,
				hl_eol = true,
			})
		elseif capture == "list_marker" then
			local _, leading_spaces = value:find("^%s*")
			local virt_text = { string.rep(" ", leading_spaces or 0) .. config.style.bullet, highlights.bullet }
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				virt_text = { virt_text },
				virt_text_pos = "overlay",
			})
		elseif capture == "quote_marker" then
			local virt_text = { value:gsub(">", config.style.quote), highlights.quote }
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				virt_text = { virt_text },
				virt_text_pos = "overlay",
			})
		elseif vim.tbl_contains({ "table_head", "table_delim", "table_row" }, capture) then
			local row = value:gsub("|", "│")
			if capture == "table_delim" then
				-- Order matters here, in particular handling inner intersections before left & right
				row = row:gsub("-", "─")
					:gsub(" ", "─")
					:gsub("─│─", "─┼─")
					:gsub("│─", "├─")
					:gsub("─│", "─┤")
			end
			local highlight = highlights.table.head
			if capture == "table_row" then
				highlight = highlights.table.row
			end
			local virt_text = { row, highlight }
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				virt_text = { virt_text },
				virt_text_pos = "overlay",
			})
		else
			vim.print("Unhandled capture: " .. capture)
		end
	end
end

M.cycle = function(values, index)
	return values[((index - 1) % #values) + 1]
end

M.clamp_last = function(values, index)
	return values[math.min(index, #values)]
end

return M
