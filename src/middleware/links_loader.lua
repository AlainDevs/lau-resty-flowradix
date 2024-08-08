local _M = {
    version = 0.1
}

_M.links = require("configs.links")

_M.load = function (opts)
    opts.matched.user_data.links_data = _M.links
end

return _M
