local request = {
	new = function(obj, chunk)
		obj = {
			headers = {},
			method = "",
			file = "",
			version = "",
		}
		for line in chunk:gmatch("[^\r\n]+") do
			if line then
				local colon = line:find(":")
				if colon then
					obj.headers[line:sub(1, colon - 1)] = line:sub(colon + 2)
				else
					obj.method, obj.file, obj.version = line:match("([^ ]+) ([^ ]+) ([^ ]+)")
				end
			end
		end

		return obj
	end,
}

return request
