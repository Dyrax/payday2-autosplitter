cmake_minimum_required(VERSION 3.0)

# This is the name of the resulting library, without
# the .dll (Windows) or .so (GNU+Linux)
set(plugin_name LiveSplitConnection)

# This is the project name, often shown in IDEs
# On Windows, this is the filename of the Visual Studio project
project(LiveSplitConnection)

# Use CXX 14
set(CMAKE_CXX_STANDARD 14)

# Set up loading of the statically-linked base library
link_directories(lib)

# Add the library
add_library(${plugin_name} SHARED src/main.cpp src/legal.cpp src/lua_interface.cpp src/connection.cpp)
target_include_directories(${plugin_name} PUBLIC include)

# Include the base library
target_include_directories(${plugin_name} PUBLIC lib)
target_link_libraries(${plugin_name} sblt_plugin)

# Copy the dll into the mod directory
add_custom_command(
	TARGET ${plugin_name}
	POST_BUILD
	COMMAND powershell -command copy \\\"$<TARGET_FILE:${plugin_name}>\\\" \\\"${CMAKE_SOURCE_DIR}/../AutoSplitter/${plugin_name}.dll\\\"
)

# auto-ignore build directory
file(GENERATE OUTPUT ${CMAKE_BINARY_DIR}/.gitignore CONTENT "*")
