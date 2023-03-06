#ifndef LIVESPLITCONNECTION_LUA_INTERFACE_H
#define LIVESPLITCONNECTION_LUA_INTERFACE_H

#include <superblt_flat.h>

int connect(lua_State *L);
int send_command(lua_State *L);
int send_command_and_get_result(lua_State *L);

#endif //LIVESPLITCONNECTION_LUA_INTERFACE_H
