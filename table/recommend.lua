PoolSize=1024
Timeout=1000

local Ttype=ngx.var.arg_type
if Ttype==nil then Ttype="" end
local userId=ngx.var.arg_userId
if userId==nil then userId="" end
local psapi=ngx.var.arg_psapi
if psapi==nil then psapi="" end
local positionId=ngx.var.arg_positionId
if positionId==nil then positionId="" end
local action=ngx.var.arg_action
if action==nil then action="" end

local table1 = {
	["1"]={
		["key"]="type:"..Ttype..":userId:"..userId,
		["content"]=(psapi=="" and "") or "{\"psapi\":\""..psapi.."\",\"time\":"..os.time().."}",
		["second"]=30*24*60*6,
		["redis"]="172.30.26.41"
	},
	["2"]={
		["key"]="type:"..Ttype..":userId:"..userId,
		["content"]=positionId,
		["second"]=30*24*60*60,
		["redis"]="172.30.26.42"
	},
	["3"]={
		["key"]="type:"..Ttype..":userId:"..userId,
		["content"]=positionId,
		["action"]=action,
		["second"]=30*24*60*60,
		["redis"]="172.30.26.40"
	},
	["4"]={
		["key"]="type:"..Ttype..":userId:"..userId,
		["content"]=positionId,
		["second"]=30*24*60*60,
		["redis"]="172.30.26.40"
	},
	["5"]={
		["key"]="type:"..Ttype..":userId:"..userId,
		["content"]=positionId,
		["second"]=30*24*60*60,
		["redis"]="172.30.26.40"
	},
	["6"]={
		["key"]="type:"..Ttype..":userId:"..userId,
		["content"]=positionId,
		["second"]=30*24*60*60,
		["redis"]="172.30.26.40"
	}
}

if Ttype then
	local flag = true
	for key in pairs(table1) do  
		if flag then
			if Ttype==key then flag=false break end
		end
	end 
	if flag then ngx.say("{\"message\":\"error\"}") return end
	if userId=="" then ngx.say("{\"message\":\"error\"}") return end
else
	ngx.say("{\"message\":\"error\"}")
	return
end

function SetContent(redisIp,key,content,action,expire)
	local redis = require "resty.redis"
	local red = redis:new()
	red:set_timeout(Timeout)
	local ok, err = red:connect(redisIp, 6379)
	if not ok then
		return false
	end
	if(action=="cancel") then
		local rexpr = "return redis.call('lrem',KEYS[1],-1,ARGV[1])"
		red:eval(rexpr,1,key,content)
	else
		local rexpr = "return redis.call('lrem',KEYS[1],-1,ARGV[1]) "
					.."and redis.call('lpush',KEYS[1],ARGV[1]) "
					.."and redis.call('expire',KEYS[1],".. tostring(expire) ..") "
					.."and redis.call('ltrim',KEYS[1],0,4)"
		red:eval(rexpr,1,key,content)
	end
	red:set_keepalive(0,PoolSize)
	return ok
end

function GetContent(redisIp,key)
	local redis = require "resty.redis"
	local red = redis:new()
	red:set_timeout(Timeout)
	local ok, err = red:connect(redisIp, 6379)
	if not ok then
		return false
	end
	local content = ""
	local succeed = false
	local rexpr = "return redis.call('lrange',KEYS[1],0,-1)"
	local res, err = red:eval(rexpr,1,key)
	if res and res ~= ngx.null then
		content=table.concat(res, ",")
		succeed=true
	end
	red:set_keepalive(0,PoolSize)
	return succeed, content
end

if table1[Ttype].content=="" then
	local ok,content = GetContent(table1[Ttype].redis,table1[Ttype].key)
	if ok then
		ngx.say(content)
	else
		ngx.say("{\"message\":\"error\"}")
	end
else 
	local ok = SetContent(table1[Ttype].redis,table1[Ttype].key,table1[Ttype].content,table1[Ttype].action,table1[Ttype].second)
	if ok then
		ngx.say("{\"message\":\"ok\"}")
	else
		ngx.say("{\"message\":\"error\"}")
	end
end
