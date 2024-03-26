local list = require("markdown-todo.list")
local state = require("markdown-todo.state")

local M = {}

M.namespace = vim.api.nvim_create_namespace("render-markdown.nvim")

M.clear = function()
	vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)
end

M.refresh = function()
	if not state.enabled then
		return
	end
	if not vim.tbl_contains(state.config.file_types, vim.bo.filetype) then
		return
	end
	M.clear()
	if not vim.tbl_contains(state.config.render_modes, vim.fn.mode()) then
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

M.markdown = function(root)
	local highlights = state.config.highlights
	for id, node in state.markdown_query:iter_captures(root, 0) do
		local capture = state.markdown_query.captures[id]
		local value = vim.treesitter.get_node_text(node, 0)
		local start_row, start_col, end_row, end_col = node:range()
		if capture == "heading" then
			local level = #value
			local heading = list.cycle(state.config.headings, level)
			local background = list.clamp_last(highlights.heading.backgrounds, level)
			local foreground = list.clamp_last(highlights.heading.foregrounds, level)
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
			local virt_text = { string.rep(" ", leading_spaces or 0) .. state.config.bullet, highlights.bullet }
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				virt_text = { virt_text },
				virt_text_pos = "overlay",
			})
		elseif capture == "quote_marker" then
			local virt_text = { value:gsub(">", state.config.quote), highlights.quote }
			vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				virt_text = { virt_text },
				virt_text_pos = "overlay",
			})
		elseif vim.tbl_contains({ "table_head", "table_delim", "table_row" }, capture) then
			local row = value:gsub("|", "│")
			if capture == "table_delim" then
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

M.latex = function(root)
	if vim.fn.executable("latex2text") ~= 1 then
		return
	end
	local latex = vim.treesitter.get_node_text(root, 0)
	local raw_expression = vim.fn.system("latex2text", latex)
	local expressions = vim.split(vim.trim(raw_expression), "\n", { plain = true })
	local start_row, start_col, end_row, end_col = root:range()
	local virt_lines = vim.tbl_map(function(expression)
		return { { vim.trim(expression), state.config.highlights.latex } }
	end, expressions)
	vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
		end_row = end_row,
		end_col = end_col,
		virt_lines = virt_lines,
		virt_lines_above = true,
	})
end

return M
