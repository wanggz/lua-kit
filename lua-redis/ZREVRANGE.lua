RedisServices={"172.30.50.90","172.30.50.91","172.30.50.92"}
PoolSize=1024
Timeout=1000
db=3

local readService=RedisServices[math.random(3)]

local companyId=ngx.var.arg_companyId
local count = ngx.var.arg_rows

function GetContent(redisIp,key,count)
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(Timeout)
    local ok, err = red:connect(redisIp, 6379)
	local content = ""
	local succeed = false
	if ok then
		red:select(db)
		local rexpr = "return redis.call('ZREVRANGE',KEYS[1],0,ARGV[1],'WITHSCORES')"
		local res, err = red:eval(rexpr,1,"rcomp:"..key,tonumber(count)-1)
		if res and res ~= ngx.null and table.getn(res)>0 then
			content = "["
			for i=1, #(res), 2 do
				content = content.."{\"companyId\":"..res[i]..",\"score\":"..res[i+1].."},"
			end
			content = string.sub(content, 1, -2).."]"
			succeed=true
		end
	end
	red:set_keepalive(0,PoolSize)
	return succeed, content
end

local ok,content = GetContent(readService,companyId,count)
if ok then
	ngx.say(content)
end