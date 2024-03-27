local M = {
	style = {
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
		headings = { "", "", "" },
		bullet = "",
		quote = "┃",
		highlights = {
			heading = {
				backgrounds = { "MarkdownLine" },
				foregrounds = {
					"MarkdownH1",
					"MarkdownH2",
					"MarkdownH3",
					"MarkdownH4",
					"MarkdownH5",
					"MarkdownH6",
				},
			},
			code = "MarkdownLine",
			bullet = "MarkdownBullet",
			table = {
				head = "@markup.heading",
				row = "Delimiter",
			},
			latex = "@markup.math",
			quote = "@markup.quote",
		},
	},
	to_do = {
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
				hl = "MarkdownUndone",
			},
			pending = {
				literal = "-",
				hl = "MarkdownPending",
				icon = "󰥔",
			},
			done = {
				literal = "x",
				hl = "MarkdownDone",
				icon = "󰄬",
			},
			on_hold = {
				literal = "=",
				hl = "MarkdownOnHold",
				icon = "",
			},
			cancelled = {
				literal = "y",
				hl = "MarkdownCancelled",
				icon = "",
			},
			important = {
				literal = "!",
				hl = "MarkdownImportant",
				icon = "⚠",
			},
			recurring = {
				literal = "+",
				hl = "MarkdownRecurring",
				icon = "↺",
			},
			ambiguous = {
				literal = "?",
				hl = "MarkdownAmbiguos",
				icon = "",
			},
			on_going = {
				literal = "o",
				hl = "MarkdownOnGoing",
				icon = "",
			},
		},
		keys = {
			undone = "<Leader>tu",
			pending = "<Leader>tp",
			done = "<Leader>td",
			on_hold = "<Leader>th",
			cancelled = "<Leader>tc",
			important = "<Leader>ti",
			recurring = "<Leader>tr",
			ambiguous = "<Leader>ta",
			on_going = "<Leader>to",
		},
	},
	wrap = {
		keys = {
			bold = "<Leader>cb",
			italic = "<Leader>ci",
			link = "<Leader>cl",
			code = "<Leader>cc",
		},
	},
}

return M
