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

The programmer is no longer required to maintain the types and the paths, meaning fewer run-time bugs and crashes, helpful code completion suggestions in your IDE, and faster iteration cycles.

## Usage 
I'm still figuring out the Swift PM story for how to run this, but in the meantime, here's an approach that works well:

1. Install Mint (`brew install mint`) if you don't already have it.
2. Add a file named `Mintfile` to your project and put `PadraigK/SceneGen@0.0.1` in there.
3. Run `mint bootstrap` (takes a while, maybe 5 mins)
4. Run code generation using `mint run scenegen <project-path> <output-path>` — note that output path will be **deleted** each time this is run before code is generated. This is necessary to clean up if you remove or rename a scene.

### Use with a Watcher 

The recommended usage of SceneGen is with a watcher, like [entr](https://github.com/eradman/entr), which can be used re-run the generation anytime one of the scene files changes. 

I suggest making a shell script like this:

```
#!/bin/zsh

# loop because the `-d` flag on `entr` makes it exit when it 
# detects a new or deleted file in any of the folders its watching,
# otherwise it would only detect modifications to existing files
while sleep 0.1; do
	find ../ -name '*.tscn' -not -path '*/.*' | entr -d -s 'mint run <project-path> <output-path>'
done
```

and then leaving it running in a terminal window as you work.


## Benefits
* IDE code suggestions include the names of all available nodes in your context.
* Run-time crashes due to typos in node path accessors can’t happen anymore.
* When you rename or reorganize node paths in the Godot Editor, the compiler will emit errors at build time in your swift code, giving you precise hints about what to fix, instead of run-time crashes.
* Generates a resource path to the tscn file so you can safely instantiate scenes in code — if you reorganize your tscn files into folders in Godot, a re-compile will fix all of these references with no code changes required on your part.
* Also generates typed animation names which are played using syntax like `enemy.playAnimation(.explode)`
* Supports “Access as Unique Name” to generate shorter named paths.
* Generator works independently of the built swift GDExtension — it just works off the Godot project file and tscn files. It’s not necessary that your extension code be functional code-generation time.


