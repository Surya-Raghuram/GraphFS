#pragma once
#include <cstdint>
#include <cstring>

// ─────────────────────────────────────────────
//  Magic signature + version
// ─────────────────────────────────────────────
static constexpr char FILEY_SIGNATURE[6] = {'F','I','L','E','Y','\0'};
static constexpr uint16_t FILEY_VERSION  = 3;

// ─────────────────────────────────────────────
//  UUID: 36-char string + null  (e.g. "550e8400-e29b-41d4-a716-446655440000")
// ─────────────────────────────────────────────
static constexpr int UUID_LEN = 37;

// ─────────────────────────────────────────────
//  File-level header  (written first in main.filey)
// ─────────────────────────────────────────────
#pragma pack(push, 1)
struct fileHeader {
    char     signature[6];   // "FILEY\0"
    uint16_t version;        // FILEY_VERSION
    uint64_t data_size;      // bytes that follow this header
};

// ─────────────────────────────────────────────
//  Graph-level header  (follows fileHeader)
// ─────────────────────────────────────────────
struct graphHeader {
    uint32_t num_nodes;
    uint32_t num_edges;
};

// ─────────────────────────────────────────────
//  A single node in the graph
//  md_filename = UUID + ".md"  (lives in project/nodes/)
// ─────────────────────────────────────────────
struct graphNode {
    char     id[UUID_LEN];          // stable UUID
    char     label[128];            // display name (user-editable)
    char     content_file[64];      // "<uuid>.<ext>"
    float    x;                     // canvas position
    float    y;
    uint32_t color_tag;             // RGBA colour hint (0 = default)
    uint8_t  _pad[7];               // keep struct size a multiple of 8
};

// ─────────────────────────────────────────────
//  A directed edge between two nodes
// ─────────────────────────────────────────────
struct graphEdge {
    char  from_id[UUID_LEN];
    char  to_id[UUID_LEN];
    char  label[64];          // optional edge label
    uint8_t bidirectional;    // 1 = undirected, 0 = directed
    uint8_t _pad[3];
};
#pragma pack(pop)
