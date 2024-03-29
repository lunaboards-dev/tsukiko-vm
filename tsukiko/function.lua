local func = {}

function func.load_string(str, next)
	local size, next = string.unpack("B", str, next)
	if size == 0xFF then
		size, next = string.unpack("T", str, next)
	end
	local s = str:sub(next, next+size-2)
	next = next+math.max(size-1, 0)
	return s, next
end

function func.load_code(str, next)
	local n, next = string.unpack("i", str, next)
	local code = str:sub(next, next+(n*4)-1)
	next = next + (n*4)
	return code, next
end

function func.load_protos(str, next)
	local protos = {}
	tsukiko.dprint(string.format("%.x", next))
	local n, next = string.unpack("i", str, next)
	tsukiko.dprint(n)
	for i=1, n do
		local p
		tsukiko.dprint(string.format("%.x", next))
		p, next = func.load(str, next)
		protos[i] = p
	end
	return protos, next
end

local function tostr(v)
	--[[if v == nil then
		return "nil"
	elseif type(v) == "table" then
		return tostring(v)
	else]]
		return string.format("%q", v)
	--end
end

function func.load_constants(str, next)
	local consts = {}
	local n, next = string.unpack("i", str, next)
	consts.n = n
	for i=1, n do
		local t
		t, next = string.unpack("B", str, next)
		if t == tsukiko.types.tnil then
			consts[i] = nil
		elseif t == tsukiko.types.tbool then
			consts[i] = str:byte(next) > 0
			next = next + 1
		elseif t == tsukiko.types.tnumflt then
			consts[i], next = string.unpack("n", str, next)
		elseif t == tsukiko.types.tnumint then
			consts[i], next = string.unpack("j", str, next)
		elseif t & 0x4 == tsukiko.types.tstring then
			consts[i], next = func.load_string(str, next)
		else
			error("unknown constant type "..string.format("%x", t))
		end
		--tsukiko.dprint(string.format("%.4x\t%s", i, tostr(consts[i])))
	end
	return consts, next
end

local function dstr(s)
	tsukiko.dprint(string.format(string.rep("%.2x", #s), s:byte(1, #s)))
end

function func.load_upvalues(str, next)
	local uvs = {}
	local n, next = string.unpack("i", str, next)
	--tsukiko.dprint(n)
	for i=1, n do
		local instack, idx
		instack, idx, next = string.unpack("BB", str, next)
		uvs[i] = {
			instack = instack,
			idx = idx
		}
	end
	return uvs, next
end

function func.load_debug(uv, str, next)
	local line_info = {}
	local n
	n, next = string.unpack("i", str, next)
	local linfo = str:sub(next, next+(n*4)-1)
	next = next + (n*4)

	n, next = string.unpack("i", str, next)

	local locvars = {}

	for i=1, n do
		local lv = {}
		lv.name, next = func.load_string(str, next)
		lv.startpc, lv.endpc, next = string.unpack("II", str, next)
		locvars[i] = lv
	end

	n, next = string.unpack("i", str, next)

	if n > #uv then
		error("upvalue debug array larger than upvalues")
	end

	for i=1, n do
		uv[i].name, next = func.load_string(str, next)
	end

	return linfo, locvars, next
end

function func.load(str, next)
	local src, code, const, uvs, protos, linfo, locvars
	src, next = func.load_string(str, next or 1)
	tsukiko.dprint("src", src)
	local line_defined, last_line_defined, num_params, is_va, max_stack, next = string.unpack("iiBBB", str, next)
	tsukiko.dprint("line", line_defined)
	tsukiko.dprint("last line", last_line_defined)
	tsukiko.dprint("num params", num_params)
	tsukiko.dprint("is vararg", is_va)
	tsukiko.dprint("max_stack", max_stack)
	code, next = func.load_code(str, next)
	const, next = func.load_constants(str, next)
	tsukiko.dprint("constants:")
	for i=1, const.n do tsukiko.dprint(i, string.format("%s", tostr(const[i]))) end
	uvs, next = func.load_upvalues(str, next)
	protos, next = func.load_protos(str, next)
	linfo, locvars, next = func.load_debug(uvs, str, next)
	tsukiko.dprint("locals:")
	for i=1, #locvars do tsukiko.dprint(string.format("%s\t%x\t%x", locvars[i].name, locvars[i].startpc, locvars[i].endpc)) end
	tsukiko.dprint("upvalues:")
	for i=1, #uvs do tsukiko.dprint(string.format("%s\t%x\t%x", uvs[i].name, uvs[i].instack, uvs[i].idx)) end
	local npos = 1
	local ins = {}
	local args = {}
	while code:sub(npos, npos+3) ~= "" do
		npos = tsukiko.decode_ins(code, npos, ins)
		--tsukiko.dprint(ins.op)
		local iname = tsukiko.ilist[ins.op]
		local idat = tsukiko.instructions[ins.op]
		local regs = idat.regs
		for i=1, #regs do
			table.insert(args, ins[regs[i]])
		end
		tsukiko.dprint("% "..iname, table.unpack(args))
		args[1] = nil
		args[2] = nil
		args[3] = nil
	end
	return setmetatable({
		code = code,
		const = const,
		uvs = uvs,
		protos = protos,
		linfo = linfo,
		locvars = locvars
	}, {__dtype=tsukiko.objtypes.func}), next
end


return func