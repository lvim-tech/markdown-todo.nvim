local config = require("markdown-todo.config")

local M = {}

local get_line = function(line_num)
	return vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
end

local delete_line = function(line_num)
	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, true, {})
end

local get_text = function(selection)
	local first_pos, last_pos = selection.first_pos, selection.last_pos
	last_pos[2] = math.min(last_pos[2], #get_line(last_pos[1]))
	return vim.api.nvim_buf_get_text(0, first_pos[1] - 1, first_pos[2] - 1, last_pos[1] - 1, last_pos[2], {})
end

local insert_text = function(pos, text)
	pos[2] = math.min(pos[2], #get_line(pos[1]) + 1)
	vim.api.nvim_buf_set_text(0, pos[1] - 1, pos[2] - 1, pos[1] - 1, pos[2] - 1, text)
end

local change_text = function(selection, text)
	if not selection then
		return
	end
	local first_pos, last_pos = selection.first_pos, selection.last_pos
	vim.api.nvim_buf_set_text(0, first_pos[1] - 1, first_pos[2] - 1, last_pos[1] - 1, last_pos[2], text)
end

local set_curpos = function(pos)
	if not pos then
		return
	end
	vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] - 1 })
end

local get_mark = function(mark)
	local position = vim.api.nvim_buf_get_mark(0, mark)
	return { position[1], position[2] + 1 }
end

local set_mark = function(mark, position)
	if position then
		vim.api.nvim_buf_set_mark(0, mark, position[1], position[2] - 1, {})
	end
end

local get_first_byte = function(pos)
	local byte = string.byte(get_line(pos[1]):sub(pos[2], pos[2]))
	if not byte then
		return pos
	end
	while byte >= 0x80 and byte < 0xc0 do
		pos[2] = pos[2] - 1
		byte = string.byte(get_line(pos[1]):sub(pos[2], pos[2]))
	end
	return pos
end

local get_last_byte = function(pos)
	if not pos then
		return nil
	end
	local byte = string.byte(get_line(pos[1]):sub(pos[2], pos[2]))
	if not byte then
		return pos
	end
	if byte >= 0xf0 then
		pos[2] = pos[2] + 3
	elseif byte >= 0xe0 then
		pos[2] = pos[2] + 2
	elseif byte >= 0xc0 then
		pos[2] = pos[2] + 1
	end
	return pos
end

local parse_arg = function(opts, key, default)
	if opts and opts[key] ~= nil then
		return opts[key]
	else
		return default
	end
end

local inline_surround = function(before, after, opts)
	local s = get_first_byte(get_mark("<"))
	local e = get_last_byte(get_mark(">"))
	if s == nil or e == nil then
		return
	end
	if vim.fn.visualmode() == "V" then
		e[2] = #get_line(e[1])
	end
	local remove = parse_arg(opts, "remove", true)
	local selection = { first_pos = s, last_pos = e }
	local text = get_text(selection)
	local first = text[1]:sub(1, #before) == before
	local last = text[#text]:sub(-#after) == after
	local is_removing = first and last and remove
	local is_sameline = s[1] == e[1]
	if is_removing then
		text[1] = text[1]:sub(#before + 1, -1)
		text[#text] = text[#text]:sub(1, -#after - 1)
		change_text(selection, text)
		if is_sameline then
			e[2] = e[2] - #before - #after
		else
			e[2] = e[2] - #after
		end
	else
		insert_text(s, { before })
		e[2] = e[2] + 1
		if is_sameline then
			e[2] = e[2] + #before
		end
		insert_text(e, { after })
		e[2] = e[2] + #after - 1
	end
	set_mark(">", e)
end

local newline_surround = function(before, after, opts)
	local s = get_first_byte(get_mark("<"))
	local e = get_last_byte(get_mark(">"))
	if s == nil or e == nil then
		return
	end
	if vim.fn.visualmode() == "V" then
		e[2] = #get_line(e[1])
	end
	local remove = parse_arg(opts, "remove", true)
	local selection = { first_pos = s, last_pos = e }
	local text = get_text(selection)
	local first = text[1] == before
	local last = text[#text] == after
	local is_removing = first and last and remove
	if is_removing then
		delete_line(s[1])
		e[1] = e[1] - 1
		delete_line(e[1])
		e[1] = e[1] - 1
		set_mark(">", { e[1], #text[#text - 1] - 1 })
		set_curpos({ e[1], 1 })
	else
		insert_text(s, { before, "" })
		s = { s[1], 1 }
		set_mark("<", s)
		e = { e[1] + 1, e[2] + 1 }
		insert_text(e, { "", after })
		e = { e[1] + 1, #after }
		set_mark(">", e)
		set_curpos({ e[1] - 1, 1 })
	end
end

function M.bold()
	inline_surround("**", "**")
end

function M.italic()
	inline_surround("_", "_")
end

function M.code()
	if vim.fn.visualmode() == "V" then
		vim.ui.input({ prompt = "Language:" }, function(lang)
			if lang == nil then
				return
			end
			newline_surround("```" .. lang, "```")
		end)
	else
		inline_surround("`", "`")
	end
end

function M.link()
	vim.ui.input({ prompt = "Href:" }, function(href)
		if href == nil then
			return
		end
		inline_surround("[", "](" .. href .. ")", { remove = false })
	end)
end

function M.init()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function()
			vim.keymap.set(
				"v",
				config.wrap.keys.bold,
				":lua require('markdown-todo.wrap').bold()<cr>",
				{ buffer = 0, silent = true }
			)
			vim.keymap.set(
				"v",
				config.wrap.keys.italic,
				":lua require('markdown-todo.wrap').italic()<cr>",
				{ buffer = 0, silent = true }
			)
			vim.keymap.set(
				"v",
				config.wrap.keys.link,
				":lua require('markdown-todo.wrap').link()<cr>",
				{ buffer = 0, silent = true }
			)
			vim.keymap.set(
				"v",
				config.wrap.keys.code,
				":lua require('markdown-todo.wrap').code()<cr>",
				{ buffer = 0, silent = true }
			)
		end,
	})
end

return M
