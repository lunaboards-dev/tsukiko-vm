local tsukiko = require("tsukiko")

local d = string.dump(function(a)
	local function test1(a, b)
		local t = a
		return ((a ~ b) << (t & 4)) | (t >> (64-(t & 4))) , b-1
	end
	local x, y = 4, 10
	while y ~= 0 do
		print(x, y)
		x, y = test1(x, y)
	end
	print(x, y)
end)

local f = io.open("tvm_test.luac", "wb")
f:write(d)
f:close()

local res = tsukiko.parser.parse(d)