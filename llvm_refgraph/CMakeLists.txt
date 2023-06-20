project(ProjectName)
cmake_minimum_required(VERSION 3.22)

find_package(LLVM 15 REQUIRED CONFIG)

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_definitions(${LLVM_DEFINITIONS_LIST})
include_directories(${LLVM_INCLUDE_DIRS})

add_llvm_library( LLVMrefgraph MODULE
  refgraph.cpp

  PLUGIN_TOOL
  opt
  )
