# Asset Scope

<p align="center">
  <img src="https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/asset%20scope.png" width="700">
</p>

<p align="center">
  <b>A real-time Roblox asset discovery and extraction tool.</b>
</p>

---

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/squidward5/asset-scope/refs/heads/main/assetscope.lua"))()
```

---

## What is Asset Scope?

Asset Scope is a powerful Roblox asset scanner that continuously monitors a game and discovers assets as they appear.

Unlike traditional asset dumpers, Asset Scope updates in real time and provides detailed information about where assets came from, what type they are, and how they are being used inside the game.

Whether you're researching assets, inspecting game resources, locating UI elements, finding sounds, viewing skyboxes, or analyzing remotes, Asset Scope puts everything in one place.

---

## Features

- 🔍 Real-time asset discovery
- ⚡ Live updates while playing
- 🖼️ Built-in image previews
- 🎥 View assets with CurrentCamera
- 💾 Save individual assets
- 📦 Dump all discovered assets
- 📋 Copy asset IDs instantly
- 📂 Copy full instance paths
- 🏷️ Copy instance names
- 🔎 Locate the source instance
- 📡 RemoteEvent inspection
- 📡 RemoteFunction inspection
- 🧩 Automatic asset type detection
- 🎨 SurfaceAppearance support
- 🌌 Skybox support
- 🔊 Sound support
- 🎬 Video support

---

## Supported Objects

Asset Scope scans:

- ImageLabel
- ImageButton
- Decal
- Texture
- ParticleEmitter
- Trail
- Beam
- MeshPart
- SpecialMesh
- SurfaceAppearance
- Sky
- VideoFrame
- ImageHandleAdornment
- Handle
- ArcHandle
- Sound
- RemoteEvent
- RemoteFunction
- EditableImage

## Requirements

Your executor must support:

- loadstring
- game:HttpGet
- writefile
- readfile
- isfile
- isfolder
- makefolder
- request
- getcustomasset
- setclipboard (optional)

Executors such as Potassium, Volt, and other high UNC & sUNC should work fine.
