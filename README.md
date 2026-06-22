<p align="center">
  <img src="https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/asset scope.png" width="600">
</p>

# Loadstring
<pre>
  <span>loadstring(game:HttpGet("https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/assetscope.lua"))()</span>
</pre>

This script is intended for extracting game assets from Roblox games. It constantly updates every time a new asset is found.
<hr>
This script also allows you to dump all images into your executor's workspace, save separate images, see where the asset came from, copy paths (ex: game.Workspace.SoundEffect1), copy names of the asset, copy ids (ex: rbxassetid://1234567890), show an image preview of the image, view the asset with the CurrentCamera, execute remote events/functions, and see the type of the asset.
<hr>


# Showcase of the script in Murder Mystery 2:

<p align="center">
  <img src="https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/mm2 example.png" width="800" style="border-radius: 12px;">
</p>

# This is a list of what it grabs:

<pre>
  <span>• ImageLabel</span>
  <span>• ImageButton</span>
  <span>• Decal</span>
  <span>• Texture</span>
  <span>• ParticleEmitter</span>
  <span>• Trail</span>
  <span>• Beam</span>
  <span>• MeshPart</span>
  <span>• SpecialMesh</span>
  <span>• SurfaceAppearance</span>
  <span>• Sky</span>
  <span>• VideoFrame</span>
  <span>• ImageHandleAdornment</span>
  <span>• Handle</span>
  <span>• ArcHandle</span>
  <span>• Sound</span>
  <span>• RemoteEvent</span>
  <span>• RemoteFunction</span>
  <span>• EditableImage</span>
</pre>

# And these are the asset fields it extracts from them:

<pre>
  <span>• Image</span>
  <span>• Texture</span>
  <span>• TextureID</span>
  <span>• TextureId</span>
  <span>• ColorMap</span>
  <span>• NormalMap</span>
  <span>• RoughnessMap</span>
  <span>• MetalnessMap</span>
  <span>• SkyboxBk</span>
  <span>• SkyboxDn</span>
  <span>• SkyboxFt</span>
  <span>• SkyboxLf</span>
  <span>• SkyboxRt</span>
  <span>• SkyboxUp</span>
  <span>• Video</span>
  <span>• SoundId</span>
  <span>• (and raw asset IDs parsed from any rbxassetid:// string)</span>

# You may encounter bugs. If you do, just re-execute the script and it should be working again.
</pre>
