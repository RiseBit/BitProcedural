# BitProceural
A simple and efficient procedural generation library for Roblox.

## 🚀 Features
- **Easy to Use**: Simple API for quick integration
- **Lightweight**: Minimal performance impact
- **Customizable**: Flexible parameters for different generation needs
- **Type-Safe**: Uses Luau type annotations for better code reliability and IntelliSense support.

## 📦 Installation
1. Get the library from the Roblox library: `[Library ID]`
2. Require it in your script:
```lua
local bitProcedural = require(path.to.BitProceural)
```
3. just pass a a Table of Config like this
```lua
bitProcedural.RockPropel({
originPos = HRP.Position,
minAmount = 5,
maxAmount = 15,
radius = 12,
size = Vector3.new(2,2,3),
force = 25,
material = Enum.Material.Rock
})
