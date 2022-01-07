
OBS-Birddog-Camera-Preset
=========================

**Recalling a Birddog Camera Preset from within OBS Studio**

About
-----

This is a two-fold way to recall defined presets on a Birddog camera
from within [OBS Studio](https://obsproject.com) through the Birddog
REST API of the camera.

The first way of control is a manual one through a tiny HTML5
Single-Page-Application (SPA), intended to be running inside a [OBS
Source Dock](https://github.com/exeldro/obs-source-dock) inside [OBS
Studio](https://obsproject.com) on top of a preview of the camera scene.

The second way of control is an automatic one through a OBS Lua
based scene/source filter which recalls the camera preset once the
scene/source becomes active (is shown in the program).

License
-------

Copyright &copy; 2022 [Dr. Ralf S. Engelschall](http://engelschall.com/)<br/>
Distributed under [GPL 3.0 license](https://spdx.org/licenses/GPL-3.0-only.html)

