# SceneGen

Renders typed descriptions of each node in the scene files (.tscn) of a Godot project. Provides an access function to get a reference to the nodes called `node()`. This tool is intended for use with Miguel de Icaza's SwiftGodot bindings and generates Swift code that depends on SwiftGodot being available. 

## Example

<img src="https://raw.githubusercontent.com/PadraigK/SceneGen/main/Images/playerscene.png" alt="A Node Tree in Godot" width="30%" align="left" style="padding-right: 20px;">

In SwiftGodot a node is referenced as follows: 

```swift
let marker = getNodeOrNull("Sprite2D/Marker2D") as? Marker2D`.
```

This requires the programmer to ensure that the path to the node, and its type, are correct. If there is a mismatch, the node will be nil. 

If we run SceneGen on this project, our root `Player` type will be extended with typed descriptions of each node. These can then be accessed in a type-safe way: 

```
swift let sprite = node(.sprite2D_marker2d)
```

## Usage 

`> swift run scene-gen <project-path> <output-path>`
 
## Benefits
* IDE code suggestions include the names of all available nodes in your context.
* Run-time crashes due to typos in node path accessors can’t happen anymore.
* When you rename or reorganize node paths in the Godot Editor, the compiler will emit errors at build time in your swift code, giving you precise hints about what to fix, instead of run-time crashes.
* Generates a resource path to the tscn file so you can safely instantiate scenes in code — if you reorganize your tscn files into folders in Godot, a re-compile will fix all of these references with no code changes required on your part.
* Also generates typed animation names which are played using syntax like `enemy.playAnimation(.explode)`
* Supports “Access as Unique Name” to generate shorter named paths.
* Generator works independently of the built swift GDExtension — it just works off the Godot project file and tscn files. It’s not necessary that your extension code be functional code-generation time.

## Recommended Usage:
* Run with a watcher to regenerate code every time a scene file changes 