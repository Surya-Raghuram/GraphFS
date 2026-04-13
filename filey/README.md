# Filey

> Markdown mind maps — connected thought.

A desktop graph editor where every node is a real `.md` file on disk.
The entire project lives in a single self-contained folder. The md files are stored within the folder along with a 

---

## Project structure

```
filey/
├── core/                        ← C++17 shared library
│   ├── include/
│   │   ├── filey_data.h         ← binary structs (graphNode, graphEdge…)
│   │   ├── filey_uuid.h         ← UUID v4 generator
│   │   ├── filey_project.h      ← high-level C++ API
│   │   └── filey_ffi.h          ← plain-C FFI surface for Dart
│   ├── src/
│   │   ├── filey_project.cpp    ← full implementation
│   │   ├── filey_ffi.cpp        ← C wrappers + JSON serialiser
│   │   └── filey_cli.cpp        ← smoke-test binary
│   └── CMakeLists.txt
│
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   └── graph_model.dart  ← Dart data classes (GraphNode, GraphEdge…)
│   │   ├── services/
│   │   │   ├── filey_ffi.dart    ← Dart FFI bindings to C symbols
│   │   │   └── filey_project.dart← ChangeNotifier wrapping FFI
│   │   ├── theme/
│   │   │   └── filey_theme.dart  ← dark theme, yellow accent
│   │   ├── widgets/
│   │   │   ├── graph_canvas.dart ← CustomPainter: pan/zoom/drag/click
│   │   │   └── markdown_editor.dart ← edit + preview panel, auto-save
│   │   └── screens/
│   │       ├── home_screen.dart  ← create / open project landing
│   │       └── editor_screen.dart← main 2-panel layout
│   ├── linux/
│   │   └── CMakeLists.txt        ← bundles libfiley_core.so
│   └── pubspec.yaml
│
└── build.sh                      ← one-shot build script (Only for arch Linux)
```

---

## On-disk project format

```
my_notes/                    ← your project folder (name it anything)
├── main.filey               ← binary graph: node positions + edge list
└── nodes/
    ├── 3c60b594-…-bf7c.md   ← one UUID-named .md file per node
    ├── 05cc7ea0-…-bacc.md
    └── …
```

- Renaming a node in the UI only updates its **label** in `main.filey`.
  The `.md` filename (UUID-based) never changes and should not be changed. This makes sure there is no broken links ever.
- The entire folder is portable, you can zip it and share it.
- Individual nodes can be exported as separate `<label>.md` files which are editable.

---

## Dependencies

Flutter needs these for Linux desktop:
```bash
sudo pacman -S clang cmake ninja libblkid
```

### Fonts (download once)

Place in `flutter_app/fonts/`:

| File | Source |
|---|---|
| `SpaceGrotesk-{Regular,Medium,SemiBold,Bold}.ttf` | [Google Fonts](https://fonts.google.com/specimen/Space+Grotesk) |
| `IBMPlexMono-{Regular,Medium,SemiBold}.ttf` | [Google Fonts](https://fonts.google.com/specimen/IBM+Plex+Mono) |

---

## Build & Run

```bash
cd filey
# build script only for arch
./build.sh release
# Run
build/linux/x64/release/bundle/run_filey.sh
```

Or step-by-step:

```bash
# 1. Build C++ library
cd core
g++ -std=c++17 -O2 -fPIC -shared \
    -Iinclude src/filey_project.cpp src/filey_ffi.cpp \
    -o libfiley_core.so

# 2. Run smoke tests
g++ -std=c++17 -O2 -Iinclude \
    src/filey_project.cpp src/filey_ffi.cpp src/filey_cli.cpp \
    -o filey_cli && ./filey_cli

# 3. Flutter
cd ../flutter_app
flutter pub get
flutter build linux --release

# 4. Bundle the .so
mkdir -p build/linux/x64/release/bundle/lib
cp ../core/libfiley_core.so build/linux/x64/release/bundle/lib/

# 5. Run
LD_LIBRARY_PATH=build/linux/x64/release/bundle/lib \
    build/linux/x64/release/bundle/filey
```

---

## Interaction guide
The app will soon include an info page containing this information.
| Action | Result |
|---|---|
| Click empty canvas | Add new node at that position |
| Click node | Select node + open markdown editor |
| Double-click node | Enter edge-draw mode |
| (in edge mode) click node | Create edge between the two nodes |
| Right-click node | Context menu: connect / export / delete |
| Scroll wheel | Zoom in / out |
| Drag background | Pan canvas |
| Drag node | Move node (auto-saved) |
| Double-click editor label | Rename node |
| Sidebar list | Jump to any node |

---

## Architecture design

### Why FFI instead of a subprocess?

The C++ library is loaded as a **shared object** (`.so`) directly into the
Flutter process via `dart:ffi`. There is no IPC, no serialisation overhead
on the hot path — node moves (called continuously during drag) go through
a direct function call. Only the `filey_graph_json()` call (for full graph
refresh after editing) involves JSON, and that only fires on structural
changes (add/remove node, add/remove edge).

The C++ core and the Dart service layer are identical across all devices(support will be added in late editions).
Only the library-loading path in `filey_ffi.dart` changes.

### Why UUID filenames?

The `.md` file on disk is named after a stable UUID, not the display label.
This means:
- Renaming a node = update one field in `main.filey`, zero filesystem ops
- Edges reference UUIDs, so they never break after rename
- Git history of a `.md` file tracks a node's content correctly across renames


