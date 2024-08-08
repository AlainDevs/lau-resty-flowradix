local _M = {}
local resty_post = require "resty.post"
local jit_uuid = require 'resty.jit-uuid'
local uploads = ngx.shared.uploads
local cjson = require "cjson"
local ngx_log, ngx_ERR = ngx.log, ngx.ERR
local insert = table.insert
local ipairs = ipairs

_M.routes00_GET = function()
    return {type = "html", template = "dashboard_admin.html"}
end

_M.routes01_GET = function()
    local uploads_data = uploads:get("uploads")
    local data = {}
    if uploads_data then
        data = cjson.decode(uploads_data)
        -- ngx_log(ngx_ERR, "uploads_data", uploads_data)
    end
    return {type = "html", template = "dashboard_uploads.html", data = {uploads_list = data}}
end

_M.routes01_POST = function()
    jit_uuid.seed()
    local post = resty_post:new({
        path = "src/uploads/",
        chunk_size = 10240,
        no_tmp = true,
        name = function(name, field)
            return jit_uuid()
        end
    })

    local m = post:read()

    if not m or not m.files then
        return {type = "json", template = "", data = {status = 1, message = "No files uploaded"}}
    end

    local uploads_data = uploads:get("uploads")
    local data = uploads_data and cjson.decode(uploads_data) or {}

    if not m.files or not #m.files.uploads then
        return {type = "json", template = "", data = {status = 1, message = "No files uploaded"}}
    end
    -- ngx_log(ngx_ERR, "encoded", cjson.encode(m.files))
    for _, file_info in ipairs(m.files.uploads) do
        local new_file = {
            uuid = file_info.tmp_name,
            name = file_info.name,
            type = file_info.type,
            size = file_info.size
        }
        insert(data, new_file)
    end

    local success, err = uploads:set("uploads", cjson.encode(data))
    -- ngx_log(ngx_ERR, "data: ", cjson.encode(data))
    if not success then
        ngx_log(ngx_ERR, "Failed to update uploads data: ", err)
        return {type = "json", template = "", data = {status = 1, message = "Failed to store upload information"}}
    end

    return {type = "json", template = "", data = {status = 0, message = "Files uploaded successfully"}}
end

_M.routes = {
    {
        paths = {"/admins/main"},
        metadata = function()
            return _M.routes00_GET()
        end,
    },
    {
        paths = {"/admins/uploads"},
        metadata = function()
            -- if POST
            if ngx.req.get_method() == "POST" then
                return _M.routes01_POST()
            end
            return _M.routes01_GET()
        end,
    },
}

return _M
