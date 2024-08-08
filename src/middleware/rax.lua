-- @module rax.lua
local _M = {}

-- Localize global functions and constants
local type, setmetatable, require = type, setmetatable, require
local ngx = ngx
local print, redirect, exec = ngx.print, ngx.redirect, ngx.exec
local ngx_log, ngx_ERR = ngx.log, ngx.ERR
local capture = ngx.location.capture
local ngx_md5 = ngx.md5
local ngx_exit = ngx.exit
local escape_uri = ngx.escape_uri
local concat = table.concat


-- Required modules
local radix = require("resty.radixtree")
local apis = require("routes.apis")
local admins = require("routes.admins")
local internal = require("routes.internal")
local download = require("routes.download")
local cjson = require("cjson")
local template = require("resty.template")
local config = require("configs.site_setting")
local sess_manager = require("middleware.sess_manager")
local language_loader = require("middleware.language_loader")
local links_loader = require("middleware.links_loader")
local my_cache = ngx.shared.content_cache

-- Local functions
local function table_merge(t1, t2)
    local len = #t1
    for i = 1, #t2 do
        t1[len + i] = t2[i]
    end
    return t1
end

local CACHE_TTL = 3600  -- Cache TTL in seconds (e.g., 1 hour)
local function generate_cache_key(raw, lang, user_data)
    local key_data = cjson.encode({raw = raw, lang = lang, user_data = user_data})
    return ngx_md5(key_data)
end

local function routes00_GET()
    return {type = "html", template = "index.html", data = {}}
end

-- Routes setup
local routes = {
    {
        paths = {"/"},
        metadata = routes00_GET
    },
}

local glo_routes = {
    maintenance = function ()
        if config.is_maintenance_mode then
            exec("/internal/maintenance")
            ngx_exit(ngx.HTTP_OK)
        end
    end
}

routes = table_merge(routes, apis.routes)
routes = table_merge(routes, internal.routes)
routes = table_merge(routes, download.routes)
routes = table_merge(routes, admins.routes)
_M.rx = radix.new(routes)

-- View setup function
local function setup_view(template_name, lang, user_data)
    local view = template.new(template_name)
    view.language_loader = language_loader
    view.lang = lang
    view.lt = view.language_loader.load(template_name, view.lang)
    view.user_data = user_data
    return view
end

-- Response handlers
local response_handlers = {
    html = function(raw, lang, user_data)
        lang = sess_manager.init_lang()
        local cache_key = generate_cache_key(raw, lang, user_data)
        local cached_content = my_cache:get(cache_key)

        if cached_content then
            print(cached_content)
        else
            local view = setup_view(raw.template, lang, user_data)
            raw.data = raw.data or {}
            raw.data.view = view
            local content = view:process(setmetatable(raw.data, { __index = view }))
            my_cache:set(cache_key, content, CACHE_TTL)
            print(content)
        end
    end,
    json = function(raw)
        ngx.header['Content-Type'] = 'application/json; charset=utf-8'
        print(cjson.encode(raw.data))
    end,
    steam = function(raw)
        ngx.header['Content-Type'] = 'application/octet-stream'
        ngx.header['Content-Disposition'] = concat({'attachment; filename="' , raw.filename , '"' }, '')
        print(raw.data)
    end,
    redirect = function(raw)
        return redirect(raw.url or "/")
    end,
    exec = function(raw)
        return exec(raw.url or "/")
    end,
    capture = function(raw)
        return print(capture(raw.url or "/").body)
    end
}

local function handle_response(raw, lang, user_data)
    if type(raw) == "table" then
        local handler = response_handlers[raw.type]
        if handler then
            handler(raw, lang, user_data)
        end
    end
end

-- Main run function
function _M.run()
    local uri = ngx.var.uri
    local opts = {matched = {}}
    local res = _M.rx:match(uri, opts)
    opts.matched.user_data = {}
    local lang = "en"

    local route_prefixes = opts.matched.route_prefixes

    if route_prefixes then
        local n = #route_prefixes
        for i = 1, n do
            local prefix = route_prefixes[i]
            local handler = glo_routes[prefix]
            if handler then
                handler(opts)
            end
        end
    end

    if res then
        handle_response(res(opts), lang, opts.matched.user_data)
    else
        local error_data = {template = "error.html", data = {}}
        local cache_key = generate_cache_key(error_data, lang, opts.matched.user_data)
        if not cache_key then
            ngx_log(ngx_ERR, "failed to generate cache key for error page")
            return
        end

        local cached_content = my_cache:get(cache_key)
        if cached_content then
            print(cached_content)
        else
            local view = setup_view("error.html", lang, opts.matched.user_data)
            local content = view:process()
            my_cache:set(cache_key, content, CACHE_TTL)
            print(content)
        end
    end
end

return _M
