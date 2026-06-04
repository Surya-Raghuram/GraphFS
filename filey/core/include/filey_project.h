#pragma once
#include "filey_data.h"
#include <vector>
#include <string>
#include <optional>

namespace filey {

// ─────────────────────────────────────────────────────────────────
//  FileyProject  –  owns the entire on-disk project directory.
//
//  Directory layout:
//    <root>/
//      main.filey          ← binary graph (nodes + edges)
//      nodes/
//        <uuid>.md         ← one file per node
// ─────────────────────────────────────────────────────────────────
class FileyProject {
public:
    // ── lifecycle ──────────────────────────────────────────────
    FileyProject() = default;
    ~FileyProject() = default;

    // Create a brand-new project directory at `path`.
    // Returns false if the path already exists or cannot be created.
    bool create(const std::string& path);

    // Open an existing project directory.
    // Returns false if main.filey is missing or corrupt.
    bool open(const std::string& path);

    // Write main.filey (does NOT touch .md files).
    bool save();

    // Close / reset state.
    void close();

    bool isOpen() const { return m_open; }
    const std::string& rootPath() const { return m_root; }

    // ── node CRUD ──────────────────────────────────────────────
    // Create a node with given label; creates empty <uuid>.md on disk.
    // Returns the new node's UUID string, or "" on failure.
    std::string addNode(const std::string& label, float x = 0.f, float y = 0.f,
                        uint32_t colorTag = 0);

    // Delete node and its .md file.  Also removes connected edges.
    bool removeNode(const std::string& uuid);

    // Rename the label (does NOT rename the .md file – UUID is stable).
    bool renameNode(const std::string& uuid, const std::string& newLabel);

    // Move node on canvas.
    bool moveNode(const std::string& uuid, float x, float y);

    // Set colour tag.
    bool setNodeColor(const std::string& uuid, uint32_t rgba);

    // Import an external .md file: copies into nodes/, creates node entry.
    std::string importFile(const std::string& externalPath,
                               const std::string& label = "");

    // Export a node's .md to an external path with the display name.
    bool exportFile(const std::string& uuid, const std::string& destDir);

    // ── markdown content ───────────────────────────────────────
    // Read the .md content for a node.
    std::string readNodeContent(const std::string& uuid) const;

    // Write (overwrite) the .md content for a node.
    bool writeNodeContent(const std::string& uuid, const std::string& content);

    // Return the absolute path to a node's .md file.
    std::string nodeFilePath(const std::string& uuid) const;

    // ── edge CRUD ──────────────────────────────────────────────
    bool addEdge(const std::string& fromUuid, const std::string& toUuid,
                 const std::string& edgeLabel = "", bool bidirectional = true);

    bool removeEdge(const std::string& fromUuid, const std::string& toUuid);

    bool edgeExists(const std::string& fromUuid, const std::string& toUuid) const;

    // ── accessors ──────────────────────────────────────────────
    const std::vector<graphNode>& nodes() const { return m_nodes; }
    const std::vector<graphEdge>& edges() const { return m_edges; }

    // Find node by UUID (returns nullptr if not found).
    const graphNode* findNode(const std::string& uuid) const;
          graphNode* findNode(const std::string& uuid);

private:
    bool        m_open  = false;
    std::string m_root;                // absolute path to project dir
    std::string m_fileyPath;           // m_root + "/main.filey"
    std::string m_nodesDir;            // m_root + "/nodes"

    std::vector<graphNode> m_nodes;
    std::vector<graphEdge> m_edges;

    bool writeMainFiley();
    bool readMainFiley();
    bool ensureNodesDir();
    std::string nodesDir() const { return m_nodesDir; }
};

} // namespace filey
