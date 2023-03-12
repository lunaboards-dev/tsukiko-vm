local state = {}
local proc = require("tsukiko.proc")

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
	--[[local op, a, b, c = iv & 0x3f,
						(iv >> 6) & 0xFF,
						(iv >> 13) & 0x1FF,
						(iv >> 22) & 0x1FF]]
	local op = iv & 0x3f
	local args = iv >> 6
	local a = args & 0xFF
	local b = args & (0x1FF << 8)
	local c = args & (0x1FF << 17)
	local ax = args
	local bx = (b | c) >> 8
	local sbx = bx - 0x1FFFF
	tbl.op = op+1
	tbl.a = a
	tbl.c = b >> 8 -- don't worry about it
	tbl.b = c >> 17
	tbl.ax = ax
	tbl.bx = bx
	tbl.sbx = sbx
	--print(string.format("%.2x a: %.2x b: %.3x c: %.3x ax: %.7x bx: %.5x sbx: %.5x", tbl.op, tbl.a, tbl.b, tbl.c, tbl.ax, tbl.bx, tbl.sbx))
	return next
end

tsukiko.decode_ins = decode_ins

function state:run(count)
	
end

function state:call(start, argoff, argcount, rtv)

end

function state:metamethod(register, method, left, right)

end

function state:regval(n)

end

function state:retvals()
	return table.unpack(self.returns)
end

function state:new_proc(proto, env, instance)
	local e = tsukiko.envcopy(env)
	e._VERSION = tsukiko.version_string
	return setmetatable({
		inst = instance,
		func = proto,
		env = e,
		upvals = {},
		state = self,
		__type = tsukiko.objtypes.proc
	}, {__index=proc})
end

function state:load(code, env)
	-- no compiler yet
	local func = tsukiko.parser.parse(code)
	return self:new_proc(func, env, nil):instance()
end

function tsukiko.new_state()
	local env = {
		_VERSION = tsukiko.version_string
	}
	local st = {
		env = env,
		depth = 0,
		callstack = {}
	}
	return setmetatable(st, {__index=state})
end

tsukiko.state = state