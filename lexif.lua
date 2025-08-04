-- TITLE: Image Exif Info Manage Program
-- DATE: 2025-07-18 00:13:29
-- TODO: 
-- - getopt 적용하기, search_info를 더 정교하게 하고 -i 옵션도 처리할 수 있도록 하자, 코드 효율화
-- + exiftool 존재 여부 체크
-- - metadata 만들고 이를 관리하기: 보류: 그림 파일마다 메타데이터가 다르다. csv 시 문제 발생
-- - ImageDescription 위주로 관리하는 것이 바람직, 아니면 내가 필요한 요소 몇개만 테이블로 관리가 바람직
-- REQUIREMENT:
-- - exiftool

local optparse = require'optparse'
--local m = require'lim'
local mio = require'mio'
local mstr = require'mstr'

local function list_info(optargs)
	local cmd = ''
	if next(optargs) then
		cmd = 'exiftool ' .. m.catlist(optargs)
	else
		cmd = 'exiftool .'
	end
	--print(cmd)
	--local res = m.cmd(cmd)
	m.printl(m.cmd(cmd))
end

-- search info by keywords
local function search_info_(optargs)
	optargs = optargs or {}
	local res = m.cmd("exiftool -s -s -ImageDescription .")
	local fname, fname_lower, desc, desc_lower
	local TAG = false
	-- line parsing
	for line in m.each(res) do
		if line:find('^=') then
			fname = string.match(line, "^=+%s+(.*)$")
			fname_lower = string.lower(fname)
		elseif line:find('^ImageDescription:') then
			desc = string.match(line, "^ImageDescription:%s*(.*)")
			desc_lower = string.lower(desc)
			TAG = true
		end
		-- filtering filename, imagedescription from each 2 lines
		if TAG and fname and desc then
			-- search keys in fname, desc
			if next(optargs) then
				for key in m.each(optargs) do
					if fname_lower:find(string.lower(key)) or desc_lower:find(string.lower(key)) then
						print(fname .. ' : ' .. desc)
					end
				end
			else
				print(fname .. ' : ' .. desc)
			end
			TAG = false
		end
	end
end

-- search info by keywords
local function search_info(optargs)
	optargs = optargs or {}
	local res = m.cmd("exiftool -s -s -ImageDescription .")
	local fname, desc
	local TAG = false
	local total = 0
	-- line parsing
	for line in m.each(res) do
		if line:find('^=') then
			fname = string.match(line, "^=+%s+(.*)$")
		elseif line:find('^ImageDescription:') then
			desc = string.match(line, "^ImageDescription:%s*(.*)")
			TAG = true
		end
		-- filtering filename, imagedescription from each 2 lines
		if TAG and fname and desc then
			-- search keys in fname, desc
			if next(optargs) then
				for key in m.each(optargs) do
					local ikey = m.ipattern(key)
					if fname:find(ikey) or desc:find(ikey) then
						print(fname .. ' : ' .. desc)
						total = total + 1
					end
				end
			else
				print(fname .. ' : ' .. desc)
				total = total + 1
			end
			TAG = false
		end
	end
	m.printf('\n* total: %s\n', total)
end

local function show_imgdesc(optargs)
	m.printl(get_imgdesc(optargs))
end

local function cid(file)
	if not file then return false end
	-- show input
	local result = get_imgdesc({file})
	m.printf("%s: %s\n", file, m.catlist(result))
	local input = m.read('ImageDescription: ')
	-- get input
	local cmd = m.strf("exiftool -overwrite_original -ImageDescription='%s' %s", input, file)
	m.printl(m.cmd(cmd))
end

local function change_imgdesc(optargs)
	if #optargs == 0 then
		local files = list_imgfiles(optargs)
		for file in m.iterlist(files) do
			cid(file)
		end
	elseif #optargs == 1 then
		if m.isdir(optargs[1]) then
			path = optargs[1]
			local files = m.lfs(path)
			for _,file in ipairs(files) do
				cid(file)
			end
		elseif m.isfile(optargs[1]) then
			--print(optargs[1], 'is file!')
			cid(optargs[1])
		else
			print('--> optargs is wrong!')
			os.exit(1)
		end
	else
		for file in m.each(optargs) do
			cid(file)
		end
	end
end

local function create_metacsv(optargs)
	local cmd = ''
	if next(optargs) then
		cmd = string.format('exiftool -csv -r %s > metadata.csv', m.catlist(optargs))
	else
		cmd = 'exiftool -csv -r . > metadata.csv'
	end
	print('-> create_metacsv:', cmd)
	local result = m.cmd(cmd)
	if result then print("--> create_metacsv(): metadata.csv created!") end
end

