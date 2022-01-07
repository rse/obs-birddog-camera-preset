
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

License
-------

Copyright &copy; 2022 [Dr. Ralf S. Engelschall](http://engelschall.com/)<br/>
Distributed under [GPL 3.0 license](https://spdx.org/licenses/GPL-3.0-only.html)

