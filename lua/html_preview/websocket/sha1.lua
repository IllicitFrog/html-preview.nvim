local mime = require("mime")
local bit = require("bit")
local utils = require("html_preview.websocket.utils")


local sha1 = function(msg)
	local h0 = 0x67452301
	local h1 = 0xEFCDAB89
	local h2 = 0x98BADCFE
	local h3 = 0x10325476
	local h4 = 0xC3D2E1F0

	local bits = #msg * 8
	-- append b10000000
	msg = msg .. string.char(0x80)

	-- 64 bit length will be appended
	local bytes = #msg + 8

	-- 512 bit append stuff
	local fill_bytes = 64 - (bytes % 64)
	if fill_bytes ~= 64 then
		msg = msg .. string.rep(string.char(0), fill_bytes)
	end

	-- append 64 big endian length
	local high = math.floor(bits / 2 ^ 32)
	local low = bits - high * 2 ^ 32
	msg = msg .. utils.write_int32(high) .. utils.write_int32(low)

	assert(#msg % 64 == 0, #msg % 64)

	for j = 1, #msg, 64 do
		local chunk = msg:sub(j, j + 63)
		assert(#chunk == 64, #chunk)
		local words = {}
		local next = 1
		local word
		repeat
			next, word = utils.read_int32(chunk, next)
			table.insert(words, word)
		until next > 64
		assert(#words == 16)
		for i = 17, 80 do
			words[i] = bit.bxor(words[i - 3], words[i - 8], words[i - 14], words[i - 16])
			words[i] = bit.rol(words[i], 1)
		end
		local a = h0
		local b = h1
		local c = h2
		local d = h3
		local e = h4

		for i = 1, 80 do
			local k, f
			if i > 0 and i < 21 then
				f = bit.bor(bit.band(b, c), bit.band(bit.bnot(b), d))
				k = 0x5A827999
			elseif i > 20 and i < 41 then
				f = bit.bxor(b, c, d)
				k = 0x6ED9EBA1
			elseif i > 40 and i < 61 then
				f = bit.bor(bit.band(b, c), bit.band(b, d), bit.band(c, d))
				k = 0x8F1BBCDC
			elseif i > 60 and i < 81 then
				f = bit.bxor(b, c, d)
				k = 0xCA62C1D6
			end

			local temp = bit.rol(a, 5) + f + e + k + words[i]
			e = d
			d = c
			c = bit.rol(b, 30)
			b = a
			a = temp
		end

		h0 = h0 + a
		h1 = h1 + b
		h2 = h2 + c
		h3 = h3 + d
		h4 = h4 + e
	end

	h0 = bit.band(h0, 0xffffffff)
	h1 = bit.band(h1, 0xffffffff)
	h2 = bit.band(h2, 0xffffffff)
	h3 = bit.band(h3, 0xffffffff)
	h4 = bit.band(h4, 0xffffffff)

	return utils.write_int32(h0) .. utils.write_int32(h1) .. utils.write_int32(h2) .. utils.write_int32(h3) .. utils.write_int32(h4)
end

local websocketKey = function(key)
	local magic = sha1(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
	return (mime.b64(magic))
end

return websocketKey
