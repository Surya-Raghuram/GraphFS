#include "filey_ffi.h"
#include "filey_project.h"
#include <fstream>
#include <cstring>
#include <cstdlib>
#include <sstream>
#include <string>

using filey::FileyProject;

static std::string sanitizePath(const char* raw) {
    if (!raw) return "";
    std::string p(raw);
    
    if (p.find("file://") == 0) {
        p = p.substr(7);
    }
    
    while (!p.empty() && std::isspace(static_cast<unsigned char>(p.back()))) {
        p.pop_back();
    }
    return p;
}

static char* heap_str(const std::string& s) {
    if (s.empty()) return nullptr;
    char* buf = static_cast<char*>(std::malloc(s.size() + 1));
    std::memcpy(buf, s.c_str(), s.size() + 1);
    return buf;
}

static FileyProject* proj(FileyHandle h) {
    return static_cast<FileyProject*>(h);
}

// Minimal JSON escaping (no external deps)
static std::string jsonEsc(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 4);
    for (char c : s) {
        switch(c){
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:   out += c;
        }
    }
    return out;
}

static void debugLog(const std::string& msg) {
    // Appends every step to a file we can easily read
    std::ofstream log("/tmp/filey_debug.log", std::ios::app);
    log << msg << "\n";
}

// ── Lifecycle ───────────
FileyHandle filey_create(const char* raw_path) {
    debugLog("\n=== ATTEMPTING TO CREATE PROJECT ===");
    debugLog(std::string("1. Raw FFI Path: ") + (raw_path ? raw_path : "NULL"));
    
    std::string path = sanitizePath(raw_path);
    debugLog("2. Sanitized Path: " + path);
    
    auto* p = new FileyProject();
    if (!p->create(path)) { 
        debugLog("3. ERROR: p->create() failed inside C++!");
        delete p; 
        return nullptr; 
    }
    
    debugLog("3. SUCCESS: Project created.");
    return p;
}

FileyHandle filey_open(const char* raw_path) {
    debugLog("\n=== ATTEMPTING TO OPEN PROJECT ===");
    std::string path = sanitizePath(raw_path);
    debugLog("Sanitized Path: " + path);
    
    auto* p = new FileyProject();
    if (!p->open(path)) { 
        debugLog("ERROR: p->open() failed inside C++!");
        delete p; 
        return nullptr; 
    }
    return p;
}
bool filey_save(FileyHandle h) {
    return h ? proj(h)->save() : false;
}

void filey_close(FileyHandle h) {
    if (h) { proj(h)->close(); delete proj(h); }
}

bool filey_is_open(FileyHandle h) {
    return h ? proj(h)->isOpen() : false;
}

const char* filey_root_path(FileyHandle h) {
    return h ? proj(h)->rootPath().c_str() : "";
}

// ── Nodes ───────
char* filey_add_node(FileyHandle h, const char* label,
                     float x, float y, uint32_t color) {
    if (!h) return nullptr;
    return heap_str(proj(h)->addNode(label ? label : "", x, y, color));
}

bool filey_remove_node(FileyHandle h, const char* uuid) {
    return h ? proj(h)->removeNode(uuid) : false;
}

bool filey_rename_node(FileyHandle h, const char* uuid, const char* new_label) {
    return h ? proj(h)->renameNode(uuid, new_label ? new_label : "") : false;
}

bool filey_move_node(FileyHandle h, const char* uuid, float x, float y) {
    return h ? proj(h)->moveNode(uuid, x, y) : false;
}

bool filey_set_node_color(FileyHandle h, const char* uuid, uint32_t rgba) {
    return h ? proj(h)->setNodeColor(uuid, rgba) : false;
}

char* filey_import_md(FileyHandle h, const char* ext_path, const char* label) {
    if (!h) return nullptr;
    return heap_str(proj(h)->importMarkdown(ext_path ? ext_path : "",
                                             label    ? label    : ""));
}

bool filey_export_md(FileyHandle h, const char* uuid, const char* dest_dir) {
    return h ? proj(h)->exportMarkdown(uuid, dest_dir ? dest_dir : "") : false;
}

// ── Markdown content ─────
char* filey_read_content(FileyHandle h, const char* uuid) {
    if (!h) return nullptr;
    return heap_str(proj(h)->readNodeContent(uuid));
}

bool filey_write_content(FileyHandle h, const char* uuid, const char* content) {
    return h ? proj(h)->writeNodeContent(uuid, content ? content : "") : false;
}

char* filey_node_md_path(FileyHandle h, const char* uuid) {
    if (!h) return nullptr;
    return heap_str(proj(h)->nodeMdPath(uuid));
}

// ── Edges ─────
bool filey_add_edge(FileyHandle h, const char* from, const char* to,
                    const char* label, bool bidir) {
    return h ? proj(h)->addEdge(from, to, label ? label : "", bidir) : false;
}

bool filey_remove_edge(FileyHandle h, const char* from, const char* to) {
    return h ? proj(h)->removeEdge(from, to) : false;
}

bool filey_edge_exists(FileyHandle h, const char* from, const char* to) {
    return h ? proj(h)->edgeExists(from, to) : false;
}

// ── Graph JSON snapshot ───────────
char* filey_graph_json(FileyHandle h) {
    if (!h) return heap_str("{}");
    const auto& nodes = proj(h)->nodes();
    const auto& edges = proj(h)->edges();

    std::ostringstream ss;
    ss << "{\"nodes\":[";
    for (size_t i = 0; i < nodes.size(); ++i) {
        const auto& n = nodes[i];
        if (i) ss << ',';
        ss << '{'
           << "\"id\":\""          << jsonEsc(n.id)          << "\","
           << "\"label\":\""       << jsonEsc(n.label)        << "\","
           << "\"md_filename\":\"" << jsonEsc(n.md_filename)  << "\","
           << "\"x\":"             << n.x                     << ','
           << "\"y\":"             << n.y                     << ','
           << "\"color\":"         << n.color_tag
           << '}';
    }
    ss << "],\"edges\":[";
    for (size_t i = 0; i < edges.size(); ++i) {
        const auto& e = edges[i];
        if (i) ss << ',';
        ss << '{'
           << "\"from\":\""         << jsonEsc(e.from_id)      << "\","
           << "\"to\":\""           << jsonEsc(e.to_id)        << "\","
           << "\"label\":\""        << jsonEsc(e.label)        << "\","
           << "\"bidirectional\":"  << (e.bidirectional ? "true" : "false")
           << '}';
    }
    ss << "]}";
    return heap_str(ss.str());
}

// ── free the Memory ───
void filey_free_str(char* s) {
    std::free(s);
}
