local bit = require("bit")

local write_int32 = function(v)
	return string.char(
		bit.band(bit.rshift(v, 24), 0xFF),
		bit.band(bit.rshift(v, 16), 0xFF),
		bit.band(bit.rshift(v, 8), 0xFF),
		bit.band(v, 0xFF)
	)
end

local read_n_bytes = function(str, pos, n)
	pos = pos or 1
	return pos + n, string.byte(str, pos, pos + n - 1)
end

local read_int32 = function(str, pos)
	local new_pos, a, b, c, d = read_n_bytes(str, pos, 4)
	return new_pos, bit.lshift(a, 24) + bit.lshift(b, 16) + bit.lshift(c, 8) + d
end

return { write_int32 = write_int32 , read_int32 = read_int32 }
