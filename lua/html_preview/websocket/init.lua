local websocketKey = require('html_preview.websocket.sha1')
local utils = require('html_preview.websocket.utils')
local bit = require('bit')

local encode_header_small = function(header, payload)
	return string.char(header, payload)
end

local encode_header_medium = function(header, payload, len)
	return string.char(header, payload, bit.band(bit.rshift(len, 8), 0xFF), bit.band(len, 0xFF))
end

local encode_header_big = function(header, payload, high, low)
	return string.char(header, payload) .. utils.write_int32(high) .. utils.write_int32(low)
end

local frame = function(data)
	local header = 1
	header = bit.bor(header, 128)
	local payload = 0
	local len = #data
	local chunks = {}
	if len < 126 then
		payload = bit.bor(payload, len)
		table.insert(chunks, encode_header_small(header, payload))
	elseif len <= 0xffff then
		payload = bit.bor(payload, 126)
		table.insert(chunks, encode_header_medium(header, payload, len))
	elseif len < 2 ^ 53 then
		local high = math.floor(len / 2 ^ 32)
		local low = len - high * 2 ^ 32
		payload = bit.bor(payload, 127)
		table.insert(chunks, encode_header_big(header, payload, high, low))
	end
	table.insert(chunks, data)
	return table.concat(chunks)
end

local is_close = function(data)
	local header = string.byte(data, 1)
	local opcode = bit.band(header, 8)
	return opcode == 8
end

local handshake = function(key)
	local accept = websocketKey(key)
	local lines = {
		'HTTP/1.1 101 Switching Protocols',
		'Upgrade: websocket',
		'Connection: Upgrade',
    string.format('Sec-WebSocket-Accept: %s', accept),
	}

	table.insert(lines, '\r\n')
	return table.concat(lines, '\r\n')
end

return {
	frame = frame,
	handshake = handshake,
	is_close = is_close,
}
