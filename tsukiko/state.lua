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

local function decode_ins(blk, pos)
	local iv = string.unpack("I", blk, pos)
	local op, a, b, c = iv & 0x3f,
						(iv >> 5) & 0xFF,
						(iv >> 13) & 0x1FF,
						(iv >> 22) & 0x1FF
	local ax = iv >> 5
	local bx = iv >> 13
	local sbx = cast(bx, "H", "h") -- you think i'm gonna take the effort to do this in a non-jank way? lol
	return {
		op = op,
		a = a,
		b = b,
		c = c,
		ax = ax,
		bx = bx,
		sbx = sbx
	}
end

function state:call(idx, ...)