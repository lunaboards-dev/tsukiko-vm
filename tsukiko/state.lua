local state = {}

local function cast(i, f, t)
	return string.unpack(t, string.pack(f, i))
end

local function create_state()
	return setmetatable({
		stack = {},
		top = -1,
		base_ci = -1,
		last = -1,
		call_info = {}
	}, {__index=state})
end

local function decode_ins(blk, pos, tbl)
	local iv, next = string.unpack("I", blk, pos)
	local op, a, b, c = iv & 0x3f,
						(iv >> 5) & 0xFF,
						(iv >> 13) & 0x1FF,
						(iv >> 22) & 0x1FF
	local ax = iv >> 5
	local bx = iv >> 13
	local sbx = bx - 0x1FFFF
	tbl.op = op
	tbl.a = a
	tbl.b = b
	tbl.c = c
	tbl.ax = ax
	tbl.bx = bx
	tbl.sbx = sbx
	return next
end

tsukiko.decode_ins = decode_ins

function state:call(idx, ...)

end

tsukiko.state = state