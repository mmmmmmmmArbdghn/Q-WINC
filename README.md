# Q-WINC
A repository for the quick ui window creator module in roadblocks, since they've practically unobtainable after the markerplace distribution changes update

# Qredits
- `@Fraktality` on GitHub for the "neon" module, for which I have modified to fit to the form factor of Q-WINC
- The `Roblox DevForum` community from anchient to recent for helping fix stupid and complex things
- `Copilot` (the one with the red and blue ribbons), which helps with tons of things (like sounding the tornado alarms about most memory leaks)
- `Me`, oh no what bug is it this time
- `Anonymous`, I'm sorry for which I have forgotten 😭 If you've found this, please comment to make me rember 📥😭
- Etc. (If I forgot to edit this)

# What's inqluded:
- Q-WINC (or internally named "Windows") by `me`, which is the orchestrator
- Legacy Q-WINC by `me`, which is basically just the old spaghetti version of Q-WINC
------------------------------------------------------------------------------------
- SpringV2 (& Spring) by `me`, handles the boioioing physics
- Debug by `me`, handles debugging values in real-time to diagnose myself with stupid because i forgot to rename a variable
- neon (modified to UIMaterial) original by `@Fraktality`, handles the material effects like glass
- HapticManagerV2 by `me`, handles the brrr of devices a little too well
- FSearch by `anonymous`, nothing else besides matching theme names by searching for the closest match
- GetScreenInset by `anonymous`, handles getting the weird screen insets that Roblox has
- PointConverter by `me`, handles projecting the mouse & touch cursors onto SurfaceGuis
- QuickLogViewer by `me`, can let players view local error logs if you enable it
- RateLimiter by `me` and `Copilot` (i'm too stupid to handle web events), handles limiting request rates so people can't spam APIs
- Etc. (If I forgot to edit this)

# i think i'll add use examples and the doqumentations later

As a starting doc, make sure in Roblox to put everything in the same hierarchy as `Windows.lua` except for itself, to `Windows.lua`. Put the `Dark.rbxm` theme in the `Themes` folder because it's the base theme. Otherwise, everything explodes.
