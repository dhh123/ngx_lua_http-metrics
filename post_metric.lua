local deploy = 60
local sum_dict = ngx.shared.sum_dict
local timestamp=ngx.time()
local time_stamp = math.floor(timestamp/60)
trigger_push = function (posted)
    local timestamp=ngx.time()
    local time_stamp = math.floor(timestamp/60)
    local time_flag = sum_dict:get('time_flag')
    local pid_flag = sum_dict:get('pid_flag')
    if not time_flag  or not pid_flag then
        ngx.log(ngx.ERR, "Cann't get time_flag or pid_flag")
        return
    else
        if time_flag ~= time_stamp and pid_flag == ngx.worker.pid()  then
            local sock = ngx.socket.tcp()
            local ok, err = sock:connect("127.0.0.1", 80)
            sock:settimeout(1000)
            if not ok then
                 ngx.log(ngx.ERR, "failed to connect: ", err)
                 ngx.timer.at(deploy, trigger_push)
                 return
            end
            local metric_push = 'GET /falcon_push HTTP/1.1\r\nHost: 127.0.0.1:1988\r\nAccept: */*\r\nUser-Agent: ngx-lua/'..ngx.config.ngx_lua_version..'\r\n\r\n'
            local bytes, err = sock:send(metric_push)
            sock:close()
            local ok, err = ngx.timer.at(deploy, trigger_push)
            if not ok then
                ngx.log(ngx.ERR, "failed to create the timer: ", err)
                return
            end
            sum_dict:replace('time_flag', time_stamp)
            return
        else
            ngx.log(ngx.INFO, "timer worker stop :",ngx.worker.pid())
            return
        end
    end
    if posted then
        return
    end
end
sum_dict:set('pid_flag', ngx.worker.pid())
local suc, err, _ =  sum_dict:set('time_flag', time_stamp)
if not err then
    ngx.log(ngx.ERR, "Successed Set time_flag:", time_stamp)
else
    ngx.log(ngx.ERR, "Set time_flag failed:", err)
end
local ok, err = ngx.timer.at(deploy, trigger_push)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end
