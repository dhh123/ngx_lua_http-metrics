local cjson = require "cjson"
local falcon_step = 60
local sum_dict = ngx.shared.sum_dict
local timestamp=ngx.time()
local time_stamp = math.floor((timestamp-60)/60)
local post_metric = ""
function AddMetric(metric, value, tags)
    tags[1], _, _ = ngx.re.gsub(tags[1], '_', '/')
    local template ={['Metric']=metric, ['Endpoint']=ngx.var.hostname,
                    ['Timestamp']=ngx.time()-60, ['Step']=falcon_step, ['Value']=value,
                    ['CounterType']="GAUGE",['TAGS']=string.format("uri=%s,sn=%s",tags[1],tags[2])
                   }
    if post_metric == "" then
        post_metric = cjson.encode(template)
    else
        post_metric = post_metric ..','.. cjson.encode(template)
    end

end

function DeepCopy(object)
    local SearchTable = {}
    local function Func(object)
        if type(object) ~= "table" then
            return object
        end
        local NewTable = {}
        SearchTable[object] = NewTable
        for k, v in pairs(object) do
            NewTable[Func(k)] = Func(v)
        end
        return setmetatable(NewTable, getmetatable(object))
    end
    return Func(object)
end

local Sum = function(T)
   local sum = 0
   for _, v in pairs(T) do
       sum = sum + v
   end
   return sum
end

function PercentTable(t, percent)
   if #t == 0 then
       return 0, 0
   end
   table.sort(t)
   local newtable = {}
   local count = #t
   local newcount = math.ceil(count * percent)
   for i = 1, newcount do
       table.insert(newtable, t[i])
   end
   local max = newtable[newcount]
   return max, Sum(newtable)/newcount
end

-- clean the oldest key
local keys = sum_dict:get_keys()
if keys then
    if #keys >= 5 then
        ngx.log(ngx.ERR,'Delect timestamp:', keys[1])
        sum_dict:delete(keys[1])
    end
end
-- init care metric
local care_metric = {
    ['accept_sum'] = 0,['http_4xx']  = 0,['http_5xx'] = 0, ['L200'] = 0,
    ['L500'] = 0, ['L800'] = 0, ['response_time'] = {}, ['request_time'] = {}, ['http_414'] = 0,
    ['http_200'] = 0, ['http_301'] = 0, ['http_400'] = 0, ['http_403'] = 0, ['http_404'] = 0, ['http_408'] = 0, ['http_414'] = 0,
    ['http_499'] = 0, ['http_500'] = 0, ['http_502'] = 0, ['http_503'] = 0, ['http_504'] = 0
}
-- init care server_name and interface
local server_table = {
    ['cr.m.ksmobile.com']={
                  ['_news_report']=DeepCopy(care_metric),
                  ['_news_fresh']=DeepCopy(care_metric),
                  ['_news_recommend']=DeepCopy(care_metric),
                  ['_news_channels_chlist']=DeepCopy(care_metric),
                  ['_news_detail']=DeepCopy(care_metric),
                  ['_news_channels_getsubscribelist']=DeepCopy(care_metric),
                  ['_news_channels_subscribe']=DeepCopy(care_metric),
                  ['_news_column_first']=DeepCopy(care_metric),
                  ['_location_city']=DeepCopy(care_metric),
                  ['_location_pos']=DeepCopy(care_metric),
                  ['_location_update']=DeepCopy(care_metric),
    },
    ['cr.m.ksmobile.net']={
                  ['_news_report']=DeepCopy(care_metric),
                  ['_news_fresh']=DeepCopy(care_metric),
                  ['_news_recommend']=DeepCopy(care_metric),
                  ['_news_detail']=DeepCopy(care_metric),
                  ['_news_channels_getsubscribelist']=DeepCopy(care_metric),
                  ['_news_channels_subscribe']=DeepCopy(care_metric),
                  ['_news_column_first']=DeepCopy(care_metric),
                  ['_location_city']=DeepCopy(care_metric),
                  ['_location_pos']=DeepCopy(care_metric),
                  ['_location_update']=DeepCopy(care_metric),
    },
    ['n.m.ksmobile.net']={
                  ['_news_report']=DeepCopy(care_metric),
                  ['_news_fresh']=DeepCopy(care_metric),
                  ['_news_search']=DeepCopy(care_metric),
                  ['_location_reportgps']=DeepCopy(care_metric),
                  ['_news_mycolumn_get']=DeepCopy(care_metric),
                  ['_news_mycolumn_set']=DeepCopy(care_metric),
                  ['_news_recommend']=DeepCopy(care_metric),
                  ['_news_detail']=DeepCopy(care_metric),
                  ['_news_album']=DeepCopy(care_metric),
                  ['_news_nrdetail.html']=DeepCopy(care_metric),
                  ['_news_channels']=DeepCopy(care_metric),
                  ['_news_channels_chlist']=DeepCopy(care_metric),
                  ['_news_nrshare.html']=DeepCopy(care_metric),
                  ['_news_publisher']=DeepCopy(care_metric),
                  ['_news_mycolumn_set']=DeepCopy(care_metric),
                  ['_news_mycolumn_exchange']=DeepCopy(care_metric),
                  ['_search_suggestion_get']=DeepCopy(care_metric),
                  ['_news_column_second']=DeepCopy(care_metric),
                  ['_appstats_install_callback']=DeepCopy(care_metric),
                  ['_appstats_install_query']=DeepCopy(care_metric),
                  ['_news_channels_getsubscribelist']=DeepCopy(care_metric),
                  ['_news_channels_subscribe']=DeepCopy(care_metric),
                  ['_news_column_first']=DeepCopy(care_metric),
                  ['_location_city']=DeepCopy(care_metric),
                  ['_location_pos']=DeepCopy(care_metric),
                  ['_location_update']=DeepCopy(care_metric),
    },
}
local get_keys = function(tb)
    local new={}
    for k,_ in pairs(tb) do
        table.insert(new,k)
    end
    return new
