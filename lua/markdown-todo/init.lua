local config = require("markdown-todo.config")
local utils = require("markdown-todo.utils")
local style = require("markdown-todo.style")
local to_do = require("markdown-todo.to_do")
local wrap = require("markdown-todo.wrap")
local follow_link = require("markdown-todo.follow-link")

local M = {}
M.setup = function(user_config)
	if user_config ~= nil then
		utils.merge(config, user_config)
	end
	style.init()
	to_do.init()
	wrap.init()
	follow_link.init()
end

return M
