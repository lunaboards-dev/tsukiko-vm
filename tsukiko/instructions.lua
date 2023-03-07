--print(tsukiko.version_string)
local function val(proc, v, mask, vmask)
	if v & mask > 0 then
		
		return proc.constants[(v & vmask)+1]
	end
	return proc.register[v & vmask]
end
ins "move" (function(vm, proc, a, b)
	proc.register[a] = proc.register[b]
end)


ins "loadk" (function(vm, proc, a, bx)
	proc.register[a] = proc.constants[bx+1]
	return true
end)

ins "loadkx" (function(vm, proc, a)
	proc.register[a] = proc.constants[proc:get_extra()+1]
end)

ins "loadbool" (function(vm, proc, a, b, c)
	proc.register[a] = b > 0
	if c then
		proc.pc = proc.pc+1
	end
end)

ins "loadnil" (function(vm, proc, a, b)
	for i=a, a+b do
		proc.register[i] = nil
	end
end)

ins "getupval" (function(vm, proc, a, b)
	--proc.register[a] = proc.upvalue[b]
end)



ins "gettabup" (function(vm, proc, a, b, c)
	--print(proc.upvalues[b], val(proc, c, 0x100, 0xFF))
	proc.register[a] = proc.upvalues[b][val(proc, c, 0x100, 0xFF)]
	return true
end)

ins "gettable" (function(vm, proc, a, b, c)

end)



ins "settabup" (function(vm, proc, a, b, c)

end)

ins "setupval" (function(vm, proc, a, b)

end)

ins "settable" (function(vm, proc, a, b, c)

end)



ins "newtable" (function(vm, proc, a, b, c)

end)




ins "self" (function(vm, proc, a, b, c)


end)



ins "add" (function(vm, proc, a, b, c)

end)

ins "sub" (function(vm, proc, a, b, c)

end)

ins "mul" (function(vm, proc, a, b, c)

end)

ins "mod" (function(vm, proc, a, b, c)

end)

ins "pow" (function(vm, proc, a, b, c)

end)

ins "div" (function(vm, proc, a, b, c)

end)

ins "idiv" (function(vm, proc, a, b, c)

end)

ins "band" (function(vm, proc, a, b, c)

end)

ins "bor" (function(vm, proc, a, b, c)

end)

ins "bxor" (function(vm, proc, a, b, c)

end)

ins "shl" (function(vm, proc, a, b, c)

end)

ins "shr" (function(vm, proc, a, b, c)

end)

ins "unm" (function(vm, proc, a, b)

end)

ins "bnot" (function(vm, proc, a, b)

end)

ins "not" (function(vm, proc, a, b)

end)

ins "len" (function(vm, proc, a, b)

end)



ins "concat" (function(vm, proc, a, b, c)

end)



ins "jmp" (function(vm, proc, a, sbx)

end)

ins "eq" (function(vm, proc, a, b, c)

end)

ins "lt" (function(vm, proc, a, b, c)

end)

ins "le" (function(vm, proc, a, b, c)

end)



ins "test" (function(vm, proc, a, c)

end)

ins "testset" (function(vm, proc, a, b, c)

end)



ins "call" (function(vm, proc, a, b, c)
	local f = proc.register[a]
	local t = type(f)
	--print(a, f)
	local params
	if b == 1 then
		params = {}
	else
		params = table.pack(table.unpack(proc.register, a+1, a+b-1))
	end
	if t == "function" then
		f(table.unpack(params))
	elseif t == "table" then

	end
	return true
end)

ins "tailcall" (function(vm, proc, a, b, c)

end)

ins "return" (function(vm, proc, a, b)
	proc.rtv = a
	proc.rtv_count = b-1
	return true
end)



ins "forloop" (function(vm, proc, a, sbx)

end)

ins "forprep" (function(vm, proc, a, sbx)

end)



ins "tforcall" (function(vm, proc, a, c)

end)

ins "tforloop" (function(vm, proc, a, sbx)

end)



ins "setlist" (function(vm, proc, a, b, c)

end)



ins "closure" (function(vm, proc, a, bx)

end)



ins "vararg" (function(vm, proc, a, b)

end)



ins "extraarg" (function(vm, proc, ax)
	vm:error("extraarg")
end)