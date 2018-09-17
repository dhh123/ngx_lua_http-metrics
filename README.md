#### step 1: nginx.conf 中添加
'''
    * lua_shared_dict sum_dict 100M;
    * init_worker_by_lua_file /"luapath"/post_metric.lua;
    * log_by_lua_file /"luapath"/gather_facts.lua;
'''


#### step 2: nginx 80端口 default_server 中添加一个接口
```        
location /falcon_push {
                access_log off;
                content_by_lua_file /"luapath"/display_metrics.lua;
        }
'''






