cmake_minimum_required(VERSION 3.18)
project(speech_ios_wrapper)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# iOS-specific threading
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    set(CMAKE_THREAD_LIBS_INIT "-lpthread")
endif()

# Build static libraries
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

# ═══════════════════════════════════════════════════════════════
#                        PATHS
# ═══════════════════════════════════════════════════════════════

set(WHISPER_DIR    "${CMAKE_SOURCE_DIR}/../../../third_party/whisper.cpp")
set(SHERPA_DIR     "${CMAKE_SOURCE_DIR}/../../../third_party/sherpa-onnx")
set(IOS_CPP_DIR    "${PROJECT_SOURCE_DIR}/../../src/iosMain/cpp")
set(IOS_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/../../src/iosMain/c_interop/include")

# ═══════════════════════════════════════════════════════════════
#                      WHISPER.CPP (STT)
# ═══════════════════════════════════════════════════════════════

set(WHISPER_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GGML_METAL             ON  CACHE BOOL "" FORCE)
set(GGML_ACCELERATE        ON  CACHE BOOL "" FORCE)
set(WHISPER_COREML                  ON  CACHE BOOL "" FORCE)
set(WHISPER_COREML_ALLOW_FALLBACK   ON  CACHE BOOL "" FORCE)

if(EXISTS ${WHISPER_DIR}/CMakeLists.txt)
    add_subdirectory(${WHISPER_DIR} whisper-build EXCLUDE_FROM_ALL)
    set(WHISPER_FOUND TRUE)
else()
    message(WARNING "whisper.cpp not found at ${WHISPER_DIR}")
    set(WHISPER_FOUND FALSE)
endif()

# ═══════════════════════════════════════════════════════════════
#                    TTS (SHERPA-ONNX)
# ═══════════════════════════════════════════════════════════════

if(EXISTS ${SHERPA_DIR}/CMakeLists.txt)
    set(SHERPA_ONNX_ENABLE_PYTHON       OFF CACHE BOOL "" FORCE)
    set(SHERPA_ONNX_ENABLE_TESTS        OFF CACHE BOOL "" FORCE)
    set(SHERPA_ONNX_ENABLE_CHECK        OFF CACHE BOOL "" FORCE)
    set(SHERPA_ONNX_ENABLE_PORTAUDIO    OFF CACHE BOOL "" FORCE)
    set(SHERPA_ONNX_ENABLE_JNI          OFF CACHE BOOL "" FORCE)
    set(SHERPA_ONNX_ENABLE_C_API        ON  CACHE BOOL "" FORCE)

    add_subdirectory(${SHERPA_DIR} sherpa-build EXCLUDE_FROM_ALL)
    set(SHERPA_FOUND TRUE)
    message(STATUS "sherpa-onnx found — TTS enabled")
else()
    message(STATUS "sherpa-onnx not found at ${SHERPA_DIR} — TTS will use no-op stubs")
    set(SHERPA_FOUND FALSE)
endif()

# ═══════════════════════════════════════════════════════════════
#                    iOS WRAPPER LIBRARY
# ═══════════════════════════════════════════════════════════════

add_library(speech_static STATIC
    ${IOS_CPP_DIR}/whisper_ios.cpp
    ${IOS_CPP_DIR}/deviceai_tts_ios.cpp
)

target_include_directories(speech_static PRIVATE
    ${IOS_INCLUDE_DIR}
    ${WHISPER_DIR}/include
    ${WHISPER_DIR}
)

if(SHERPA_FOUND)
    target_compile_definitions(speech_static PRIVATE HAVE_SHERPA_ONNX=1)
    target_include_directories(speech_static PRIVATE ${SHERPA_DIR})
    target_link_libraries(speech_static sherpa-onnx-c-api)
endif()

if(WHISPER_FOUND AND TARGET whisper)
    target_link_libraries(speech_static whisper)
endif()

# iOS frameworks (Foundation required for CoreML)
target_link_libraries(speech_static
    "-framework Foundation"
    "-framework Accelerate"
    "-framework Metal"
    "-framework MetalKit"
    "-framework CoreML"
)

find_package(Threads REQUIRED)
target_link_libraries(speech_static Threads::Threads)

set_target_properties(speech_static PROPERTIES
    OUTPUT_NAME "speech_static"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    POSITION_INDEPENDENT_CODE ON
)

# ═══════════════════════════════════════════════════════════════
#                    COMPILE FLAGS
# ═══════════════════════════════════════════════════════════════

target_compile_options(speech_static PRIVATE
    -fPIC
    -fvisibility=hidden
    -O3
)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    target_compile_options(speech_static PRIVATE
        -fembed-bitcode
    )
endif()
