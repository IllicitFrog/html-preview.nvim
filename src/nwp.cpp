#include "server.hpp"
#include <lua.hpp>

static int nwp_new(lua_State *L) {
  (*reinterpret_cast<server **>(lua_newuserdata(L, sizeof(server *)))) =
      new server(luaL_checkstring(L, 1), luaL_checknumber(L, 2), luaL_checkstring(L, 3));
  luaL_setmetatable(L, "nwp");
  return 1;
}

static int nwp_delete(lua_State *L) {
  (*reinterpret_cast<server **>(luaL_checkudata(L, 1, "nwp")))->~server();
  return 0;
}

static int nwp_run(lua_State *L) {
  (*reinterpret_cast<server **>(luaL_checkudata(L, 1, "nwp")))->run();
  return 0;
}

static int nwp_loadMustache(lua_State *L) {
  (*reinterpret_cast<server **>(luaL_checkudata(L, 1, "nwp")))
      ->loadMustache(luaL_checkstring(L, 2));
  return 0;
}

static int nwp_unloadMustache(lua_State *L) {
  (*reinterpret_cast<server **>(luaL_checkudata(L, 1, "nwp")))
      ->unloadMustache();
  return 0;
}

static void register_nwp(lua_State *L) {

  static const luaL_Reg meta[] = {
      {"__gc", nwp_delete},
      {NULL, NULL},
  };

  static const luaL_Reg funcs[] = {
      {"run", nwp_run},
      {"loadMustache", nwp_loadMustache},
      {"unloadMustache", nwp_unloadMustache},
      {NULL, NULL},
  };

  luaL_newmetatable(L, "nwp");
  luaL_setfuncs(L, meta, 0);
  luaL_newlib(L, funcs);
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1);

  lua_pushcfunction(L, nwp_new);
}

extern "C" int luaopen_libneoweb_preview(lua_State *L) {
  luaL_openlibs(L);
  register_nwp(L);
  return 1;
}