end
local in_arr = function (tb,val)
    for _,v in ipairs(tb) do
        if val == v then
            return true
        end
    end
    return false
end

function split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end
function StartsWith(str, patten)
    local from, to, _ = ngx.re.find(str, patten, 'jo')
    if from and from == 1 then
        return true
    else
        return false
    end
end
function gen_metric(m)
    server_name, interface, request_time, response_time, status = m[1], m[2], tonumber(m[3]), m[4], tonumber(m[5])
    if not server_table[server_name] or not in_arr(get_keys(server_table[server_name]),interface) then
        return
    end

    if status < 500 and status >=400 then
        server_table[server_name][interface]['http_4xx'] = server_table[server_name][interface]['http_4xx'] + 1
    elseif status >= 500 then
        server_table[server_name][interface]['http_5xx'] = server_table[server_name][interface]['http_5xx'] + 1
    end

    if 0.2 >= request_time then
        server_table[server_name][interface]['L200'] = server_table[server_name][interface]['L200'] + 1
        server_table[server_name][interface]['L500'] = server_table[server_name][interface]['L500'] + 1
        server_table[server_name][interface]['L800'] = server_table[server_name][interface]['L800'] + 1
    elseif 0.5 >= request_time then
        server_table[server_name][interface]['L500'] = server_table[server_name][interface]['L500'] + 1
        server_table[server_name][interface]['L800'] = server_table[server_name][interface]['L800'] + 1
    elseif 0.8 >= request_time then
        server_table[server_name][interface]['L800'] = server_table[server_name][interface]['L800'] + 1
    end
    server_table[server_name][interface]['accept_sum'] = server_table[server_name][interface]['accept_sum'] + 1
    table.insert(server_table[server_name][interface]['request_time'], request_time)
    table.insert(server_table[server_name][interface]['response_time'], response_time)
    server_table[server_name][interface]['http_'..status] = server_table[server_name][interface]['http_'..status] + 1
end
-- Get the assign timestamp metrics for ngx.share.DICT
repeat
    local metric = sum_dict:rpop(time_stamp) or 0
    if metric ~= 0 then
        local metrics = split(metric, ":")
        gen_metric(metrics)
        --if not pcall(gen_metric, metrics) then
        --    ngx.log(ngx.ERR, "got a bad metric: ", metric)
        --end
    end
until (metric == 0)
-- generate request_time 0.9&&0.99
for sn,uris in pairs(server_table) do
    for uri, _ in pairs(uris) do
        local max, avg = 0, 0
        for _,v in ipairs({1, 0.9, 0.99}) do
            if v == 1 then
                flag = "all"
            else
                flag = v
            end
            server_table[sn][uri]['request_time_'..flag..'_max'], server_table[sn][uri]['request_time_'..flag..'_avg'] = PercentTable(server_table[sn][uri]['request_time'],v)
            server_table[sn][uri]['response_time_'..flag..'_max'], server_table[sn][uri]['response_time_'..flag..'_avg'] = PercentTable(server_table[sn][uri]['response_time'],v)
        end
        server_table[sn][uri]['request_time'] = nil
        server_table[sn][uri]['response_time'] = nil
    end
