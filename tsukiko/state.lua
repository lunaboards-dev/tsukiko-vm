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
	tbl.op = op
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

-- thread doesn't do anything for now
function state:run(count)
	count = count or math.huge
	local icount = 0
	local ins = {}
	local args = {}
	while count > icount do
		decode_ins(self.code, (self.pc*4)+1, ins)
		local ix = tsukiko.instructions[ins.op]
		for i=1, ix.regs.n do
			args[i] = ins[ix.regs[i]]
		end
		if not ix.func(nil, self, table.unpack(args)) then
			error(string.format("UNIMPLEMENTED: %s(%s) pc: %x", ix.name, table.concat(ix.regs, ","), self.pc))
		end
		icount = icount+1
		self.pc = self.pc+1
	end
	print(count, icount)
	return icount
end

function tsukiko.new_state(func)
	local env = {}
	local st = {
		env = env,
		upvalues = {[0]=env},
		locals = {},
		constants = func.const,
		register = {},
		pc = 0,
		code = func.code
	}
	return setmetatable(st, {__index=state})
end

tsukiko.state = state