-- TITLE: Image Exif Info Manage Program
-- DATE: 2025-07-18 00:13:29
-- TODO: 
-- - getopt 적용하기, search_info를 더 정교하게 하고 -i 옵션도 처리할 수 있도록 하자, 코드 효율화
-- + exiftool 존재 여부 체크
-- - metadata 만들고 이를 관리하기: 보류: 그림 파일마다 메타데이터가 다르다. csv 시 문제 발생
-- - ImageDescription 위주로 관리하는 것이 바람직, 아니면 내가 필요한 요소 몇개만 테이블로 관리가 바람직
-- REQUIREMENT:
-- - exiftool

local m = require'lim'

local p = m.path(arg[0])
local version = '0.1'

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
local function search_info(optargs)
	optargs = optargs or {}
	local res = m.cmd("exiftool -s -s -ImageDescription .")
	local fname, desc
	-- line parsing
	for i,line in ipairs(res) do
		if line:find('^=') then
			fname = string.match(line, "^=+%s+(.*)$")
		else
			desc = string.match(line, "^ImageDescription:%s*(.*)")
		end
		-- filtering filename, imagedescription from each 2 lines
		if i % 2 == 0 and fname and desc then
			-- search keys in fname, desc
			if next(optargs) then
				for key in m.each(optargs) do
					if fname:find(string.lower(key)) or desc:find(string.lower(key)) then
						print(fname .. ' : ' .. desc)
					end
				end
			else
				print(fname .. ' : ' .. desc)
			end
		end
	end
end



local function get_imgdesc(optargs)
	local cmd_pre = 'exiftool -s -s -s -ImageDescription'
	local cmd_last = '.'

	if next(optargs) then
		cmd_last = m.catlist(optargs)
	end

	local cmd = m.strf("%s %s", cmd_pre, cmd_last)
	--print('--> get_imgdesc:', cmd)
	--print(cmd)
	local result = m.cmd(cmd)
	return result
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

local function show_help()
	local list = {
	"----------------------------------------",
	m.strf("%s v%s Brosu", p.name, version),
	"----------------------------------------",
	m.strf("Usage: %s <option> <files>", p.name),
	"  -h: help",
	"  -f <path>   list image files",
	"  -l <files>  list exif info",
	"  -i <files>  show ImageDescription info",
	"  -I <files>  edit ImageDescription info",
	"  -s <keyword> <path> search exif info (no keyword: show ImageDesciption all files)",
	"  -m {img_dir} create metadata.csv from img_dir",
}
	m.printl(list)
end

-----------------------------------------------------------------
-- # Main
-----------------------------------------------------------------
-- check exiftool installed
local is_exif = m.which('exiftool')
m.printf('check exiftool: ')
if not is_exif then
	print('Fail')
	print('[exiftool] is not exist. Install first, please!')
	os.exit(1)
end
print('OK')


local optname = arg[1]
local optargs = {select(2,unpack(arg))}

if optname == '-l' then
	list_info(optargs)
elseif optname == '-s' then
	search_info(optargs)
elseif optname == '-f' then
	local keys = {'*.jpg','*.png','*.tif'}
	m.printl(m.lsf('.', keys))
-- Get ImageDescription
elseif optname == '-i' then
	show_imgdesc(optargs)
-- Put ImageDescription
elseif optname == '-I' then
	change_imgdesc(optargs)
elseif optname == '-m' then
	create_metacsv(optargs[1])
else
	show_help()
end
