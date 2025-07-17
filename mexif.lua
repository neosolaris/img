#!/usr/bin/env luajit

local function show_help()
	print(string.format("Usage: %s *.jpg"))
end

local function run_command(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

local function list_info()
	-- check input is dot
	local is_dot = false
	local fargs = {}
	for i=2,#arg do
		if arg[i] == '.' then
			is_dot = true
		else
			table.insert(fargs,arg[i])
		end
	end

	local cmd = ''
	if is_dot then 
		cmd = 'exiftool .'
	else 
		cmd = 'exiftool ' .. table.concat(fargs, ' ')
	end
	--print(cmd)
	local res = run_command(cmd)
	print(res)
end

-- # Main
if #arg == 0 then
	show_help()
elseif arg[1] == '-l' then
	list_info()
end
