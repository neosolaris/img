#!/usr/bin/env luajit
-- mymodule_extractor.lua
local function extract_functions_and_variables(filename)
    local functions = {}
    local variables = {}

    for line in io.lines(filename) do
        -- 함수 추출
        local func_name = line:match("function%s+(%w+)")
        if func_name then
            table.insert(functions, func_name)
        end

        -- 변수 추출 (단순한 변수만 추출)
        for var in line:gmatch("(%w+)%s*=" do
            table.insert(variables, var)
        end
    end

    return functions, variables
end

local function write_to_file(functions, variables, output_filename)
    local file = io.open(output_filename, "w")
    if not file then
        error("Could not open file for writing: " .. output_filename)
    end

    file:write("-- Extracted Functions\n")
    for _, func in ipairs(functions) do
        file:write(func .. "\n")
    end

    file:write("\n-- Extracted Variables\n")
    for _, var in ipairs(variables) do
        file:write(var .. "\n")
    end

    file:close()
end

-- 명령줄 인자 처리
local input_filename = arg[1] or "mymodule.lua"  -- 기본값으로 mymodule.lua 사용
local output_filename = "a.out"

local functions, variables = extract_functions_and_variables(input_filename)
write_to_file(functions, variables, output_filename)

print("Extraction complete. Output written to " .. output_filename)
