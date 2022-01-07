
OBS-Birddog-Camera-Preset
=========================

**Recall Birddog Camera Preset from OBS Studio**

About
-----

This is a two-fold way to recall defined PTZ presets on a [Birddog](https://bird-dog.tv/) camera
from within [OBS Studio](https://obsproject.com) through the Birddog
[RESTful API](https://bird-dog.tv/SW/API/index.html#api-PTZ-recallPost) of the camera.

The first way of recalling a preset is a manual one through a tiny HTML5
Single-Page-Application (SPA), intended to be running inside a [OBS
Source Dock](https://github.com/exeldro/obs-source-dock) inside [OBS
Studio](https://obsproject.com). The SPA is usually running in a scene where it
sits on top of a preview of the camera video stream.

The second way of recalling a preset is an automatic one through an OBS Lua
based scene/source filter which recalls the camera preset automatically once the
scene/source becomes active (is shown in the program).

Usage
-----

- **Automatic Recall via Source Filter**

  This allows you to automatically recall a preset once the source this
  filter is attached to becomes active in the program. For this, simply
  add the filter `Birddog Camera Preset` to an arbitrary source and
  enter the IP address and preset number as filter parameters.

- **Manually Recall via Source Dock**

  This allows you to manually recall a preset by clicking onto a
  button in a OBS Studio user interface dock. For this, create a
  scene with the SPA in a `Browser Source` at the top of the
  source list and a `Source Mirror` (from the [StreamFX](https://github.com/Xaymar/obs-streamfx) plugin) below, which
  just mirrors the scene/source of your camera. Then create
  a user interface dock for the scene with the help of the
  [OBS Source Dock](https://github.com/exeldro/obs-source-dock) plugin. The URL of the SPA in the Browser Source is:

  `file://[...]/birddog-camera-preset.html` (path to SPA)<br/>
  `?transparent=true` (make background transparent)<br/>
  `&camera=192.168.0.1` (the IP address of the Birddog camera)<br/>
  `&presets=1,2,3,4` (the list of used presets)

  The `presets` parameter takes a comma-separated list of up to nine
  presets (1-9). Each preset can be just the number like `1` or
  alternatively a number plus a mapping to a name like `1:Total`.

License
-------

Copyright &copy; 2022 [Dr. Ralf S. Engelschall](http://engelschall.com/)<br/>
Distributed under [GPL 3.0 license](https://spdx.org/licenses/GPL-3.0-only.html)

