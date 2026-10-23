# ModuleRelocator

**ModuleRelocator** relocates actual `ModuleScript` instances to a server-only location while leaving placeholder modules behind. This preserves existing `require()` paths while keeping server-dependent code out of client-replicated locations.

Designed for **Single Script Architecture (SSA)**, ModuleRelocator allows server and client modules to share a unified project structure without requiring separate folder hierarchies solely for replication purposes.

## Features

- **Module relocation** — Moves actual `ModuleScript` instances to a designated server-only container.
- **Placeholder preservation** — Keeps modules at their original locations to preserve existing module paths.
- **Configurable targeting** — Identifies modules using a configurable `CollectionService` tag.
- **Configurable destination** — Lets you choose where relocated modules are stored.
- **Unified architecture** — Organizes server and client modules under a shared hierarchy without needing duplicate server-only folder structures.

## Why ModuleRelocator?

In a typical Roblox project, server-only modules often need to be separated from replicated content. This can lead to duplicated folder hierarchies and make the project harder to navigate.

ModuleRelocator offers an alternative: **organize modules by functionality, then relocate server-only modules at runtime.**

### Example: Character combat modules

Suppose your character system contains a combat module at:

```text
ReplicatedStorage
└── Character
    └── Combat
        └── Punch
            └── Action (ModuleScript)
```

Without ModuleRelocator, you might create another `Characters` folder under `ServerStorage` to hold server-only combat logic.

With ModuleRelocator, you can keep the original project hierarchy and relocate the actual `Action` ModuleScript to a server-only container, leaving a placeholder at its original location.

This lets you organize your code around your game's architecture rather than its replication boundaries.

### Example: Unified service hierarchy

Instead of maintaining separate folder structures for server and client services, you can organize them together:

```text
ReplicatedStorage
└── Services
    ├── CharacterService
    ├── CombatService
    ├── InputService
    └── UIService
```

Server-dependent modules can be relocated to a server-only container, while client modules remain in their original locations.

This is particularly useful in SSA projects, where services and modules are managed through a centralized initialization workflow.

## Installation

1. Download [`ModuleRelocator.rbxm`](./ModuleRelocator.rbxm).
2. Import the model into Roblox Studio.
3. Configure the relocation tag and destination as needed.
4. Tag the `ModuleScript` instances you want to relocate.
5. Run ModuleRelocator on the server **before initialization begins**.

## Usage

Require ModuleRelocator from your server-side entry point and execute it before your loader or other systems begin requiring modules that will be relocated.

### Default configuration

```lua
local ModuleRelocator = require(path.to.ModuleRelocator)

ModuleRelocator.Relocate()
```

### Custom configuration

```lua
ModuleRelocator.Relocate({
    tag = "ServerModule",
    parent = game:GetService("ServerStorage"),
})
```

| Option | Default | Description |
|---|---|---|
| `tag` | `"ServerModule"` | The `CollectionService` tag used to identify modules for relocation. |
| `parent` | `ServerStorage` | The destination container for relocated modules. |

Replace `path.to.ModuleRelocator` with the actual location of your ModuleScript.

## Important Notes

### Initialization order

ModuleRelocator must run **before initialization**. Execute it before your loader or any other system requires modules that are expected to be relocated.

### `script.Parent` references

Relocation changes the actual module's parent, which may affect code that relies on `script.Parent`.

If a module needs to reference its original parent, add an `ObjectValue` inside the module and set its `Value` to the original parent before relocation.

For example, name the ObjectValue `RealParent`:

```lua
local originalParent = script.RealParent.Value
```

Replace affected `script.Parent` references with `script.RealParent.Value` where necessary. `RealParent` is an optional name; use the same name in your code as the one assigned to the ObjectValue.

### Security considerations

ModuleRelocator is designed to keep server-dependent code in a server-only location. Ensure that the destination is genuinely server-only and that relocation happens before clients can access the relevant replicated modules.

A placeholder is not a security boundary by itself. Keep sensitive logic and authority on the server, and validate client requests independently.

## Compatibility

- Designed for Roblox experiences using Single Script Architecture.
- Intended to run on the server.
- Must execute before dependent initialization code.

## Author

**Cement** — [Roblox](https://www.roblox.com/) · [Discord](https://discord.com/)

## License

See the repository's [`LICENSE`](../../LICENSE) file for licensing terms.
