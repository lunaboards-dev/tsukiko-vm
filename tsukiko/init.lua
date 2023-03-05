local tsukiko = {}

tsukiko.version = {
	major = 5,
	minor = 3,
	release = 6,
	version_num = 503
}

tsukiko.version_string = string.format("Tsukiko %d.%d", tsukiko.version.major, tsukiko.version.minor)
tsukiko.release_string = string.format("%s.%d", tsukiko.version_string, tsukiko.version.release)
tsukiko.copyright = string.format("%s  Copyright (C) 2022 lunaboards-dev", tsukiko.release_string)

tsukiko.signature = "\x1bLua"

tsukiko.types = {
	tnil = 0,
	tbool = 1,
	tlightud = 2,
	tnumber = 3,
	tstring = 4,
	ttable = 5,
	tfunction = 6,
	tuserdata = 7,
	tthread = 8
}

tsukiko.types.tshrstr = tsukiko.types.tstring
tsukiko.types.tlngstr = tsukiko.types.tstring | (1 << 4)

tsukiko.types.tnumflt = tsukiko.types.tnumber
tsukiko.types.tnumint = tsukiko.types.tnumber | (1 << 4)

--[[local ilist = {
	"move",
	"loadi",
	"loadf",
	"loadk",
	"loadkx",
	"loadfalse",
	"lfalseskip",
	"loadtrue",
	"loadnil",
	"getupval",
	"setupval",
	"gettabup",
	"gettable",
	"geti",
	"getfield",
	"settabup",
	"settable",
	"seti",
	"setfield",
	"newtable",
	"self",
	"addk",
	"subk",
	"mulk",
	"modk",
	"powk",
	"divk",
	"idivk",
	"bandk",
	"bork",
	"bxork",
	"shri",
	"shli",
	"add",
	"sub",
	"mul",
	"mod",
	"pow",
	"div",
	"idiv",
	"band",
	"bor",
	"bxor",
	"shl",
	"shr",
	"mmbin",
	"mmbini",
	"mmbink",
	"unm",
	"bnot",
	"not",
	"len",
	"concat",
}]]

local ilist = {
	"move",
	"loadk",
	"loadkx",
	"loadbool",
	"loadnil",
	"getupval",

	"gettabup",
	"gettable",

	"settabup",
	"setupval",
	"settable",

	"newtable",

	"self",

	"add",
	"sub",
	"mul",
	"mod",
	"pow",
	"div",
	"idiv",
	"band",
	"bor",
	"bxor",
	"shl",
	"shr",
	"unm",
	"bnot",
	"not",
	"len",

	"concat",

	"jmp",
	"eq",
	"lt",
	"le",

	"test",
	"testset",

	"call",
	"tailcall",
	"return",

	"forloop",
	"forprep",

	"tforcall",
	"tforloop",

	"setlist",

	"closure",

	"vararg",

	"extraarg"
}

for i=1, #ilist do
	ilist[ilist[i]] = i-1
end

local instructions = {}

tsukiko.instructions = instructions
tsukiko.ilist = ilist

tsukiko.registers = {
	a = 1,
	b = 2,
	c = 4,
	bx = 8,
	sbx = 16,
	ax = 32,
	"a", "b", "c", "bx", "sbx", "ax"
}

local function ins(name)
	return function(func)
		local li = 3
		local wanted_regs = {}
		while true do
			local ln = debug.getlocal(func, li)
			if not ln or not tsukiko.registers[ln] then
				break
			end
			table.insert(wanted_regs, ln:lower())
			li = li+1
		end
		wanted_regs.n = #wanted_regs
		local insinfo = {
			regs = wanted_regs,
			func = func,
			name = name:lower()
		}
		instructions[ilist[name:lower()]] = insinfo
		--print(name, table.unpack(wanted_regs))
	end
end
_ENV.tsukiko = tsukiko
_ENV.ins = ins
require("tsukiko.instructions")
require("tsukiko.parser")
require("tsukiko.state")

function tsukiko.run(func, env)
	local dmp = string.dump(func)
	local func = tsukiko.parser.parse(dmp)
	local st = tsukiko.new_state(func)
	for k, v in pairs(env) do
		st.env[k] = v
	end
	print("!!! st:run()")
	return st:run()
end

return tsukiko