end

-- generate metrics
local server_sum, server_response_time, server_request_time, server_L200, server_L500, server_L800, server_http_5xx, server_http_4xx = 0, 0, 0, 0, 0, 0, 0, 0
for sn, uris in pairs(server_table) do
    local interface_sum = 0
    for uri, metric in pairs(uris) do
--        uri, _, err = ngx.re.gsub(uri, '_', '/')
        for k,v in pairs(metric) do
            if StartsWith(k, "http_") then
                if k == "http_4xx" then
                    server_http_4xx = server_http_4xx + v
                elseif k == "http_5xx" then
                    server_http_5xx = server_http_5xx + v
                end
                AddMetric(k, v, {uri, sn})
            elseif StartsWith(k, "request_time") or StartsWith(k, "response_time") then
                  AddMetric(k, v * 1000, {uri, sn})
            elseif StartsWith(k, "L") then
                 if metric['accept_sum'] == 0 then
                     AddMetric('latency_lt_'..string.sub(k,2,4), 100, {uri, sn})
                 else
                     AddMetric('latency_lt_'..string.sub(k, 2, 4), v*100.0/metric['accept_sum'] or 100, {uri, sn})
                 end
                 if k == "L200" then
                     server_L200 = server_L200 + v
                 elseif k == "L500" then
                     server_L500 = server_L500 + v
                 else

                     server_L800 = server_L800 + v
                 end
            else
                 AddMetric('qpm', metric[k], {uri, sn})
                 interface_sum = interface_sum + v
            end
         end
    end
    server_sum = server_sum + interface_sum
    AddMetric('qpm', interface_sum, {'sum', sn})
end
if server_sum == 0 then
    AddMetric('latency_lt_200',100,{'sum', 'sum'})
    AddMetric('latency_lt_500',100,{'sum', 'sum'})
    AddMetric('latency_lt_800',100,{'sum', 'sum'})
    AddMetric('http_4xx', 0,{'sum', 'sum'})
    AddMetric('http_4xx_percent', 0 ,{'sum', 'sum'})
    AddMetric('http_5xx', 0,{'sum', 'sum'})
    AddMetric('http_5xx_percent', 0 ,{'sum', 'sum'})
else
    AddMetric('latency_lt_200',(server_L200*100.0)/server_sum, {'sum', 'sum'})
    AddMetric('latency_lt_500',(server_L500*100.0)/server_sum, {'sum', 'sum'})
    AddMetric('latency_lt_800',(server_L800*100.0)/server_sum, {'sum', 'sum'})
    AddMetric('http_4xx_percent', (server_http_4xx*100.0)/server_sum,{'sum', 'sum'})
    AddMetric('http_4xx', server_http_4xx, {'sum', 'sum'})
    AddMetric('http_5xx_percent', (server_http_5xx*100.0)/server_sum,{'sum', 'sum'})
    AddMetric('http_5xx', server_http_5xx, {'sum', 'sum'})
end
AddMetric('qpm', server_sum, {"sum", "sum"})



-- Posh metrics to falcon
local encoded_table = '['..post_metric..']'
local sock = ngx.socket.tcp()
local ok, err = sock:connect("127.0.0.1", 1988)
sock:settimeout(1000)
if not ok then
     ngx.log(ngx.ERR, "failed to connect: ", err)
     return
end
local post_metric = 'POST /v1/push HTTP/1.1\r\nHost: 127.0.0.1:1988\r\nAccept: */*\r\nUser-Agent: ngx-lua/'..ngx.config.ngx_lua_version..'\r\nContent-Length:'..#encoded_table..'\r\n\r\n'..encoded_table
local bytes, err = sock:send(post_metric)
if err then
    ngx.log(ngx.ERR, "!!:", ERR)
    return
end
local line, err, partial = sock:receiveuntil("success")
if err then
    ngx.log(ngx.ERR, "!!:", ERR)
    return
end
if not line then
    ngx.log(ngx.ERR,"failed to read a line: ", err)
end
