// Simple CLI smoke-test for filey_core
// Build: cmake --build build && ./build/filey_cli
#include "filey_project.h"
#include <iostream>
#include <cassert>
#include <filesystem>

int main() {
    const std::string testDir = "/tmp/filey_test_project";

    // Clean up any previous run
    std::filesystem::remove_all(testDir);

    std::cout << "=== filey_core CLI test ===\n\n";

    filey::FileyProject proj;

    // 1. Create project
    assert(proj.create(testDir) && "create failed");
    std::cout << "[OK] project created at " << testDir << "\n";

    // 2. Add nodes
    auto idA = proj.addNode("Alpha",  -1.f,  0.f);
    auto idB = proj.addNode("Beta",    1.f,  0.f);
    auto idC = proj.addNode("Gamma",   0.f,  1.5f);
    assert(!idA.empty() && !idB.empty() && !idC.empty());
    std::cout << "[OK] added 3 nodes: " << idA << " | " << idB << " | " << idC << "\n";

    // 3. Write markdown
    proj.writeNodeContent(idA, "# Alpha\n\nThis is the **alpha** node.\n");
    proj.writeNodeContent(idB, "# Beta\n\nConnected to Alpha.\n");
    proj.writeNodeContent(idC, "# Gamma\n\nThe apex node.\n");
    std::cout << "[OK] wrote markdown to all nodes\n";

    // 4. Read back
    auto content = proj.readNodeContent(idA);
    assert(content.find("alpha") != std::string::npos);
    std::cout << "[OK] read content: " << content.substr(0, 30) << "...\n";

    // 5. Add edges
    assert(proj.addEdge(idA, idB));
    assert(proj.addEdge(idB, idC));
    assert(proj.addEdge(idA, idC));
    std::cout << "[OK] added 3 edges\n";

    // 6. Duplicate edge check
    assert(!proj.addEdge(idA, idB) && "duplicate edge should be rejected");
    std::cout << "[OK] duplicate edge correctly rejected\n";

    // 7. Save
    assert(proj.save());
    std::cout << "[OK] saved to " << testDir << "/main.filey\n";

    // 8. Reload
    filey::FileyProject proj2;
    assert(proj2.open(testDir));
    assert(proj2.nodes().size() == 3);
    assert(proj2.edges().size() == 3);
    std::cout << "[OK] reloaded: " << proj2.nodes().size()
              << " nodes, " << proj2.edges().size() << " edges\n";

    // 9. Remove node
    assert(proj2.removeNode(idB));
    assert(proj2.nodes().size() == 2);
    // edges connected to B should be gone
    assert(proj2.edges().size() == 1);
    std::cout << "[OK] removed node B → edges reduced to "
              << proj2.edges().size() << "\n";

    // 10. Rename
    assert(proj2.renameNode(idA, "Alpha Renamed"));
    auto* n = proj2.findNode(idA);
    assert(n && std::string(n->label) == "Alpha Renamed");
    std::cout << "[OK] renamed node A\n";

    std::cout << "\n=== All tests passed ===\n";
    return 0;
}
