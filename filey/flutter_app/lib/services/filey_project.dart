import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import '../models/graph_model.dart';
import 'filey_ffi.dart';
import 'dart:ffi';

/// High-level Dart service that wraps the C FFI layer.
/// Notifies listeners whenever the graph changes.
class FileyProject extends ChangeNotifier {
  final _ffi = FileyFFI.instance;
  var _handle = nullptr;

  bool get isOpen => _handle != nullptr && _ffi.isOpen(_handle);
  String get rootPath => isOpen ? _ffi.rootPath(_handle).toDartString() : '';

  GraphModel _graph = const GraphModel(nodes: [], edges: []);
  GraphModel get graph => _graph;

  // ── Lifecycle ────────────────────────────────────────────────
  Future<bool> create(String path) async {
    _closeIfOpen();
    final pathPtr = path.toNativeUtf8();
    Pointer<Void> _handle = nullptr;
    calloc.free(pathPtr);
    if (_handle == nullptr) return false;
    _refreshGraph();
    notifyListeners();
    return true;
  }

  Future<bool> open(String path) async {
    _closeIfOpen();
    final pathPtr = path.toNativeUtf8();
    Pointer<Void> _handle = nullptr;
    calloc.free(pathPtr);
    if (_handle == nullptr) return false;
    _refreshGraph();
    notifyListeners();
    return true;
  }

  void save() {
    if (isOpen) _ffi.save(_handle);
  }

  void closeProject() {
    _closeIfOpen();
    _graph = const GraphModel(nodes: [], edges: []);
    notifyListeners();
  }

  void _closeIfOpen() {
    if (_handle != nullptr) {
      _ffi.close(_handle);
      _handle = nullptr;
    }
  }

  // ── Node operations ──────────────────────────────────────────
  String? addNode(String label, double x, double y, {int color = 0}) {
    if (!isOpen) return null;
    final lPtr = label.toNativeUtf8();
    final uuidPtr = _ffi.addNode(_handle, lPtr, x, y, color);
    calloc.free(lPtr);
    final uuid = _ffi.consumeStr(uuidPtr);
    if (uuid != null) _refreshAndNotify();
    return uuid;
  }

  bool removeNode(String uuid) {
    if (!isOpen) return false;
    final uPtr = uuid.toNativeUtf8();
    final ok = _ffi.removeNode(_handle, uPtr);
    calloc.free(uPtr);
    if (ok) _refreshAndNotify();
    return ok;
  }

  bool renameNode(String uuid, String newLabel) {
    if (!isOpen) return false;
    final uPtr = uuid.toNativeUtf8();
    final lPtr = newLabel.toNativeUtf8();
    final ok = _ffi.renameNode(_handle, uPtr, lPtr);
    calloc.free(uPtr);
    calloc.free(lPtr);
    if (ok) _refreshAndNotify();
    return ok;
  }

  bool moveNode(String uuid, double x, double y) {
    if (!isOpen) return false;
    final uPtr = uuid.toNativeUtf8();
    final ok = _ffi.moveNode(_handle, uPtr, x, y);
    calloc.free(uPtr);
    if (ok) _refreshGraph(); // no notifyListeners – canvas handles its own state
    return ok;
  }

  bool setNodeColor(String uuid, int rgba) {
    if (!isOpen) return false;
    final uPtr = uuid.toNativeUtf8();
    final ok = _ffi.setNodeColor(_handle, uPtr, rgba);
    calloc.free(uPtr);
    if (ok) _refreshAndNotify();
    return ok;
  }

  String? importMarkdown(String externalPath, {String label = ''}) {
    if (!isOpen) return null;
    final ePtr = externalPath.toNativeUtf8();
    final lPtr = label.toNativeUtf8();
    final uuidPtr = _ffi.importMd(_handle, ePtr, lPtr);
    calloc.free(ePtr);
    calloc.free(lPtr);
    final uuid = _ffi.consumeStr(uuidPtr);
    if (uuid != null) _refreshAndNotify();
    return uuid;
  }

  bool exportMarkdown(String uuid, String destDir) {
    if (!isOpen) return false;
    final uPtr = uuid.toNativeUtf8();
    final dPtr = destDir.toNativeUtf8();
    final ok = _ffi.exportMd(_handle, uPtr, dPtr);
    calloc.free(uPtr);
    calloc.free(dPtr);
    return ok;
  }

  // ── Content ──────────────────────────────────────────────────
  String readContent(String uuid) {
    if (!isOpen) return '';
    final uPtr = uuid.toNativeUtf8();
    final ptr = _ffi.readContent(_handle, uPtr);
    calloc.free(uPtr);
    return _ffi.consumeStr(ptr) ?? '';
  }

  bool writeContent(String uuid, String content) {
    if (!isOpen) return false;
    final uPtr = uuid.toNativeUtf8();
    final cPtr = content.toNativeUtf8();
    final ok = _ffi.writeContent(_handle, uPtr, cPtr);
    calloc.free(uPtr);
    calloc.free(cPtr);
    return ok;
  }

  String nodeMdPath(String uuid) {
    if (!isOpen) return '';
    final uPtr = uuid.toNativeUtf8();
    final ptr = _ffi.nodeMdPath(_handle, uPtr);
    calloc.free(uPtr);
    return _ffi.consumeStr(ptr) ?? '';
  }

  // ── Edges ────────────────────────────────────────────────────
  bool addEdge(String from, String to, {String label = '', bool bidir = true}) {
    if (!isOpen) return false;
    final fPtr = from.toNativeUtf8();
    final tPtr = to.toNativeUtf8();
    final lPtr = label.toNativeUtf8();
    final ok = _ffi.addEdge(_handle, fPtr, tPtr, lPtr, bidir);
    calloc.free(fPtr);
    calloc.free(tPtr);
    calloc.free(lPtr);
    if (ok) _refreshAndNotify();
    return ok;
  }

  bool removeEdge(String from, String to) {
    if (!isOpen) return false;
    final fPtr = from.toNativeUtf8();
    final tPtr = to.toNativeUtf8();
    final ok = _ffi.removeEdge(_handle, fPtr, tPtr);
    calloc.free(fPtr);
    calloc.free(tPtr);
    if (ok) _refreshAndNotify();
    return ok;
  }

  // ── Internal ─────────────────────────────────────────────────
  void _refreshGraph() {
    if (!isOpen) return;
    final jsonPtr = _ffi.graphJson(_handle);
    final jsonStr = _ffi.consumeStr(jsonPtr) ?? '{}';
    _graph = GraphModel.fromJson(jsonDecode(jsonStr));
  }

  void _refreshAndNotify() {
    _refreshGraph();
    notifyListeners();
  }
}
