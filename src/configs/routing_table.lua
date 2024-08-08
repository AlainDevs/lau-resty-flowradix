return {
    -- { path = [=[^\/users\/(?!login$|register$).*]=], routes = {"verify"}},
    -- { path = [=[^\/]=], routes = {"get_email"}},
    { path = [=[^\/(?!internal\/maintenance$)]=], routes = {"maintenance"}},
}
