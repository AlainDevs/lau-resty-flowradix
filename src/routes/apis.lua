local _M = {}
local sess_manager = require "middleware.sess_manager"
local resty_post = require "resty.post"

_M.routes00_GET = function()
    local post = resty_post:new()
    local m = post:read() or {}
    local lang = m.lang ~= "" and m.lang or nil

    if lang == "zh" then
        sess_manager.set("lang", lang, true)
        sess_manager.set("abc", lang, true)
    elseif lang == "en" then
        sess_manager.set("lang", lang, true)
    end

    return {type = "json", data = {status = 0}}
end
_M.routes = {
    {
        paths = {"/api/v1/lang"},
        metadata = function()
            return _M.routes00_GET()
        end,
    },
}

return _M
