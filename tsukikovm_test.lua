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

function ref()
	hello()
	subfunc()
end

function double_subfunc()
	local function test2(a, b, c)
		local function test1(a, b)
			local t = a
			return ((a ~ b) << (t & 4)) | (t >> (64-(t & 4))) , b-1
		end
		for i=1, c do
			a, b = test1(a, b)
		end
		return a, b
	end
	local x, y = 4, 10
	while y ~= 0 do
		print(x, y)
		x, y = test1(x, y)
	end
	print(x, y)
end

function tailcall()
	return hello()
end

local function test(name, func)
	print("===================================")
	print(name)
	print("===================================")
	local d = string.dump(func)
	local f = io.open("tests/tvm_test_"..name..".luac", "wb")
	f:write(d)
	f:close()
	os.execute("luadisass -d tests/tvm_test_"..name..".luac tests/tvm_test_"..name..".luas")
	local res = tsukiko.parser.parse(d)
	print("===================================")
	print("pass!")
	print("===================================\n")
end

test("hello", hello)
test("subfunc", subfunc)
test("ref", ref)
test("double_subfunc", double_subfunc)
test("anonymous", function()
	print("ok!")
end)
test("taillcall", tailcall)