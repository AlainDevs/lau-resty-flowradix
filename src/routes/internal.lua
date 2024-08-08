local _M = {}
local sess_manager = require "middleware.sess_manager"
local resty_post = require "resty.post"

_M.routes00_GET = function()
    return {type = "html", template = "maintenance.html"}
end
_M.routes = {
    {
        paths = {"/internal/maintenance"},
        metadata = function()
            return _M.routes00_GET()
        end,
    },
}

return _M
