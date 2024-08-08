local _M = {
    version = 0.1
}

_M.routes = require("views.languages.routes")

_M.load = function (template, lang)
    return _M.routes[template] and _M.routes[template][lang] or nil
end

return _M
