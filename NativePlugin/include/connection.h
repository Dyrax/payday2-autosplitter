#ifndef LIVESPLITCONNECTION_CONNECTION_H
#define LIVESPLITCONNECTION_CONNECTION_H

#include <windows.h>
#include <string>

class Connection {
private:
    HANDLE file_handle;
public:
    Connection();
    ~Connection();

    bool connect();

    bool sendCommand(std::string cmd);
    bool getCmdResultBlocking(std::string& result);
    bool getCmdResultTimeout(std::string& result, int time);
};

#endif //LIVESPLITCONNECTION_CONNECTION_H
