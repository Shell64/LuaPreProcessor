# Lua code preprocessor for LÖVE Framework
===========
It's mainly made to be used with löve framework, but if you provide your own filesystem operation functions it can work with any Lua platform.

Quick Implementation
===========
```lua
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

The code is based in SimplePreProcessor so it does share similar syntax when in use such as:

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

This preprocessor supports string and comments blocks, except for the $(code) syntax, it will work anywhere and you must prepare your strings for this as well (or it might be replaced). @line codes works with comments and string blocks, it won't run as code if it's inside a string or comment block.

There's a built in function for including files, use it

```lua
$(include("path.lua"))
```

Library Functions
===========
```lua
--Use the following function to copy useful functions like include to your preprocessing environment:
PreProcessor.PrepareEnvironment(EnvironmentTable or _G)

--Use this function for preprocessing your code and returning it as a string, the path provided must contain the extension.
StringCode = PreProcessor.GenerateCode(Path, EnvironmentTable or _G)
```

