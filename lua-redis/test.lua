local config = {
	name = "test",
	serv_list = {
		{ip="172.17.5.70", port = 7000},
		{ip="172.17.5.70", port = 7001},
		{ip="172.17.5.70", port = 7002},
		{ip="172.17.5.70", port = 7003},
		{ip="172.17.5.70", port = 7004},
		{ip="172.17.5.70", port = 7005},
	},
}

local cmd=ngx.var.arg_cmd
local key=ngx.var.arg_key
if key==nil then key="" end
local value=ngx.var.arg_value
if value==nil then value="" end

local redis_cluster = require "resty.rediscluster"
local red_c = redis_cluster:new(config)

if cmd == "get" then
	local v,err = red_c:get(key)
	ngx.say(v)
elseif cmd == "set" then
	local ok, err = red_c:set(key,value)
	ngx.say(ok)
elseif cmd == "hmset" then
	local res, err = red:hmset(key, "dog{key}", "bark", "cat{key}", "meow")
	if not res then
		ngx.say("failed to set : ", err)
		return
	end
	ngx.say("hmset : ", res)
elseif cmd == "hmget" then
	local res, err = red:hmget(key, "dog{key}", "cat{key}")
	if not res then
		ngx.say("failed to get : ", err)
		return
	end
	ngx.say("hmget : ", res)	
else
	ngx.say("haha")
end
