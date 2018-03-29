local sum_dict = ngx.shared.sum_dict
local time_stamp = math.floor(ngx.time()/60)
local server_name = ngx.var.host

if ngx.var.request_method == "POST" then
    uri, _, err = ngx.re.gsub(ngx.var.request_uri, '/', '_')
else
    if ngx.var.request_uri then
        caps, _, err = ngx.re.match(ngx.var.request_uri, "([//a-z0-9]+)/?.*", 'iox')
        if caps then
            if caps[1] then
                uri = ngx.re.gsub(caps[1], '/', '_')
            else
                ngx.log(ngx.ERR, "can't get native uri! server_name: ", server_name, "request: ",ngx.var.request )
                return
            end
         else
             ngx.log(ngx.ERR, "can't match request! server_name: ", server_name, "request: ", ngx.var.request)
             return
         end
    else
        ngx.log(ngx.ERR, "no request_uri! server_name: ", server_name, "request: ",ngx.var.request_uri )
        return
    end
end
if uri then
    if ngx.var.upstream_response_time == "-" then
        up_time = ngx.var.request_time
    else
        up_time = ngx.re.gsub(ngx.var.upstream_response_time or 0,"(\\d*)(,.*)","$1","i") or 0
    end
    metric = server_name .. ':' .. uri .. ':' .. ngx.var.request_time .. ':' .. up_time .. ':' .. ngx.var.status
    sum_dict:lpush(time_stamp, metric)
else
    ngx.log(ngx.ERR, "error: ", err)
    return
end
