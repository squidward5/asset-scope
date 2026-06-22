<p align="center">
  <img src="https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/asset scope.png" width="600">
</p>

# Loadstring
<pre>
  <span>loadstring(game:HttpGet("https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/assetscope.lua"))()</span>
</pre>
<div class="zeroclipboard-container">
    <clipboard-copy aria-label="Copy code to clipboard" class="ClipboardButton btn btn-invisible js-clipboard-copy m-2 p-0 d-flex flex-justify-center flex-items-center" data-copy-feedback="Copied!" data-tooltip-direction="w" value="local Params = {
 RepoURL = &quot;https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/&quot;,
 SSI = &quot;saveinstance&quot;,
}
local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. &quot;.luau&quot;, true), Params.SSI)()
local Options = {} -- Documentation here https://luau.github.io/UniversalSynSaveInstance/api/SynSaveInstance
synsaveinstance(Options)" tabindex="0" role="button">
      <svg aria-hidden="true" data-component="Octicon" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-copy js-clipboard-copy-icon">
    <path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"></path><path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"></path>
</svg>
      <svg aria-hidden="true" data-component="Octicon" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-check js-clipboard-check-icon color-fg-success d-none">
    <path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"></path>
</svg>
    </clipboard-copy>
  </div>

This script is intended for extracting game assets from Roblox games. It constantly updates every time a new asset is found.
<hr>
This script also allows you to dump all images into your executor's workspace, save separate images, see where the asset came from, copy paths (ex: game.Workspace.SoundEffect1), copy names of the asset, copy ids (ex: rbxassetid://1234567890), show an image preview of the image, view the asset with the CurrentCamera, execute remote events/functions, and see the type of the asset.
<hr>


# Showcase of the script in Murder Mystery 2

<p align="center">
  <img src="https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/mm2 example" width="800">
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
