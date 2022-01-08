--[[
**
**  birddog-camera-preset.html ~ Recall Birddog Camera Preset from OBS Studio
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
    local req
    if type == nil and body == nil then
        req = "GET " .. path .. " HTTP/1.1\r\n"
    else
        req = "POST " .. path .. " HTTP/1.1\r\n"
    end
    req = req ..
        "Host: " .. host .. "\r\n" ..
        "User-Agent: OBS-Studio/Birddog-Camera-Preset\r\n" ..
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
    --  obs.script_log(obs.LOG_INFO, string.format("HTTP: connect: \"%s:%d\"", host, port))
    local socket = ljsocket.create("inet", "stream", "tcp")
    socket:set_blocking(false)
    socket:connect(host, port)
    local count = 0
    while true do
        if socket:is_connected() then
            --  send request
            --  obs.script_log(obs.LOG_INFO, string.format("HTTP: send: \"%s\"", req))
            local _, err = socket:send(req)
            if err == "timeout" then
                obs.script_log(obs.LOG_ERROR, string.format("HTTP: send: error: %s -- aborting", err))
                socket:close()
                return nil
            end

            --  receive response
            local res = ""
            local total_length = 0
            while true do
                local chunk, err2 = socket:receive()
                if chunk then
                    res = res .. chunk
                    if not total_length then
                        total_length = tonumber(res:match("Content%-Length: (%d+)"))
                    end
                    if #res >= total_length then
                        --  obs.script_log(obs.LOG_INFO, string.format("HTTP: receive: \"%s\"", res))
                        socket:close()
                        return res
                    end
                elseif err2 ~= "timeout" then
                    obs.script_log(obs.LOG_ERROR, string.format("HTTP: receive: error: %s -- aborting", err2))
                    socket:close()
                    return nil
                end
            end
        else
            local _, err = socket:poll_connect()
            if err ~= "timeout" then
                obs.script_log(obs.LOG_ERROR, string.format("HTTP: poll: error: %s -- aborting", err))
                return nil
            else
                count = count + 1
                if count > 100 then
                    obs.script_log(obs.LOG_ERROR, string.format("HTTP: poll: too many connect timeouts in sequence"))
                    return nil
                end
            end
        end
    end
end

--  recall a pre-defined PTZ preset on a Birddog camera
local function recall (address, preset)
     obs.script_log(obs.LOG_INFO,
         string.format("recalling PTZ preset #%d on Birddog camera %s", preset, address))
     local res = httpRequest(address, 8080, "/recall",
         "application/json", "{ \"Preset\": \"Preset-" .. preset .. "\" }")
     local code = tonumber(res:match("HTTP/1.1 (%d+) "))
     if code ~= 200 then
         obs.script_log(obs.LOG_ERROR,
             string.format("Birddog camera answered with HTTP response code %d", code))
     end
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
    obs.obs_data_set_default_string(settings, "address", "192.168.0.1")
    obs.obs_data_set_default_string(settings, "preset1", "none")
    obs.obs_data_set_default_string(settings, "preset2", "none")
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
        address = "192.168.0.1",
        preset1 = "none",
        preset2 = "none"
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
    --  take current parameters
    filter.cfg.address = obs.obs_data_get_string(settings, "address")
    filter.cfg.preset1 = obs.obs_data_get_string(settings, "preset1")
    filter.cfg.preset2 = obs.obs_data_get_string(settings, "preset2")

    --  hook: activate (preview)
    obs.obs_frontend_add_event_callback(function (ev)
        if ev == obs.OBS_FRONTEND_EVENT_PREVIEW_SCENE_CHANGED then
            if filter.parent ~= nil then
                local sceneSource      = obs.obs_frontend_get_current_preview_scene()
                local sceneSourceName  = obs.obs_source_get_name(sceneSource)
                local filterSourceName = obs.obs_source_get_name(filter.parent)
                local scene            = obs.obs_scene_from_source(sceneSource)
                local sceneItem        = obs.obs_scene_find_source_recursive(scene, filterSourceName)
                obs.obs_source_release(sceneSource)
                if sceneItem then
                    if filter.cfg.preset1 ~= "none" then
                        obs.script_log(obs.LOG_INFO, string.format(
                            "hook: scene \"%s\" with filter source \"%s\" is in PREVIEW now -- reacting",
                            sceneSourceName, filterSourceName))
                        recall(filter.cfg.address, filter.cfg.preset1)
                    end
                end
            end
        end
    end)
end

--  hook: provide filter properties (for dialog)
info.get_properties = function (_filter)
    --  create properties
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "address", "Birddog Camera IP (X.X.X.X):", obs.OBS_TEXT_DEFAULT)
    local function addList (prop)
        obs.obs_property_list_add_string(prop, "none", "none")
        obs.obs_property_list_add_string(prop, "1", "1")
        obs.obs_property_list_add_string(prop, "2", "2")
        obs.obs_property_list_add_string(prop, "3", "3")
        obs.obs_property_list_add_string(prop, "4", "4")
        obs.obs_property_list_add_string(prop, "5", "5")
        obs.obs_property_list_add_string(prop, "6", "6")
        obs.obs_property_list_add_string(prop, "7", "7")
        obs.obs_property_list_add_string(prop, "8", "8")
        obs.obs_property_list_add_string(prop, "9", "9")
    end
    local preset1 = obs.obs_properties_add_list(props, "preset1", "Birddog Camera PTZ Preset on PREVIEW:",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local preset2 = obs.obs_properties_add_list(props, "preset2", "Birddog Camera PTZ Preset on PROGRAM:",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    addList(preset1)
    addList(preset2)
    return props
end

--  hook: react on filter property update (during dialog)
info.update = function (filter, settings)
    filter.cfg.address = obs.obs_data_get_string(settings, "address")
    filter.cfg.preset1 = obs.obs_data_get_string(settings, "preset1")
    filter.cfg.preset2 = obs.obs_data_get_string(settings, "preset2")
end

--  hook: activate (program)
info.activate = function (filter)
    if filter.cfg.preset2 ~= "none" then
        if filter.parent ~= nil then
            local sceneSource      = obs.obs_frontend_get_current_scene()
            local sceneSourceName  = obs.obs_source_get_name(sceneSource)
            local filterSourceName = obs.obs_source_get_name(filter.parent)
            obs.obs_source_release(sceneSource)
            obs.script_log(obs.LOG_INFO, string.format(
                "hook: scene \"%s\" with filter source \"%s\" is in PROGRAM now -- reacting",
                sceneSourceName, filterSourceName))
            recall(filter.cfg.address, filter.cfg.preset2)
        end
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
        href="https://spdx.org/licenses/GPL-3.0-only.html">GPL 3.0 license</a>

        <p>
        Define a <b>Birddog Camera Preset</b> filter for sources. This is intended
        to allow OBS Studio to force a Birddog camera to recall a pre-defined
        Pan/Tilt/Zooom (PTZ) preset in case the source becomes visible
        in the PREVIEW (for enabled studio mode only) and/or PROGRAM.
        </p>
    ]]
end

