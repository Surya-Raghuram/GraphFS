//  filey_ffi.h  –  Plain-C interface consumed by Dart via dart:ffi
//  All strings are UTF-8, null-terminated.
//  Caller owns memory returned by filey_str_* functions; free with filey_free_str().

#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ── Opaque project handle ──────────────────────────────────────────
typedef void* FileyHandle;

// ── Lifecycle ──────────────────────────────────────────────────────
FileyHandle filey_create(const char* path);   // returns NULL on failure
FileyHandle filey_open(const char* path);     // returns NULL on failure
bool        filey_save(FileyHandle h);
void        filey_close(FileyHandle h);       // frees handle
bool        filey_is_open(FileyHandle h);
const char* filey_root_path(FileyHandle h);   // do NOT free this

// ── Nodes ──────────────────────────────────────────────────────────
// Returns heap-allocated UUID string; caller must filey_free_str().
char* filey_add_node(FileyHandle h, const char* label, float x, float y, uint32_t color);
bool  filey_remove_node(FileyHandle h, const char* uuid);
bool  filey_rename_node(FileyHandle h, const char* uuid, const char* new_label);
bool  filey_move_node(FileyHandle h, const char* uuid, float x, float y);
bool  filey_set_node_color(FileyHandle h, const char* uuid, uint32_t rgba);

// Import external .md into project. Returns new UUID or NULL.
char* filey_import_file(FileyHandle h, const char* ext_path, const char* label);

// Export node .md to destDir. Returns true on success.
bool  filey_export_file(FileyHandle h, const char* uuid, const char* dest_dir);

// ── Markdown content ───────────────────────────────────────────────
// Returns heap-allocated content string; caller must filey_free_str().
char* filey_read_content(FileyHandle h, const char* uuid);
bool  filey_write_content(FileyHandle h, const char* uuid, const char* content);
// Returns heap-allocated absolute path; caller must filey_free_str().
char* filey_node_file_path(FileyHandle h, const char* uuid);

// ── Edges ──────────────────────────────────────────────────────────
bool filey_add_edge(FileyHandle h, const char* from_uuid, const char* to_uuid,
                    const char* label, bool bidirectional);
bool filey_remove_edge(FileyHandle h, const char* from_uuid, const char* to_uuid);
bool filey_edge_exists(FileyHandle h, const char* from_uuid, const char* to_uuid);

// ── Serialised graph snapshot for Dart ────────────────────────────
// Returns a heap-allocated JSON string describing all nodes + edges.
// Dart parses this to rebuild its model without touching binary structs.
// Caller must filey_free_str().
char* filey_graph_json(FileyHandle h);

// ── Memory ────────────────────────────────────────────────────────
void filey_free_str(char* s);

#ifdef __cplusplus
}
#endif
