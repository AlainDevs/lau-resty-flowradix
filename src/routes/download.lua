local _M = {}
local sess_manager = require "middleware.sess_manager"
local resty_post = require "resty.post"
local ngx_escape_uri = ngx.escape_uri
local concat = table.concat
local uploads = ngx.shared.uploads
local cjson = require "cjson"
local ipairs = ipairs
_M.routes00_GET = function(opts)
    local uuid = opts.matched.uuid

    -- Set the original filename in an Nginx variable
    local uploads_data = uploads:get("uploads")
    local data = {}
    if uploads_data then
        data = cjson.decode(uploads_data)
        -- ngx_log(ngx_ERR, "uploads_data", uploads_data)
    end
    -- data[#].name, which match to data[#].uuid
    local filename = ""
    for k, v in ipairs(data) do
        if v.uuid == uuid then
            filename = v.name
            break
        end
    end
    -- ngx_log(ngx_ERR, "filename", filename)

    -- Perform internal redirect to the file serving location
    return {type = "exec", url = concat({"/internal/serve_file/", uuid, "?filename=", filename}, "")}
end

_M.routes01_GET = function(opts)

    -- Set the original filename in an Nginx variable
    local filename = ngx_escape_uri("def.pdf")

    -- Perform internal redirect to the file serving location
    return {type = "steam", filename = filename, data = "1234567890"}
end

_M.routes = {
    {
        paths = {"/download/:uuid"},
        metadata = function(opts)
            return _M.routes00_GET(opts)
        end,
    },
    {
        paths = {"/download/steam"},
        metadata = function(opts)
            return _M.routes01_GET(opts)
        end,
    },
}

return _M
