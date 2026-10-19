# LPCAnimatedSprite2D in THORNBOUND

Upstream: https://github.com/alextrevisan/LPCAnimatedSprite2D
Godot Asset Library: https://godotengine.org/asset-library/asset/2212
Pinned commit: abe214da0a71c55a295d42ef7ea64f11dcc69769
Plugin version: 4.4.0.1, MIT. Original plugin scripts are unchanged.

Actual use: `res://bake_lpc.gd` configures LPCAnimationDataBase for each downloaded layer, calls the upstream LPCAnimatedSprite2D importer, and saves SpriteFrames into `res://art/lpc/baked/`. This project uses per-animation PNG files, not Aseprite sources. Only supported actions are enabled; idle references walk frame 0; oversized sword/axe attack frames stay 192×192. The runtime renderer samples the baked frames using one shared clock.

Godot 4.7.2 compatibility is checked by headless import, bake, composition tests, and actual rendered preview. The plugin is enabled for authoring; users playing the packaged application do not need to install it separately.