local function list_files()
	local filelist = {}
	local exts = {'.jpg','.png','.tif'}
	local filter = function(p) return mio.filter_ext(p,exts) end
	local ok, result = pcall(function()
		mio.lsf('.',filelist,filter)
	end)

	if not ok then
		print(result)
	else
		for _, file in ipairs(filelist) do
			print(file)
		end
		print('\ntotal: ', #filelist)
	end
end

-- get value by key in line (line:string, key:string, sep:string)
local function get_val_key(line, key, sep)
	sep = sep or ':'
    -- 키워드와 ':' 사이의 공백을 고려하여 패턴을 생성
    local pattern = key .. "%s*" .. sep .. "%s*(.+)"
    -- 패턴에 맞는 값을 추출
    return line:match(pattern)
end

-- get imgdesc info by keywords (res:table, keys:string or table)
local function get_imgdesc(res, keys)
	res = res or {}
	if #res == 0 then
		print('get_imgdesc: res is empty!')
		return
	end
	keys = keys or {}
	if type(keys) == 'string' then keys = {'keys'} end

	local result = {}
	local fname, desc
	local TAG = false
	local total = 0

	-- line parsing
	for _,line in ipairs(res) do
		if line:find('^=') then
			fname = string.match(line, "^=+%s+(.*)$")
		elseif line:find('^Image Description') then
			--desc = string.match(line, "%s*:%s*(.+)")
			desc = mstr.getval(line, '^Image Description', ':')
			TAG = true
		end
		-- filtering filename, imagedescription from each 2 lines
		if TAG and fname and desc then
			-- search keys in fname, desc
			if next(keys) then
				for key in m.each(keys) do
					local ikey = m.ipattern(key)
					if fname:find(ikey) or desc:find(ikey) then
						-- print(fname .. ' : ' .. desc)
						table.insert(result, fname .. ' : ' .. desc)
						total = total + 1
					end
				end
			else
				-- print(fname .. ' : ' .. desc)
				table.insert(result, fname .. ' : ' .. desc)
				total = total + 1
			end
			TAG = false
		end
	end
	return result
end

local function list_exifinfo(args)
	local cmd = ''
	args = args or {}

	if #args == 0 then
		cmd = 'exiftool .'
	else
		cmd = 'exiftool ' .. table.concat(args,' ')
	end

	local result = mio.cmd(cmd)

	for _,v in ipairs(result) do
		print(v)
	end
	--print(cmd)
end

local function list_imgdesc(args)
	local cmd_exif = 'exiftool '
	local cmd
	args = args or {}

	if #args == 0 then
		cmd = cmd_exif .. '.'
	elseif #args == 1 then
		if mio.isdir(args[1]) then
			cmd = cmd_exif .. args[1]
		elseif mio.isfile(args[1]) then
			cmd = cmd_exif .. '-s -s -s -ImageDescription ' .. args[1]
			local res = mio.cmd(cmd)
			print(args[1] .. ' : ' .. res[1])
			os.exit(0)
		else
		 	print("list_imgdesc(): It's not dir or file: " .. args[1])
			os.exit(1)
		end
	else
		cmd = cmd_exif .. table.concat(args,' ')
	end

	local res = mio.cmd(cmd)
	local result = get_imgdesc(res)
	for _,v in ipairs(result) do
		print(v)
	end
	--print(cmd)
end

local help = [[
lexif (Lua Exif Imagedescription Tool) v0.1

Copyright © 2025 Borisu
This test program comes with ABSOLUTELY NO WARRANTY.

Usage: lexif [<options>] <file>...

Banner Text
Long description .....

Options:

  -h, --help         display this help, then exit
  -e, --edit         Edit ImageDescription (dir or file[s])
  -f, --files        List image files (dir)
  -i, --info         List exif all info data (dir or file[s])
  -l, --list         List exif ImageDescription (dir or file[s])
  -s, --search=KEY   Search ImageDescription
      --version      display version information, then exit
  -v, --view         View ImageDescription

]]


-----------------------------------------------------------------
-- # Main
-----------------------------------------------------------------
-- check exiftool installed
local is_exif = mio.cmd('which exiftool')
if not is_exif then
	print('Check exiftool: Fail!')
	print('[exiftool] is not exist. Install first, please!')
	os.exit(1)
end

local parser = optparse(help)
local args, opts = parser:parse(arg)


-- for k,v in pairs(opts) do print(k,v) end
-- for i,v in ipairs(args) do print(i,v) end

if opts.files then
	list_files()
elseif opts.info then
	list_exifinfo(args)
elseif opts.list then
	list_imgdesc(args)
elseif opts.edit then
	edit_imgdesc(args)
end

-- if  == '-l' then
-- 	list_info(optargs)
-- elseif optname == '-s' then
-- 	search_info(optargs)
-- elseif optname == '-f' then
-- 	local flist = m.lsf('.', {'*.jpg','*.png','*.tif'})
-- 	table.sort(flist)
-- 	m.printl(flist)
-- -- Get ImageDescription
-- elseif optname == '-i' then
-- 	search_info()
-- -- Put ImageDescription
-- elseif optname == '-I' then
-- 	change_imgdesc(optargs)
-- elseif optname == '-m' then
-- 	create_metacsv(optargs[1])
-- else
-- 	show_help()
-- end
