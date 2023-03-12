local proci = {}

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

local function makemask(m)
	local v = 0
	while m > 1 do
		v = (v << 1) | 1
		m = m >> 1
	end
	return v
end

function proci:value(v, mask)
	if v & mask > 0 then
		return self:constval(makemask(mask) & v)
	end
	return self:regval(v)
end

function proci:constval(v)
	return self.const[v+1]
end

function proci:regval(v)
	return self.register[v+1]
end

function proci:upvalue(v)

end

function proci:setupvalue(uv, val)

end

function proci:mapupvalue(uv, src, index)

end

function proci:call(register, argstart, argcount, returncount)
	local reg = self.register[register]
	local ftype = type(reg)
	if ftype == "function" then
		print("calling native", reg)
		local rtv = table.pack(reg(table.unpack(self.register, argstart, argstart+argcount-1)))
		for i=1, argcount do
			table.remove(self.register, argstart-1+argcount-i)
		end
		for i=1, returncount do
			table.insert(self.register, rtv[i])
		end
	elseif ftype == "table" and reg.__type == tsukiko.objtypes.proc then
		print("calling proc", reg)
		local instance = reg:instance()
		instance:apply(table.unpack(self.register, argstart, argstart+argcount-1))
		for i=1, argcount do
			table.remove(self.register, argstart-1+argcount-i)
		end
		self.calling = instance
		self.rtvcount = returncount
		local rtv = table.pack(instance:step(self.maxcount-self.icount))
		if type(rtv[1] == "nil") then
			self.error = rtv[2]
		elseif rtv[1] then
			for i=1, returncount do
				table.insert(self.register, rtv[i+1])
			end
			self.icount = self.icount + self.calling.icount
		else
			self.icount = self.icount + rtv[2]
		end
	else
		tsukiko.error(self, "UNKNOWN PROC TYPE: "..ftype)
	end
end

function proci:apply(...)
	local t = table.pack(...)
	for i=1, t.n do
		table.insert(self.register, t[i])
	end
	return #self.register
end

function proci:step(count)
	count = count or math.huge
	self.icount = 0
	self.maxcount = count
	if self.calling then
		local rtv = table.pack(self.calling:step())
		local rtv = table.pack(self.calling:step(self.maxcount-self.icount))
		if type(rtv[1] == "nil") then
			return nil, rtv[2]
		elseif rtv[1] then
			for i=1, self.rtvcount do
				table.insert(self.register, rtv[i+1])
			end
			self.icount = self.icount + self.calling.icount
			self.calling = nil
		else
			self.icount = self.icount + rtv[2]
			return self.icount
		end
	end
	local ins = {}
	local args = {}
	while count > self.icount do
		decode_ins(self.code, (self.pc*4)+1, ins)
		local ix = tsukiko.instructions[ins.op]
		for i=1, ix.regs.n do
			args[i] = ins[ix.regs[i]]
		end
		print(ix.name, table.unpack(args))
		if not ix.func(self.vm, self, table.unpack(args)) then
			error(string.format("UNIMPLEMENTED: %s(%s) pc: %x", ix.name, table.concat(ix.regs, ","), self.pc))
		end
		
		args[1], args[2], args[3] = nil,nil,nil
		self.icount = self.icount+1
		self.pc = self.pc+1
		if self.rtv then
			--print(self.register, self.rtv, self.rtv+self.rtv_count-1)
			--print(table.unpack(self.register, self.rtv, self.rtv+self.rtv_count-1))
			local rpos, rcount = self.rtv, self.rtv_count
			self.rtv, self.rtv_count = nil, nil
			if rcount == 0 then
				return true
			end
			return true, table.unpack(self.register, rpos, rpos+rcount-1)
		end
	end
	return false, self.icount
end

return proci