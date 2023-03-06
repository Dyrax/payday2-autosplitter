#include "connection.h"
#include <chrono>

using namespace std;

Connection::Connection() {
    file_handle = INVALID_HANDLE_VALUE;
}

Connection::~Connection() {
    if (file_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(file_handle);
    }
}

bool Connection::connect() {
    if (file_handle != INVALID_HANDLE_VALUE) {
        // Write empty string to test if handle is valid
        if (WriteFile(file_handle, "", 0, nullptr, nullptr)) {
            return true;
        }
        CloseHandle(file_handle);
    }
    file_handle = CreateFile(
            "//./pipe/LiveSplit",
            GENERIC_READ | GENERIC_WRITE,
            0,
            nullptr,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            nullptr);

    return file_handle != INVALID_HANDLE_VALUE;
}

bool Connection::sendCommand(string cmd) {
    cmd = cmd + "\n";
    if (!WriteFile(file_handle,
                   cmd.c_str(),
                   cmd.length(),
                   nullptr,
                   nullptr))
        return false;
    return FlushFileBuffers(file_handle);
}

bool Connection::getCmdResultBlocking(string& result) {
    result = "";
    while (true) {
        char c;
        if (!ReadFile(file_handle, &c, 1, nullptr, nullptr))
            return false;
        if (c == '\n') {
            return true;
        } else if (c != '\r') {
            result += c;
        }
    }
}

bool Connection::getCmdResultTimeout(string& result, int timeout) {
    result = "";
    chrono::steady_clock::time_point begin = chrono::steady_clock::now();
    do {
        DWORD charsInPipe = 0;
        if (!PeekNamedPipe(file_handle, nullptr, 0, nullptr, &charsInPipe, nullptr))
            return false;
        for (DWORD i = 0; i < charsInPipe; i++) {
            char c;
            if (!ReadFile(file_handle, &c, 1, nullptr, nullptr))
                return false;
            if (c == '\n') {
                return true;
            } else if (c != '\r') {
                result += c;
            }
        }
    } while(chrono::duration_cast<chrono::milliseconds>(chrono::steady_clock::now() - begin).count() < timeout);
    return false;
}