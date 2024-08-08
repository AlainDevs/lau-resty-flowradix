local _M = {
    version = 1.2
}

local homepage = require "src.views.languages.index"
local footer = require "views.languages.footer"
local error_page = require "views.languages.error"
local maintenance = require "views.languages.maintenance"

_M["index.html"] = homepage
_M["footer.html"] = footer
_M["error.html"] = error_page
_M["maintenance.html"] = maintenance

return _M
