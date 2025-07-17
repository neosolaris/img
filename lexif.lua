#!/usr/bin/env luajit
-- TITLE: Image Exif Info Manage Program
-- DATE: 2025-07-18 00:13:29
-- TODO: 

-- local lfs = require'lfs'
--
-- local function list_files(path)
-- 	local files = {}
-- 	for file in lfs.dir(path) do
-- 		if file ~= "." and file ~= ".." then
-- 			local fullpath = path .. '/' .. file
-- 			local attr = lfs.attributes(fullpath)
-- 			if attr and attr.mode == "file" then
-- 				table.insert(files, fullpath)
-- 			end
-- 		end
-- 	end
-- end
--

--// run_command(command)
local function run_command(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return result
end

local function show_help()
	print("Usage: lexif.lua <option> <files>")
	print("-h: help")
	print("-l <files>: list exif info")
	print("-s <keyword> <files>: search exif info")
end

local function list_info(optargs)
	local cmd = ''
	if #optargs == 0 then
		cmd = 'exiftool .'
	else
		cmd = 'exiftool ' .. table.concat(optargs, ' ')
	end
	local res = run_command(cmd)
	print(res)
end

local function search_info(optargs)
	local cmd = ''
	if #optargs == 0 then
		print('-> search_info: No Keyword!')
		return
	end

	if #optargs == 1 then
		local files = assert(io.popen("find . -type f -name '*.jpg'"))
		for file in files:lines() do
			cmd = 'exiftool ' ..file.. ' | grep -i ' .. optargs[1]
			local result = run_command(cmd)
			if result and result:match("^%s*$") == nil then
				print('==>',file)
				print(result)
			end
		end
	else
		cmd = 'exiftool ' ..optargs[2].. ' | grep -i ' .. optargs[1]
		local result = run_command(cmd)
		print(result)
	end
end


-----------------------------------------------------------------
-- # Main
-----------------------------------------------------------------
local optname = arg[1]
local optargs = {select(2,unpack(arg))}

if optname == '-l' then
	list_info(optargs)
elseif optname == '-s' then
	search_info(optargs)
else
	show_help()
end
