--[[
**
**  birddog-camera-preset.lua -- OBS Studio Source Filter for Recalling a Birddog Camera Preset
**  Copyright (c) 2022 Dr. Ralf S. Engelschall <rse@engelschall.com>
**  Distributed under GPL 3.0 license <https://spdx.org/licenses/GPL-3.0-only.html>
**
--]]

--  global OBS API
local obs = obslua

--  global Lua APIs
local bit      = require("bit")
local ljsocket = require("ljsocket")

--  send HTTP request
local function httpRequest (host, port, path, type, body)
    --  create HTTP request
    local req = ""
    if type == nil and body == nil then
        req = "GET " .. path .. " HTTP/1.1\r\n"
    else
        req = "POST " .. path .. " HTTP/1.1\r\n"
    end
    req = req ..
        "Host: " .. host .. "\r\n" ..
        "User-Agent: OBS-Studio\r\n" ..
        "Accept: */*\r\n" ..
        "Connection: keep-alive\r\n"
    if not (type == nil and body == nil) then
        req = req ..
            "Content-Type: " .. type .."\r\n" ..
            "Content-Length: " .. string.len(body) .."\r\n" ..
            "\r\n" ..
            body
    end

    --  connect to the server
    obs.script_log(obs.LOG_INFO, string.format("httpRequest: connect: \"%s:%d\"", host, port))
    local socket = ljsocket.create("inet", "stream", "tcp")
    socket:set_blocking(false)
    socket:connect(host, port)
    while true do
        if socket:is_connected() then
            --  send request
            obs.script_log(obs.LOG_INFO, string.format("httpRequest: send: \"%s\"", req))
            local ok, err = socket:send(req)
            if err == "timeout" then
                obs.script_log(obs.LOG_INFO, string.format("httpRequest: send: error: %s -- aborting", err))
                return nil
            end

            --  receive response
            local res = ""
            local total_length = 0
            while true do
                local chunk, err = socket:receive()
                if chunk then
                    res = res .. chunk
                    if not total_length then
                        total_length = tonumber(res:match("Content%-Length: (%d+)"))
                    end
                    if #res >= total_length then
                        obs.script_log(obs.LOG_INFO, string.format("httpRequest: receive: \"%s\"", res))
                        return res
                    end
                elseif err ~= "timeout" then
                    obs.script_log(obs.LOG_INFO, string.format("httpRequest: receive: error: %s -- aborting", err))
                    return nil
                end
            end
        else
            local ok, err = socket:poll_connect()
            if err ~= "timeout" then
                obs.script_log(obs.LOG_INFO, string.format("httpRequest: poll: error: %s -- aborting", err))
                return nil
            end
        end
    end
end

--  recall a pre-defined PTZ preset on a Birddog camera
local function recall (address, preset)
     obs.script_log(obs.LOG_INFO,
         string.format("recall PTZ preset #%d on Birddog camera %s", preset, address))
     httpRequest(address, 8080, "/recall",
         "application/json", "{ \"Preset\": \"Preset-" .. preset .. "\" }")
end

--  create obs_source_info structure
local info = {}
info.id           = "birddog_camera_preset"
info.type         = obs.OBS_SOURCE_TYPE_FILTER
info.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO)

--  hook: provide name of filter
info.get_name = function ()
    return "Birddog Camera Preset"
end

--  hook: provide default settings (initialization before create)
info.get_defaults = function (settings)
    --  provide default values
    obs.obs_data_set_default_bool(settings, "program", true)
    obs.obs_data_set_default_string(settings, "address", "192.168.0.1")
    obs.obs_data_set_default_int(settings, "preset", 1)
end

--  hook: create filter context
info.create = function (_settings, source)
    --  create new filter context object
    local filter = {}
    filter.source = source
    filter.parent = nil
    filter.width  = 0
    filter.height = 0
    filter.name = obs.obs_source_get_name(source)
    filter.cfg = {
        program = true,
        address = "192.168.0.1",
        preset  = 1
    }
    obs.script_log(obs.LOG_INFO, string.format("hook: create: filter name: \"%s\"", filter.name))
    return filter
end

--  hook: destroy filter context
info.destroy = function (filter)
    --  free resources only (notice: no more logging possible)
    filter.source = nil
    filter.name   = nil
    filter.cfg    = nil
end

--  hook: after loading settings
info.load = function (filter, settings)
    filter.cfg.program = obs.obs_data_get_bool(settings, "program")
    filter.cfg.address = obs.obs_data_get_string(settings, "address")
    filter.cfg.preset  = obs.obs_data_get_int(settings, "preset")
end

--  hook: provide filter properties (for dialog)
info.get_properties = function (_filter)
    --  create properties
    local props = obs.obs_properties_create()
    obs.obs_properties_add_bool(props, "program", "Activate preset when scene becomes active in Program only")
    obs.obs_properties_add_text(props, "address", "Birddog Camera IP (X.X.X.X):", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_int(props, "preset", "Birddog Camera PTZ Preset (1-9):", 1, 9, 1)
    return props
end

--  hook: react on filter property update (during dialog)
info.update = function (filter, settings)
    filter.cfg.program = obs.obs_data_get_string(settings, "program")
    filter.cfg.address = obs.obs_data_get_string(settings, "address")
    filter.cfg.preset  = obs.obs_data_get_int(settings, "preset")
end

--  hook: activate (program)
info.activate = function (filter)
    if filter.cfg.program then
        recall(filter.cfg.address, filter.cfg.preset)
    end
end

--  hook: show (anywhere)
info.show = function (filter)
    if not filter.cfg.program then
        recall(filter.cfg.address, filter.cfg.preset)
    end
end

--  hook: render video
info.video_render = function (filter, _effect)
    if filter.parent == nil then
        filter.parent = obs.obs_filter_get_parent(filter.source)
    end
    if filter.parent ~= nil then
        filter.width  = obs.obs_source_get_base_width(filter.parent)
        filter.height = obs.obs_source_get_base_height(filter.parent)
    end
    obs.obs_source_skip_video_filter(filter.source)
end

--  hook: provide size
info.get_width = function (filter)
    return filter.width
end
info.get_height = function (filter)
    return filter.height
end

--  register the filter
obs.obs_register_source(info)

--  script hook: description displayed on script window
function script_description ()
    return [[
        <h2>Birddog Camera Preset</h2>

        Copyright &copy; 2022 <a style="color: #ffffff; text-decoration: none;"
        href="http://engelschall.com">Dr. Ralf S. Engelschall</a><br/>
        Distributed under <a style="color: #ffffff; text-decoration: none;"
        href="https://spdx.org/licenses/MIT.html">MIT license</a>

        <p>
        <b>Define a Birddog Camera Preset filter for sources. This is intended
        to allow OBS Studio to force a Birddog camera to recall a pre-defined
        Pan/Tilt/Zooom (PTZ) preset in case the source becomes visible (aka shown)
        in any display or visible (aka active) in the Program.</b>
        </p>
    ]]
end

