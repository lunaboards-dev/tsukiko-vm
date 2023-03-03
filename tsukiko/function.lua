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
	print(string.format("%.x", next))
	local n, next = string.unpack("i", str, next)
	print(n)
	for i=1, n do
		local p
		print(string.format("%.x", next))
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
		--print(string.format("%.4x\t%s", i, tostr(consts[i])))
	end
	return consts, next
end

local function dstr(s)
	print(string.format(string.rep("%.2x", #s), s:byte(1, #s)))
end

function func.load_upvalues(str, next)
	local uvs = {}
	local n, next = string.unpack("i", str, next)
	--print(n)
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
	print("src", src)
	local line_defined, last_line_defined, num_params, is_va, max_stack, next = string.unpack("iiBBB", str, next)
	print("line", line_defined)
	print("last line", last_line_defined)
	print("num params", num_params)
	print("is vararg", is_va)
	print("max_stack", max_stack)
	code, next = func.load_code(str, next)
	const, next = func.load_constants(str, next)
	print("constants:")
	for i=1, const.n do print(i, string.format("%s", tostr(const[i]))) end
	uvs, next = func.load_upvalues(str, next)
	protos, next = func.load_protos(str, next)
	linfo, locvars, next = func.load_debug(uvs, str, next)
	print("locals:")
	for i=1, #locvars do print(string.format("%s\t%x\t%x", locvars[i].name, locvars[i].startpc, locvars[i].endpc)) end
	print("upvalues:")
	for i=1, #uvs do print(string.format("%s\t%x\t%x", uvs[i].name, uvs[i].instack, uvs[i].idx)) end
	return {
		code = code,
		const = const,
		uvs = uvs,
		protos = protos,
		linfo = linfo,
		locvars = locvars
	}, next
end


return func