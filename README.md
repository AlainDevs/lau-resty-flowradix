# lau-resty-flowradix
Modern Web Framework - Integrating Flowbite and Radix.

This repository combines several Lua libraries to enhance functionality for various systems:

- **Matching System**:
  - [lua-resty-radixtree](https://github.com/api7/lua-resty-radixtree)
  - [lua-resty-ipmatcher](https://github.com/api7/lua-resty-ipmatcher)
  - [lua-resty-expr](https://github.com/api7/lua-resty-expr)

- **Session Manager System**:
  - [lua-resty-session](https://github.com/bungle/lua-resty-session) or [lua-resty-cookie](https://github.com/cloudflare/lua-resty-cookie), you may set it in `src/configs/site_setting.lua`

- **Upload System**:
  - [lua-resty-post](https://github.com/antonheryanto/lua-resty-post)

- **Template System**:
  - [lua-resty-template](https://github.com/bungle/lua-resty-template)

- **Utility Tools**:
  - [lua-resty-random](https://github.com/bungle/lua-resty-random/tree/master)
  - [lua-resty-jit-uuid](https://github.com/thibaultcha/lua-resty-jit-uuid/tree/master)
  - [lua-resty-base-encoding](https://github.com/spacewander/lua-resty-base-encoding)
  - [phc-winner-argon2](https://github.com/P-H-C/phc-winner-argon2)
  - [lua-resty-string](https://github.com/openresty/lua-resty-string)
  - [lua-resty-openssl](https://github.com/fffonion/lua-resty-openssl)
## Requirements

To manage dependencies efficiently, three repositories are included within the `requirements` folder:

- **base-cencoding**
- **argon2**
- **radixtree**

## Modifications

### Radixtree

I have modified the `radixtree` library to introduce a feature that allows global routes with non-blocking high performance.

### Post Logic

For the `lua-resty-post` library, I have modified the multipart upload logic. Now, it always returns a number array, ensuring consistent structure whether one or multiple files are uploaded simultaneously.

This guide help you reimplement these features in other locations. Let's break it down into sections:

1. **File Upload**
2. **File Download**
3. **Stream Download**

Here's a comprehensive guide:

### 1. File Upload

The file upload functionality is implemented in the `routes01_POST` function in the `routes/admins.lua` file.

**Key steps:**

a) **Set up the upload configuration:**
```lua
local post = resty_post:new({
    path = "src/uploads/",
    chunk_size = 10240,
    no_tmp = true,
    name = function(name, field)
        return jit_uuid()
    end
})
```

b) **Read the uploaded files:**
```lua
local m = post:read()
```

c) **Process the uploaded files:**
```lua
for _, file_info in ipairs(m.files.uploads) do
    local new_file = {
        uuid = file_info.tmp_name,
        name = file_info.name,
        type = file_info.type,
        size = file_info.size
    }
    insert(data, new_file)
end
```

d) **Store the file information:**
```lua
local success, err = uploads:set("uploads", cjson.encode(data))
```

### 2. File Download

The file download functionality is implemented in the `routes00_GET` function in the `routes/download.lua` file.

**Key steps:**

a) **Retrieve the file UUID from the URL:**
```lua
local uuid = opts.matched.uuid
```

b) **Find the original filename:**
```lua
local uploads_data = uploads:get("uploads")
local data = cjson.decode(uploads_data)
local filename = ""
for k, v in ipairs(data) do
    if v.uuid == uuid then
        filename = v.name
        break
    end
end
```

c) **Perform an internal redirect to serve the file:**
```lua
return {type = "exec", url = concat({"/internal/serve_file/", uuid, "?filename=", filename}, "")}
```

### 3. Stream Download

The stream download functionality is implemented in the `routes01_GET` function in the `routes/download.lua` file.

**Key steps:**

a) **Set the filename:**
```lua
local filename = ngx_escape_uri("def.pdf")
```

b) **Return the stream data:**
```lua
return {type = "steam", filename = filename, data = "1234567890"}
```

### Implementation in `rax.lua`

The `rax.lua` file contains the main routing logic and response handlers. To implement these features:

1. **Add route handlers in the `routes` table:**
```lua
routes = table_merge(routes, download.routes)
```

2. **Implement response handlers:**
```lua
local response_handlers = {
    -- ... other handlers ...
    steam = function(raw)
        ngx.header['Content-Type'] = 'application/octet-stream'
        ngx.header['Content-Disposition'] = concat({'attachment; filename="' , raw.filename , '"' }, '')
        print(raw.data)
    end,
    exec = function(raw)
        return exec(raw.url or "/")
    end,
    -- ... other handlers ...
}
```

3. **Handle the response in the `handle_response` function:**
```lua
local function handle_response(raw, lang, user_data)
    if type(raw) == "table" then
        local handler = response_handlers[raw.type]
        if handler then
            handler(raw, lang, user_data)
        end
    end
end
```

### To reimplement these features in other locations:

1. **Ensure the necessary dependencies are available** (e.g., `resty.post`, `resty.jit-uuid`, `ngx.shared.uploads`).
2. **Set up the appropriate routes** in your routing configuration.
3. **Implement the upload, download, and stream functions** following the patterns shown above.
4. **Adjust the file storage location and shared dictionary names** as needed for your specific implementation.
5. **Ensure proper error handling and security measures** are in place, such as file type validation and user authentication.
6. **"ngx.shared.uploads" acts like database**, you can use redis or other database (for example PostgreSQL) to store the file information.
7. **"resty.post" is a library for handling HTTP POST requests**, you can use other libraries for this purpose.
8. **"resty.jit-uuid" is a library for generating UUIDs**, you can use other libraries for this purpose.
9. **"ngx.escape_uri" is a function for escaping URI components**, you can use other functions for this purpose.
10. **"ngx.header" is a table for setting HTTP headers**, you can use other methods for this purpose.
11. **"print" is a function for printing output to the console**, you can use other methods for this purpose.
12. **"exec" is a function for executing a URL**, you can use other methods for this purpose.
13. **"table_merge" is a function for merging tables**, you can use other functions for this purpose.
14. **"cjson" is a library for encoding and decoding JSON data**, you can use other libraries for this purpose.
15. **"ipairs" is a function for iterating over the elements of a table**, you can use other functions for this purpose.
16. **"concat" is a function for concatenating strings**, you can use other functions for this purpose.
17. **"insert" is a function for inserting elements into a table**, you can use other functions for this purpose.
18. **"type" is a function for checking the type of a variable**, you can use other functions for this purpose.
19. **"ngx.header['Content-Type']" is used to set the content type of the response**, you can use other methods for this purpose.
20. **"ngx.header['Content-Disposition']" is used to set the content disposition of the response**, you can use other methods for this purpose.
21. **"ngx.shared.uploads" is a shared dictionary for storing file information**, you can use other methods for this purpose.
22. **"resty.post" is a library for handling HTTP POST requests**, you can use other libraries for this purpose.
23. **"resty.jit-uuid" is a library for generating UUIDs**, you can use other libraries for this purpose.
24. **"ngx.escape_uri" is a function for escaping URI components**, you can use other functions for this purpose.

Remember to adapt the code to your specific needs and environment, and always prioritize security when handling file uploads and downloads.
