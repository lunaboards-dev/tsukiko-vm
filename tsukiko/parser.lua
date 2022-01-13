local parser = {}

local luac_data = "\x19\x93\r\n\x1a\n"

local func = require("tsukiko.function")

local luac_int = 0x5678
local luac_num = 370.5
local l_isize = #string.pack("i", 0)
local l_ssize = #string.pack("T", 0)
local l_osize = #string.pack("I", 0)
local l_dsize = #string.pack("j", 0)
local l_nsize = #string.pack("n", 0)

function parser.parse_header(str)
	local sig, ver, fmt, dat, isize, ssize, osize, dsize, nsize, endian, floatfmt, next = string.unpack("c4BBc6BBBBBjn", str)
	assert(sig == tsukiko.signature, "bad signature")
	assert(ver == 0x53, "bad version")
	assert(fmt == 0, "bad format")
	assert(isize == l_isize, "wrong int size")
	assert(ssize == l_ssize, "wrong size_t size")
	assert(osize == l_osize, "wrong opcode size")
	assert(dsize == l_dsize, "wrong lua_Integer size")
	assert(nsize == l_nsize, "wrong lua_Number size")
	assert(endian == luac_int, "wrong endian")
	assert(floatfmt == luac_num, "wrong float fmt")
	return next
end

function parser.parse(str)
	local next = parser.parse_header(str)
	local uvs
	uvs, next = string.unpack("B", str, next)
	print("uvs:", uvs)
	return func.load(str:sub(next))
end

tsukiko.parser = parser