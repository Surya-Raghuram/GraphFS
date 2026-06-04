import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ─────────────────────────────────────────────────────────────────
//  Native function typedefs
// ─────────────────────────────────────────────────────────────────
typedef _CreateNative = Pointer<Void> Function(Pointer<Utf8>);
typedef _CreateDart   = Pointer<Void> Function(Pointer<Utf8>);

typedef _OpenNative = Pointer<Void> Function(Pointer<Utf8>);
typedef _OpenDart   = Pointer<Void> Function(Pointer<Utf8>);

typedef _SaveNative = Bool Function(Pointer<Void>);
typedef _SaveDart   = bool Function(Pointer<Void>);

typedef _CloseNative = Void Function(Pointer<Void>);
typedef _CloseDart   = void Function(Pointer<Void>);

typedef _IsOpenNative = Bool Function(Pointer<Void>);
typedef _IsOpenDart   = bool Function(Pointer<Void>);

typedef _RootPathNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _RootPathDart   = Pointer<Utf8> Function(Pointer<Void>);

typedef _AddNodeNative = Pointer<Utf8> Function(
    Pointer<Void>, Pointer<Utf8>, Float, Float, Uint32);
typedef _AddNodeDart = Pointer<Utf8> Function(
    Pointer<Void>, Pointer<Utf8>, double, double, int);

typedef _RemoveNodeNative = Bool Function(Pointer<Void>, Pointer<Utf8>);
typedef _RemoveNodeDart   = bool Function(Pointer<Void>, Pointer<Utf8>);

typedef _RenameNodeNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _RenameNodeDart   = bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _MoveNodeNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Float, Float);
typedef _MoveNodeDart   = bool Function(Pointer<Void>, Pointer<Utf8>, double, double);

typedef _SetColorNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Uint32);
typedef _SetColorDart   = bool Function(Pointer<Void>, Pointer<Utf8>, int);

typedef _ImportFileNative = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _ImportFileDart   = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _ExportFileNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _ExportFileDart   = bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _ReadContentNative = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _ReadContentDart   = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);

typedef _WriteContentNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _WriteContentDart   = bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _NodeFilePathNative = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _NodeFilePathDart   = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);

typedef _AddEdgeNative = Bool Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Bool);
typedef _AddEdgeDart = bool Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, bool);

typedef _RemoveEdgeNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _RemoveEdgeDart   = bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _EdgeExistsNative = Bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _EdgeExistsDart   = bool Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef _GraphJsonNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _GraphJsonDart   = Pointer<Utf8> Function(Pointer<Void>);

typedef _FreeStrNative = Void Function(Pointer<Utf8>);
typedef _FreeStrDart   = void Function(Pointer<Utf8>);

// ─────────────────────────────────────────────────────────────────
//  FileyFFI  –  singleton that loads the .so and binds all symbols
// ─────────────────────────────────────────────────────────────────
class FileyFFI {
  FileyFFI._();
  static FileyFFI? _instance;
  static FileyFFI get instance => _instance ??= FileyFFI._().._load();

  late final DynamicLibrary _lib;

  late final _CreateDart   create;
  late final _OpenDart     open;
  late final _SaveDart     save;
  late final _CloseDart    close;
  late final _IsOpenDart   isOpen;
  late final _RootPathDart rootPath;

  late final _AddNodeDart    addNode;
  late final _RemoveNodeDart removeNode;
  late final _RenameNodeDart renameNode;
  late final _MoveNodeDart   moveNode;
  late final _SetColorDart   setNodeColor;
  late final _ImportFileDart   importFile;
  late final _ExportFileDart   exportFile;

  late final _ReadContentDart  readContent;
  late final _WriteContentDart writeContent;
  late final _NodeFilePathDart   nodeFilePath;

  late final _AddEdgeDart    addEdge;
  late final _RemoveEdgeDart removeEdge;
  late final _EdgeExistsDart edgeExists;

  late final _GraphJsonDart graphJson;
  late final _FreeStrDart   freeStr;

  void _load() {
    // Look for libfiley_core.so next to the executable, then system paths
    final exe = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      '$exe/lib/libfiley_core.so',
      '$exe/libfiley_core.so',
      'libfiley_core.so',
    ];
    DynamicLibrary? lib;
    for (final path in candidates) {
      if (File(path).existsSync()) {
        lib = DynamicLibrary.open(path);
        break;
      }
    }
    lib ??= DynamicLibrary.open('libfiley_core.so'); // rely on LD_LIBRARY_PATH
    _lib = lib;

    create      = _lib.lookupFunction<_CreateNative,   _CreateDart>  ('filey_create');
    open        = _lib.lookupFunction<_OpenNative,     _OpenDart>    ('filey_open');
    save        = _lib.lookupFunction<_SaveNative,     _SaveDart>    ('filey_save');
    close       = _lib.lookupFunction<_CloseNative,    _CloseDart>   ('filey_close');
    isOpen      = _lib.lookupFunction<_IsOpenNative,   _IsOpenDart>  ('filey_is_open');
    rootPath    = _lib.lookupFunction<_RootPathNative, _RootPathDart>('filey_root_path');

    addNode     = _lib.lookupFunction<_AddNodeNative,    _AddNodeDart>   ('filey_add_node');
    removeNode  = _lib.lookupFunction<_RemoveNodeNative, _RemoveNodeDart>('filey_remove_node');
    renameNode  = _lib.lookupFunction<_RenameNodeNative, _RenameNodeDart>('filey_rename_node');
    moveNode    = _lib.lookupFunction<_MoveNodeNative,   _MoveNodeDart>  ('filey_move_node');
    setNodeColor= _lib.lookupFunction<_SetColorNative,   _SetColorDart>  ('filey_set_node_color');
    importFile    = _lib.lookupFunction<_ImportFileNative,   _ImportFileDart>  ('filey_import_file');
    exportFile    = _lib.lookupFunction<_ExportFileNative,   _ExportFileDart>  ('filey_export_file');

    readContent  = _lib.lookupFunction<_ReadContentNative,  _ReadContentDart> ('filey_read_content');
    writeContent = _lib.lookupFunction<_WriteContentNative, _WriteContentDart>('filey_write_content');
    nodeFilePath   = _lib.lookupFunction<_NodeFilePathNative,   _NodeFilePathDart>  ('filey_node_file_path');

    addEdge    = _lib.lookupFunction<_AddEdgeNative,    _AddEdgeDart>   ('filey_add_edge');
    removeEdge = _lib.lookupFunction<_RemoveEdgeNative, _RemoveEdgeDart>('filey_remove_edge');
    edgeExists = _lib.lookupFunction<_EdgeExistsNative, _EdgeExistsDart>('filey_edge_exists');

    graphJson  = _lib.lookupFunction<_GraphJsonNative, _GraphJsonDart>('filey_graph_json');
    freeStr    = _lib.lookupFunction<_FreeStrNative,   _FreeStrDart>  ('filey_free_str');
  }

  /// Helper: call a C function that returns a heap char*, convert to Dart String,
  /// then free the C memory.
  String? consumeStr(Pointer<Utf8> ptr) {
    if (ptr == nullptr) return null;
    final s = ptr.toDartString();
    freeStr(ptr);
    return s;
  }
}
