local M = {
	file_types = { "markdown" },
	markdown_query = [[
            (atx_heading [
                (atx_h1_marker)
                (atx_h2_marker)
                (atx_h3_marker)
                (atx_h4_marker)
                (atx_h5_marker)
                (atx_h6_marker)
            ] @heading)

            (fenced_code_block) @code

            [
                (list_marker_plus)
                (list_marker_minus)
                (list_marker_star)
            ] @list_marker

            (block_quote (block_quote_marker) @quote_marker)
            (block_quote (paragraph (inline (block_continuation) @quote_marker)))

            (pipe_table_header) @table_head
            (pipe_table_delimiter_row) @table_delim
            (pipe_table_row) @table_row
        ]],
	render_modes = { "n", "c" },
	headings = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
	bullet = "○",
	quote = "┃",
	highlights = {
		heading = {
			backgrounds = { "DiffAdd", "DiffChange", "DiffDelete" },
			foregrounds = {
				"markdownH1",
				"markdownH2",
				"markdownH3",
				"markdownH4",
				"markdownH5",
				"markdownH6",
			},
		},
		code = "ColorColumn",
		bullet = "Normal",
		table = {
			head = "@markup.heading",
			row = "Normal",
		},
		latex = "@markup.math",
		quote = "@markup.quote",
	},
	lead_chars = {
		"######",
		"#####",
		"####",
		"###",
		"##",
		"#",
		"-",
	},
	indicators = {
		undone = {
			literal = " ",
			icon = " ",
			hl = "Delimiter",
		},
		pending = {
			literal = "-",
			hl = "PreProc",
			icon = "󰥔",
		},
		done = {
			literal = "x",
			hl = "String",
			icon = "󰄬",
		},
		on_hold = {
			literal = "=",
			hl = "Special",
			icon = "",
		},
		cancelled = {
			literal = "y",
			hl = "NonText",
			icon = "",
		},
		important = {
			literal = "!",
			hl = "@text.danger",
			icon = "⚠",
		},
		recurring = {
			literal = "+",
			hl = "Repeat",
			icon = "↺",
		},
		ambiguous = {
			literal = "?",
			hl = "Boolean",
			icon = "",
		},
		ongoing = {
			literal = "o",
			hl = "@keyword",
			icon = "",
		},
	},
	keys = {
		undone = "<leader>tu",
		pending = "<leader>tp",
		done = "<leader>td",
		on_hold = "<leader>th",
		cancelled = "<leader>tc",
		important = "<leader>ti",
		recurring = "<leader>tr",
		ambiguous = "<leader>ta",
		ongoing = "<leader>to",
	},
}

return M
