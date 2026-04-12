cmake_minimum_required(VERSION 3.18)
project(filey_core VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ── Source files ───────────────────────────────────────────────────
set(FILEY_SOURCES
    src/filey_project.cpp
    src/filey_ffi.cpp
)

set(FILEY_HEADERS
    include/filey_data.h
    include/filey_uuid.h
    include/filey_project.h
    include/filey_ffi.h
)

# ── Shared library (.so for Linux) ────────────────────────────────
add_library(filey_core SHARED ${FILEY_SOURCES} ${FILEY_HEADERS})

target_include_directories(filey_core
    PUBLIC  ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Link filesystem (needed on some GCC versions)
target_link_libraries(filey_core PRIVATE stdc++fs)

# Export symbols needed by Dart FFI
set_target_properties(filey_core PROPERTIES
    OUTPUT_NAME   "filey_core"
    SOVERSION     2
    CXX_VISIBILITY_PRESET default
    VISIBILITY_INLINES_HIDDEN OFF
)

# ── CLI test binary ────────────────────────────────────────────────
add_executable(filey_cli src/filey_cli.cpp)
target_include_directories(filey_cli PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(filey_cli PRIVATE filey_core)

# ── Install rules (so flutter can pick up the .so) ────────────────
install(TARGETS filey_core
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
install(FILES ${FILEY_HEADERS} DESTINATION include/filey)

message(STATUS "filey_core v${PROJECT_VERSION} configured")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
