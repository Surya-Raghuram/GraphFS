#include "filey_project.h"
#include "filey_uuid.h"
#include "filey_data.h"

#include <fstream>
#include <iostream>
#include <sstream>
#include <cstring>
#include <algorithm>
#include <filesystem>

namespace fs = std::filesystem;

namespace filey {

// ─────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────
static void fillStrField(char* dst, size_t dstSize, const std::string& src) {
    std::memset(dst, 0, dstSize);
    std::strncpy(dst, src.c_str(), dstSize - 1);
}

// ─────────────────────────────────────────────────────────────────
//  lifecycle
// ─────────────────────────────────────────────────────────────────
bool FileyProject::create(const std::string& path) {
    std::ofstream log("/tmp/filey_debug.log", std::ios::app); // Open the log
    
    if (fs::exists(path)) {
        log << "   -> FAIL: path already exists: " << path << "\n";
        return false;
    }
    std::error_code ec;
    fs::create_directories(path, ec);
    if (ec) {
        log << "   -> FAIL: cannot create dir: " << ec.message() << "\n";
        return false;
    }

    m_root      = fs::absolute(path).string();
    m_fileyPath = m_root + "/main.filey";
    m_nodesDir  = m_root + "/nodes";
    m_nodes.clear();
    m_edges.clear();
    m_open = true;

    if (!ensureNodesDir()) {
        log << "   -> FAIL: ensureNodesDir() failed\n";
        return false;
    }
    
    bool wrote = writeMainFiley();
    if (!wrote) log << "   -> FAIL: writeMainFiley() failed\n";
    return wrote;
}

bool FileyProject::open(const std::string& path) {
    std::ofstream log("/tmp/filey_debug.log", std::ios::app);
    log << "\n=== C++ OPENING: " << path << " ===\n";

    if (!fs::exists(path) || !fs::is_directory(path)) {
        log << "   -> FAIL: C++ std::filesystem says directory does not exist!\n";
        return false;
    }

    m_root      = fs::absolute(path).string();
    m_fileyPath = m_root + "/main.filey";
    m_nodesDir  = m_root + "/nodes";
    m_nodes.clear();
    m_edges.clear();

    log << "   -> Creating nodes directory: " << m_nodesDir << "\n";
    std::error_code ec;
    fs::create_directories(m_nodesDir, ec);
    if (ec) {
        log << "   -> WARNING: create_directories failed: " << ec.message() << "\n";
        // We won't return false here, we'll see if the main file can still be written
    }

    if (!fs::exists(m_fileyPath)) {
        log << "   -> main.filey not found. Initializing new project...\n";
        m_open = true;
        bool wrote = writeMainFiley();
        if (!wrote) log << "   -> FAIL: writeMainFiley() returned false!\n";
        return wrote;
    }

    log << "   -> main.filey exists. Reading project data...\n";
    if (!readMainFiley()) {
        log << "   -> FAIL: readMainFiley() returned false!\n";
        return false;
    }
    
    m_open = true;
    log << "   -> SUCCESS: Project opened.\n";
    return true;
}

bool FileyProject::save() {
    if (!m_open) return false;
    return writeMainFiley();
}

void FileyProject::close() {
    m_open = false;
    m_root.clear();
    m_fileyPath.clear();
    m_nodesDir.clear();
    m_nodes.clear();
    m_edges.clear();
}

// ─────────────────────────────────────────────────────────────────
//  Node CRUD
// ─────────────────────────────────────────────────────────────────
std::string FileyProject::addNode(const std::string& label,
                                   float x, float y, uint32_t colorTag) {
    if (!m_open) return "";
    std::string uuid = generateUUID();
    std::string mdFile = uuid + ".md";

    graphNode node{};
    fillStrField(node.id,          sizeof(node.id),          uuid);
    fillStrField(node.label,       sizeof(node.label),       label);
    fillStrField(node.content_file, sizeof(node.content_file), mdFile);
    node.x         = x;
    node.y         = y;
    node.color_tag = colorTag;

    // create empty .md on disk
    std::string mdPath = m_nodesDir + "/" + mdFile;
    std::ofstream f(mdPath);
    if (!f) {
        std::cerr << "[filey] addNode: cannot create " << mdPath << "\n";
        return "";
    }
    f << "# " << label << "\n\n";
    f.close();

    m_nodes.push_back(node);
    writeMainFiley();
    return uuid;
}

bool FileyProject::removeNode(const std::string& uuid) {
    if (!m_open) return false;
    auto it = std::find_if(m_nodes.begin(), m_nodes.end(),
        [&](const graphNode& n){ return uuid == n.id; });
    if (it == m_nodes.end()) return false;

    // delete .md file
    std::string mdPath = m_nodesDir + "/" + it->content_file;
    std::error_code ec;
    fs::remove(mdPath, ec);

    m_nodes.erase(it);

    // remove all connected edges
    m_edges.erase(std::remove_if(m_edges.begin(), m_edges.end(),
        [&](const graphEdge& e){
            return uuid == e.from_id || uuid == e.to_id;
        }), m_edges.end());

    return writeMainFiley();
}

bool FileyProject::renameNode(const std::string& uuid, const std::string& newLabel) {
    auto* node = findNode(uuid);
    if (!node) return false;
    fillStrField(node->label, sizeof(node->label), newLabel);
    return writeMainFiley();
}

bool FileyProject::moveNode(const std::string& uuid, float x, float y) {
    auto* node = findNode(uuid);
    if (!node) return false;
    node->x = x;
    node->y = y;
    return writeMainFiley();
}

bool FileyProject::setNodeColor(const std::string& uuid, uint32_t rgba) {
    auto* node = findNode(uuid);
    if (!node) return false;
    node->color_tag = rgba;
    return writeMainFiley();
}

std::string FileyProject::importFile(const std::string& externalPath,
                                       const std::string& label) {
    if (!m_open) return "";
    if (!fs::exists(externalPath)) return "";

    // derive label from filename if not given
    std::string lbl = label.empty()
        ? fs::path(externalPath).stem().string()
        : label;

    std::string uuid = generateUUID();
    std::string ext = fs::path(externalPath).extension().string();
    std::string contentFile = uuid + ext;
    std::string dst = m_nodesDir + "/" + contentFile;

    std::error_code ec;
    fs::copy_file(externalPath, dst,
                  fs::copy_options::overwrite_existing, ec);
    if (ec) return "";

    graphNode node{};
    fillStrField(node.id,          sizeof(node.id),          uuid);
    fillStrField(node.label,       sizeof(node.label),       lbl);
    fillStrField(node.content_file, sizeof(node.content_file), contentFile);
    node.x = 0; node.y = 0;
    node.color_tag = 0;
    std::memset(node._pad, 0, sizeof(node._pad));

    m_nodes.push_back(node);
    writeMainFiley();
    return uuid;
}

bool FileyProject::exportFile(const std::string& uuid,
                               const std::string& destDir) {
    const auto* node = findNode(uuid);
    if (!node) return false;
    std::string src = m_nodesDir + "/" + node->content_file;
    std::string ext = fs::path(src).extension().string();
    std::string dst = destDir + "/" + node->label + ext;
    std::error_code ec;
    fs::copy_file(src, dst, fs::copy_options::overwrite_existing, ec);
    return !ec;
}

// ─────────────────────────────────────────────────────────────────
//  Markdown content
// ─────────────────────────────────────────────────────────────────
std::string FileyProject::readNodeContent(const std::string& uuid) const {
    const auto* node = findNode(uuid);
    if (!node) return "";
    std::ifstream f(m_nodesDir + "/" + node->content_file);
    if (!f) return "";
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

bool FileyProject::writeNodeContent(const std::string& uuid,
                                     const std::string& content) {
    const auto* node = findNode(uuid);
    if (!node) return false;
    std::ofstream f(m_nodesDir + "/" + node->content_file,
                    std::ios::trunc);
    if (!f) return false;
    f << content;
    return true;
}

std::string FileyProject::nodeFilePath(const std::string& uuid) const {
    const auto* node = findNode(uuid);
    if (!node) return "";
    return m_nodesDir + "/" + node->content_file;
}

// ─────────────────────────────────────────────────────────────────
//  Edge CRUD
// ─────────────────────────────────────────────────────────────────
bool FileyProject::addEdge(const std::string& from, const std::string& to,
                            const std::string& edgeLabel, bool bidirectional) {
    if (!m_open) return false;
    if (!findNode(from) || !findNode(to)) return false;
    if (edgeExists(from, to)) return false;

    graphEdge e{};
    fillStrField(e.from_id, sizeof(e.from_id), from);
    fillStrField(e.to_id,   sizeof(e.to_id),   to);
    fillStrField(e.label,   sizeof(e.label),   edgeLabel);
    e.bidirectional = bidirectional ? 1 : 0;

    m_edges.push_back(e);
    return writeMainFiley();
}

bool FileyProject::removeEdge(const std::string& from, const std::string& to) {
    if (!m_open) return false;
    size_t before = m_edges.size();
    m_edges.erase(std::remove_if(m_edges.begin(), m_edges.end(),
        [&](const graphEdge& e){
            return (from == e.from_id && to == e.to_id) ||
                   (e.bidirectional && to == e.from_id && from == e.to_id);
        }), m_edges.end());
    if (m_edges.size() == before) return false;
    return writeMainFiley();
}

bool FileyProject::edgeExists(const std::string& from, const std::string& to) const {
    for (const auto& e : m_edges) {
        if (from == e.from_id && to == e.to_id) return true;
        if (e.bidirectional && to == e.from_id && from == e.to_id) return true;
    }
    return false;
}

// ─────────────────────────────────────────────────────────────────
//  Accessors
// ─────────────────────────────────────────────────────────────────
const graphNode* FileyProject::findNode(const std::string& uuid) const {
    for (const auto& n : m_nodes)
        if (uuid == n.id) return &n;
    return nullptr;
}

graphNode* FileyProject::findNode(const std::string& uuid) {
    for (auto& n : m_nodes)
        if (uuid == n.id) return &n;
    return nullptr;
}

// ─────────────────────────────────────────────────────────────────
//  Private: disk I/O
// ─────────────────────────────────────────────────────────────────
bool FileyProject::ensureNodesDir() {
    std::error_code ec;
    fs::create_directories(m_nodesDir, ec);
    if (ec) {
        std::cerr << "[filey] ensureNodesDir: " << ec.message() << "\n";
        return false;
    }
    return true;
}

bool FileyProject::writeMainFiley() {
    std::ofstream log("/tmp/filey_debug.log", std::ios::app);
    
    std::ofstream file(m_fileyPath, std::ios::binary | std::ios::trunc);
    if (!file) {
        log << "      -> ERROR: std::ofstream could not open: " << m_fileyPath << " for writing!\n";
        return false;
    }

    graphHeader gHdr{};
    gHdr.num_nodes = static_cast<uint32_t>(m_nodes.size());
    gHdr.num_edges = static_cast<uint32_t>(m_edges.size());

    fileHeader fHdr{};
    std::memcpy(fHdr.signature, FILEY_SIGNATURE, 6);
    fHdr.version   = FILEY_VERSION;
    fHdr.data_size = sizeof(graphHeader)
                   + sizeof(graphNode) * gHdr.num_nodes
                   + sizeof(graphEdge) * gHdr.num_edges;

    file.write(reinterpret_cast<const char*>(&fHdr),  sizeof(fHdr));
    file.write(reinterpret_cast<const char*>(&gHdr),  sizeof(gHdr));
    file.write(reinterpret_cast<const char*>(m_nodes.data()),
               sizeof(graphNode) * m_nodes.size());
    file.write(reinterpret_cast<const char*>(m_edges.data()),
               sizeof(graphEdge) * m_edges.size());

    bool ok = file.good();
    if (ok) log << "      -> SUCCESS: Wrote main.filey\n";
    else log << "      -> ERROR: file.write() failed!\n";
    
    return ok;
}

bool FileyProject::readMainFiley() {
    std::ifstream file(m_fileyPath, std::ios::binary);
    if (!file) return false;

    fileHeader fHdr{};
    file.read(reinterpret_cast<char*>(&fHdr), sizeof(fHdr));
    if (std::memcmp(fHdr.signature, FILEY_SIGNATURE, 6) != 0) {
        std::cerr << "[filey] readMainFiley: bad signature\n";
        return false;
    }
    if (fHdr.version != FILEY_VERSION) {
        if (fHdr.version == 2) {
            std::cerr << "[filey] readMainFiley: migrating from V2\n";
            graphHeader gHdr{};
            file.read(reinterpret_cast<char*>(&gHdr), sizeof(gHdr));

            struct graphNodeV2 {
                char     id[37];
                char     label[128];
                char     content_file[40];
                float    x;
                float    y;
                uint32_t color_tag;
                uint8_t  _pad[4];
            };

            std::vector<graphNodeV2> oldNodes(gHdr.num_nodes);
            file.read(reinterpret_cast<char*>(oldNodes.data()), sizeof(graphNodeV2) * gHdr.num_nodes);

            m_nodes.resize(gHdr.num_nodes);
            for (size_t i=0; i<gHdr.num_nodes; ++i) {
                std::memcpy(m_nodes[i].id, oldNodes[i].id, 37);
                std::memcpy(m_nodes[i].label, oldNodes[i].label, 128);
                std::memcpy(m_nodes[i].content_file, oldNodes[i].content_file, 40);
                m_nodes[i].x = oldNodes[i].x;
                m_nodes[i].y = oldNodes[i].y;
                m_nodes[i].color_tag = oldNodes[i].color_tag;
                std::memset(m_nodes[i]._pad, 0, sizeof(m_nodes[i]._pad)); // Zero new padding
            }

            m_edges.resize(gHdr.num_edges);
            file.read(reinterpret_cast<char*>(m_edges.data()), sizeof(graphEdge) * gHdr.num_edges);

            return file.good() || file.eof();
        }

        std::cerr << "[filey] readMainFiley: version mismatch "
                  << fHdr.version << " != " << FILEY_VERSION << "\n";
        return false;
    }

    graphHeader gHdr{};
    file.read(reinterpret_cast<char*>(&gHdr), sizeof(gHdr));

    m_nodes.resize(gHdr.num_nodes);
    file.read(reinterpret_cast<char*>(m_nodes.data()),
              sizeof(graphNode) * gHdr.num_nodes);

    m_edges.resize(gHdr.num_edges);
    file.read(reinterpret_cast<char*>(m_edges.data()),
              sizeof(graphEdge) * gHdr.num_edges);

    return file.good() || file.eof();
}

}
