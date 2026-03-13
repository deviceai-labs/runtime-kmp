cmake_minimum_required(VERSION 3.22)
project(llm_static)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ═══════════════════════════════════════════════════════════════
#                           PATHS
# ═══════════════════════════════════════════════════════════════

set(LLAMA_DIR  "${CMAKE_SOURCE_DIR}/../../../../llama.cpp")
set(ENGINE_DIR "${CMAKE_SOURCE_DIR}/../../../../cpp/llm")

# ═══════════════════════════════════════════════════════════════
#                         llama.cpp
# ═══════════════════════════════════════════════════════════════

set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(GGML_METAL           ON  CACHE BOOL "" FORCE)  # Metal acceleration on iOS
set(BUILD_SHARED_LIBS    OFF CACHE BOOL "" FORCE)  # Static libs for embedding

if(EXISTS ${LLAMA_DIR}/CMakeLists.txt)
    add_subdirectory(${LLAMA_DIR} llama-build EXCLUDE_FROM_ALL)
else()
    message(FATAL_ERROR "llama.cpp not found at ${LLAMA_DIR}")
endif()

# ═══════════════════════════════════════════════════════════════
#                     Bridge static library
# ═══════════════════════════════════════════════════════════════

add_library(llm_static STATIC
    ${ENGINE_DIR}/deviceai_llm_engine.cpp
)

target_include_directories(llm_static PRIVATE
    ${ENGINE_DIR}
    ${LLAMA_DIR}/include
    ${LLAMA_DIR}
)

target_link_libraries(llm_static llama)

target_compile_options(llm_static PRIVATE
    -fvisibility=hidden
    -O3
)
