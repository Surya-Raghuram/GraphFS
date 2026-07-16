# GraphFS

> Visualize your knowledge. Connect your files.

GraphFS is an advanced, node-based file management and knowledge organization system. By utilizing a custom binary file format, GraphFS allows you to treat directories, files, and abstract concepts as connected "nodes" within a visual knowledge graph, rather than a static list of nested folders.

The visual interface is powered by the **Filey** application.

---

## Installation

Please refer to the detailed instructions in [Installation Guide](filey/README.md) to set up and build the visual editor required to run GraphFS workspaces.

---

## Quick Start Guide

Once you have installed the application, follow this guide to create your first workspace and begin connecting your data.

### Step 1: Create a New Project

Launch the application. On the welcome home screen, click the **New Project** button.

<p align="center">
  <img width="90%" alt="GraphFS Welcome Screen" src="https://github.com/user-attachments/assets/018a5fda-8280-4ed2-8b68-d33ebe49d792" />
</p>

### Step 2: Select Your Workspace Directory

A system dialog will appear. Navigate to and select the directory where you want to store your new graph project.

*(GraphFS will create a specialized configuration file inside this directory to manage your node connections).*

### Step 3: Add Nodes and Edit Content

Welcome to your new workspace. The primary interface features a sidebar on the left and the main visual graph canvas on the right.

1.  **Add a Node:** Click the "+" button in the sidebar to create a new entry (node).
2.  **View/Edit:** Select a node. A Markdown (.md) preview tab will open automatically.
3.  **Go Fullscreen:** You can toggle fullscreen mode for the editor to focus entirely on editing the markdown file associated with that node.

<p align="center">
  <img width="90%" alt="Editing a node in GraphFS" src="https://github.com/user-attachments/assets/b10bdde1-d86c-4288-8ce0-d09616448581" />
</p>

### Step 4: Map Your Knowledge

As you add more nodes, you can connect them visually on the canvas. Drag lines between nodes to represent relationships, dependencies, or links.

Below is an example of a mature workspace after adding multiple nodes and establishing complex connections between them.

<p align="center">
  <img width="90%" alt="A populated GraphFS workspace" src="https://github.com/user-attachments/assets/cffdefda-5cf7-46ff-a7b3-ad5fb0f0dde4" />
</p>

## Built With

*   **Flutter:** Cross-platform visual interface.
*   **C++/Dart FFI:** High-performance binary file format management.
*   **Markdown:** Standard formatting for node content.
