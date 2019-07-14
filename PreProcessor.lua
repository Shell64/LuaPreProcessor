--[[
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
]]

local PreProcessor = {}

local Error = error
local FileSystem_Read
local LoadString = loadstring
local Table_Concatenate = table.concat
local String_Byte = string.byte
local String_Find = string.find
local String_Format = string.format
local String_GMatch = string.gmatch
local String_Substring = string.sub
local Type = type
local Global = _G
local Pairs = pairs
local SetFunctionEnvironment = setfenv
local ToString = tostring

local CurrentEnvironment = Global

local function ToByteString(Str)
	local NewStr = ""
	
	for I = 1, #Str do
		NewStr = NewStr .. "\\" .. String_Byte(String_Substring(Str, I, I))
	end
	
	return NewStr
end

local function include(Path)
	local Data, Err = FileSystem_Read(Path)
	
	if Data then
		local Blocks = {}
		
		do
			local I = 1
			local MaxI = #Data
			
			while I <= MaxI do
				local Char = String_Substring(Data, I, I)
				
				if Char == "\"" or Char == "'" then
					local BlockEnd = String_Find(Data, Char, I + 1, true)
				
					while BlockEnd and String_Substring(Data, BlockEnd - 1, BlockEnd - 1) == "\\" do
						local Count = 0
						for J = BlockEnd - 1, I + 1, -1 do
							if String_Substring(Data, J, J) == "\\" then
								Count = Count + 1
							else
								break
							end
						end
						
						if Count % 2 == 1 then
							BlockEnd = String_Find(Data, Char, BlockEnd + 1, true)
						else
							BlockEnd = String_Find(Data, Char, I + 1, true) + 1
						end
					end
					
					if BlockEnd then
						Blocks[#Blocks + 1] = {1, I, BlockEnd}
						I = BlockEnd
					else
						Blocks[#Blocks + 1] = {1, I, #Data}
						I = #Data
					end
				elseif Char == "-" and String_Substring(Data, I + 1, I + 1) == "-" then
					if String_Substring(Data, I + 2, I + 2) == "[" then
						local Next = I + 3
						
						local Equals = ""
						local Found = false
						while not Found do
							local Char2 = String_Substring(Data, Next, Next)
							
							if not Char2 then
								Blocks[#Blocks + 1] = {2, I, #Data}
								I = #Data
							elseif Char2 == "=" then
								Equals = Equals .. "="
							elseif Char2 == "[" then
								break
							else
								Blocks[#Blocks + 1] = {2, I, #Data}
								I = #Data
							end
							
							Next = Next + 1
						end
						
						local _, BlockEnd = String_Find(Data, "]" .. Equals .. "]", Next, true)
						
						if not BlockEnd then
							Blocks[#Blocks + 1] = {2, I, #Data}
							I = #Data
						else
							Blocks[#Blocks + 1] = {2, I, BlockEnd}
							I = BlockEnd
						end
					else
						local BlockEnd = String_Find(Data, "\n", I + 2, true)
							
						if BlockEnd then
							Blocks[#Blocks + 1] = {2, I, BlockEnd}
							I = BlockEnd
						else
							Blocks[#Blocks + 1] = {2, I, #Data}
							I = #Data
						end
					end
				end
				
				I = I + 1
			end
		end
		
		local LocalDefined = false
		local Chunk = {"local Output = \"\" "}
		
		local LineStart = 1
		local LineEnd = String_Find(Data, "\n", nil, true)
		
		if not LineEnd then
			LineEnd = #Data + 1
		end
			
		while LineEnd do
			local Line = String_Substring(Data, LineStart, LineEnd - 1)
			
			local CodeBegin, CodeEnd = String_Find(Line, "%@")
			
			if CodeBegin then
				local TempCodeBegin = LineStart + CodeBegin
				
				for I = 1, #Blocks do
					if TempCodeBegin >= Blocks[I][2] and TempCodeBegin <= Blocks[I][3] then
						CodeBegin = nil
						break
					end
				end
			end
			
			if CodeBegin then
				Chunk[#Chunk + 1] = String_Substring(Line, CodeEnd + 1) .. "\n"
			else
				local LastCodeEnd = 0
				local CodeBegin, CodeEnd = String_Find(Line, "%$(%b())()")
				
				while CodeBegin do
					local TempCodeBegin = LineStart + CodeBegin
					
					for I = 1, #Blocks do
						if Blocks[I][1] == 2 and TempCodeBegin >= Blocks[I][2] and TempCodeBegin <= Blocks[I][3] then
							CodeBegin = nil
							break
						end
					end
					
					if CodeBegin then
						local NewCodeBegin = String_Find(String_Substring(Line, CodeBegin + 1, CodeEnd), "$", nil, true)
						
						if NewCodeBegin then
							CodeBegin = CodeBegin + NewCodeBegin
						end
						
						local BeforeString = String_Substring(Line, LastCodeEnd + 1, CodeBegin - 1)
						local AfterString = String_Substring(Line, CodeBegin + 1, CodeEnd)
						
						if BeforeString ~= "" then
							Chunk[#Chunk + 1] = String_Format("Output = Output .. \"%s\"", ToByteString(BeforeString))
						end
						
						Chunk[#Chunk + 1] = String_Format(" Output = Output ..  %s ", AfterString)
						
						LastCodeEnd = CodeEnd
					end
					
					CodeBegin, CodeEnd = String_Find(Line, "%$(%b())()", CodeEnd + 1)
				end
				
				if LastCodeEnd < #Line then
					Chunk[#Chunk + 1] = String_Format("Output = Output .. \"%s\"", ToByteString(String_Substring(Line, LastCodeEnd + 1)))
				end
				
				Chunk[#Chunk + 1] = " Output = Output .. \"\\n\"\n"
			end
			
			if LineEnd == #Data + 1 then
				break
			end
			
			LineStart = LineEnd + 1
			LineEnd = String_Find(Data, "\n", LineEnd + 1, true)
			
			if not LineEnd then
				LineEnd = #Data + 1
			end
		end
		
		Chunk[#Chunk + 1] = "return Output\n"
		
		local ConcatenatedChunk = Table_Concatenate(Chunk)
		local Func, Err = LoadString(ConcatenatedChunk, Path)
		
		if Func then
			SetFunctionEnvironment(Func, CurrentEnvironment)
			return Func()
		else
			Error("Could not load include (" .. Path .. "). Error: " .. Err)
		end
	else
		Error("Could not include (" .. Path .. ") Error: " .. ToString(Err))
	end
end

function PreProcessor.ReplaceFileSystemReadFunction(ReadFunction)
	FileSystem_Read = ReadFunction
end

function PreProcessor.PrepareEnvironment(Tab)
	Tab.include = include
end

function PreProcessor.GenerateCode(Path, Environment)
	CurrentEnvironment = Environment or Global
	return include(Path)
end

return PreProcessor
