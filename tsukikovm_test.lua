local tsukiko = require("tsukiko")

function hello()
	print("Hello, world!")
end

function subfunc()
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
end

local function test(name, func)
	print("===================================")
	print(name)
	print("===================================")
	local d = string.dump(func)
	local f = io.open("tvm_test.luac", "wb")
	f:write(d)
	f:close()
	local res = tsukiko.parser.parse(d)
	print("===================================")
	print("pass!")
	print("===================================\n")
end

test("hello", hello)
test("subfunc", subfunc)