#include "lua_interface.h"
#include "connection.h"
#include <mutex>

using namespace std;

static Connection connection;
static mutex connection_mutex;

int connect(lua_State *L) {
    const lock_guard<mutex> lock(connection_mutex);
    bool success = connection.connect();
    lua_pushboolean(L, success);
    return 1;
}

int send_command(lua_State *L) {
    const lock_guard<mutex> lock(connection_mutex);

    string command = luaL_checkstring(L, 1);
    bool success = connection.sendCommand(command);
    lua_pushboolean(L, success);
    return 1;
}

int send_command_and_get_result(lua_State *L) {
    const lock_guard<mutex> lock(connection_mutex);

    string command = luaL_checkstring(L, 1);
    bool success = connection.sendCommand(command);
    string result;
    if (success) {
        static const int TIMEOUT = 1000;
        success = connection.getCmdResultTimeout(result, TIMEOUT);
    }
    if (success)
        lua_pushstring(L, result.c_str());
    else
        lua_pushnil(L);
    return 1;
}
