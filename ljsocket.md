
LJSocket
========

This is a copy of the [MIT-licensed](https://github.com/CapsAdmin/luajitsocket/blob/master/LICENSE)
[Lua source code](https://raw.githubusercontent.com/CapsAdmin/luajitsocket/master/ljsocket.lua)
of the [LuaJITSocket](https://github.com/CapsAdmin/luajitsocket/)
project, a pure LuaJIT FFI socket binding module
for Unix and Windows, which resembles the non-pure
[LuaSocket](https://w3.impa.br/~diego/software/luasocket/) core Lua
module, but is a bit more low-level and tries to follow the Unix socket
API. It allows us to implement basic HTTP operations within
[OBS Studio](https://obsproject.com)'s LuaJIT implementation, which lacks
network socket support.

