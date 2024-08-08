local _M = {}
local session = require "resty.session"
local uuid = require 'resty.jit-uuid'
local ck = require "resty.cookie"
local aes = require "resty.aes"
local base_encoding = require "resty.base_encoding"
local session_method = require "configs.site_setting".session_method
local aes_128_cbc_md5_key = require "configs.site_setting".cookie.aes_128_cbc_md5
local ngx_var = ngx.var
local ngx_find = ngx.re.find
local type = type
local ipairs = ipairs
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local sessions = ngx.shared.sessions

-- Initialize UUID generator
uuid.seed()

-- AES encryption setup
local function encrypt_value(value)
    local aes_128_cbc_md5 = aes:new(aes_128_cbc_md5_key)
    return base_encoding.encode_base32(aes_128_cbc_md5:encrypt(value))
end

local function decrypt_value(encrypted_base32)
    local aes_128_cbc_md5 = aes:new(aes_128_cbc_md5_key)
    return aes_128_cbc_md5:decrypt(base_encoding.decode_base32(encrypted_base32))
end

_M.method = {
    session = {
        set = function (key, value, is_exists)
            local sess, err, exists, refreshed = session.start()
            if not sess then
                ngx_log(ngx_ERR, "failed to open session: ", err)
            end
            if not exists and is_exists then
                -- ngx_log(ngx_ERR, "failed to open session: ", "user not exists")
                return
            end
            if not exists then
                if type(key) == "table" then
                    for _, v in ipairs(key) do
                        sess:set(v.key, v.value)
                    end
                else
                    sess:set(key, value)
                end
            
                local ok
                ok, err = sess:save()
                if err then
                    ngx_log(ngx_ERR, "failed to save session: ", err)
                end
                return
            end
            if type(key) == "table" then
                for _, v in ipairs(key) do
                    sess.info:set(v.key, v.value)
                end
            else
                sess.info:set(key, value)
            end
        
            local ok
            ok, err = sess.info:save()
            if err then
                ngx_log(ngx_ERR, "failed to save session: ", err)
            end
        end,
        get = function (key)
            local sess = session.open()
            return sess.info:get(key) or sess:get(key)
        end,
    },

    cookie = {
        set = function (key, value, is_exists)
            local cookie, err = ck:new()
            if not cookie then
                ngx_log(ngx_ERR, "failed to create cookie: ", err)
                return
            end

            local session_id = cookie:get("session")
            if not session_id and is_exists then
                -- ngx_log(ngx_ERR, "failed to open session: ", "user not exists")
                return
            end
            if not session_id or not uuid.is_valid(session_id) then
                session_id = uuid()
                local ok
                ok, err = cookie:set({
                    key = "session",
                    value = session_id,
                    path = "/",
                    httponly = true,
                    secure = false,
                    samesite = "Strict"
                })
                if not ok then
                    ngx_log(ngx_ERR, "failed to set cookie: ", err)
                    return
                end
            end

            local encrypted_value = encrypt_value(value)
            sessions:set(session_id .. ":" .. key, encrypted_value)
        end,
        get = function (key)
            local cookie, err = ck:new()
            if not cookie then
                ngx_log(ngx_ERR, "failed to create cookie: ", err)
                return nil
            end

            local session_id = cookie:get("session")
            if not session_id or not uuid.is_valid(session_id) then
                return nil
            end

            local encrypted_value = sessions:get(session_id .. ":" .. key)
            if not encrypted_value then
                return nil
            end

            return decrypt_value(encrypted_value)
        end,
    }
}

_M.set = function(key, value, is_exists)
    return _M.method[session_method].set(key, value, is_exists)
end

_M.get = function(key)
    return _M.method[session_method].get(key)
end

_M.init_lang = function()
    local lang = _M.method[session_method].get("lang")
    if lang then
        return lang
    end
    local header_lang = ngx_var.http_accept_language or "en"
    lang = ngx_find(header_lang, "zh", "jo") and "zh" or "en"
    _M.method[session_method].set("lang", lang)
    return lang
end

return _M
