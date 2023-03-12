local proc = {}

local proc_instance = require("tsukiko.procinstance")

function proc:mapupvalue(uv, src, index)
	self.upvals[uv+1] = {src, index}
end

function proc:instance()
	return setmetatable({
		upvals = self.upvals,
		proc = self,
		code = self.func.code,
		const = self.func.const,
		protos = self.func.protos,
		register = {},
		env = self.env,
		pc = 0,
		vm = self.state
	}, {
		__index = proc_instance
	})
end

return proc