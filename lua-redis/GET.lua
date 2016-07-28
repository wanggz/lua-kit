RedisServices={"172.17.5.42","172.17.5.42","172.17.5.42"}
PoolSize=1024
Timeout=1000
db=0

local readService=RedisServices[math.random(3)]

local positionId=ngx.var.arg_positionId

local uri = ngx.var.request_uri

--[====[
redis get key : red:get(key)
]====]
function GetContent(redisIp,key)
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(Timeout)
    local ok, err = red:connect(redisIp, 6379)
	local content = ""
	local succeed = false
	if ok then
		red:select(db)
		local res, err = red:get(key)
		content = key..":"..res..":"..err
		if res and res ~= ngx.null and res ~= "" and res ~= nil then
			content=res
			succeed=true
			red:set_keepalive(0,PoolSize)
		end
	end
	return succeed, content
end

local ok,content = GetContent(readService,positionId)
if ok then
	ngx.say(content)
else
	ngx.say("{\"message\":\"error\"}")
end