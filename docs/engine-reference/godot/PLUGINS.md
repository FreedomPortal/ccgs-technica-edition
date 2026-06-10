# Godot Plugins & Extensions — Quick Reference

Last verified: [stub — not verified] | Engine: Godot (version not set)

*Empty stub. Run `/refresh-docs update godot plugins --web` with target version to populate.*

---

## What Changed Since ~4.3 (LLM Cutoff)

*Not yet populated.*

### Key Topics to Verify
- `EditorPlugin` API changes (4.4–4.6)
- `@tool` script behavior and limitations
- GDExtension stability tier and API compatibility guarantees
- `EditorInspectorPlugin` / `EditorImportPlugin` / `EditorExportPlugin` API
- Plugin auto-loading and dependency declaration
- Asset Library submission requirements
- GDExtension vs GDNative migration path (Godot 3 → 4)
- Hot-reload behavior for `@tool` scripts

## Plugin Types Reference

*Run `/refresh-docs update godot plugins --web` to populate with verified patterns.*

| Type | Use Case | Base Class |
|------|----------|-----------|
| `@tool` GDScript | In-editor behavior for existing nodes | Any node class |
| `EditorPlugin` | Editor UI additions, import, export | `EditorPlugin` |
| GDExtension | Native performance, C/C++/Rust | `GDExtension` |

## Common Mistakes

*Run `/refresh-docs update godot plugins --web` to populate.*

## Official Documentation
- Editor plugins: https://docs.godotengine.org/en/stable/tutorials/plugins/editor/
- GDExtension: https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/
- `@tool` scripts: https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html
