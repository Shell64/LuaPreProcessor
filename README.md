# Lua preprocessor

It's mainly made to be used with löve framework, but if you supply your own filesystem operation functions it can work with any Lua platform.

Quick Implementation
===========
```lua
--Supply filesystem.read. Might return DataStringOrNil, ErrorString  to work
PreProcessor.ReplaceFileSystemReadFunction(love.filesystem.read)

local PreProcessor = require("PreProcessor")
PreProcessor.PrepareEnvironment(_G)

local GeneratedCode = PreProcessor.GenerateCode("MyFile.lua", _G)
local CompiledCode, Err = loadstring(GeneratedCode)

if CompiledCode then
	CompiledCode()
else
	error("Could not compile code. Error: " .. Err)
end
```

The code is based in SimpleLuaPreprocessor so it does share similar syntax when in use such as:

```lua
@for i = 1, 5 do
  print($(i))
@end
```

will compile to

```lua
print(1)
print(2)
print(3)
print(4)
print(5)
```

This preprocessor supports string and comments blocks, except for the $(code) syntax, it will work except inside comment blocks. Strings will be parsed as such. @line codes will be ignored in comments and string blocks.

There's a built in function for including files, use it

```lua
$(include("path.lua"))
```

Library Functions
===========
```lua
--Supply your own filesystem.read function that returns DataStringOrNil, ErrorString to work on different platforms:
PreProcessor.ReplaceFileSystemReadFunction(Func)
--Use the following function to copy useful functions like include to your preprocessing environment:
PreProcessor.PrepareEnvironment(EnvironmentTable or _G)

--Use this function for preprocessing your code and returning it as a string, the path provided must contain the extension.
StringCode = PreProcessor.GenerateCode(Path, EnvironmentTable or _G)
```

