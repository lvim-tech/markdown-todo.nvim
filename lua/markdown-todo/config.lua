local M = {
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
		reccurring = "<leader>tr",
		ambiguous = "<leader>ta",
		ongoing = "<leader>to",
	},
}

return M
