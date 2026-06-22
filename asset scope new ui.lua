local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local cancelSaveAll = false
local savingAll = false

local function applyGlassGradient(instance)
    local uigradient = Instance.new("UIGradient")
    uigradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    })
    uigradient.Rotation = 45
    uigradient.Parent = instance
    return uigradient
end

local function getTimeFolderName()
    local t = os.date("*t")
    return string.format(
        "%04d-%02d-%02d_%02d-%02d-%02d",
        t.year, t.month, t.day,
        t.hour, t.min, t.sec
    )
end

local function sanitize(str)
    return tostring(str):gsub("[^%w%-_ ]", "_")
end

local function extractAssetId(asset)
    if typeof(asset) ~= "string" then
        return ""
    end
    return asset:match("%d+") or ""
end

local function getImageAsset(obj)
    local assets = {}
    local function add(value)
        if typeof(value) ~= "string" then return end
        local id = extractAssetId(value)
        if id ~= "" then
            table.insert(assets, "rbxassetid://" .. id)
        end
    end

    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        table.insert(assets, "remote")
        return assets
    end

    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then add(obj.Image) end
    if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then add(obj.Texture) end
    if obj:IsA("MeshPart") then add(obj.TextureID) end
    if obj:IsA("SpecialMesh") then add(obj.TextureId) end
    if obj:IsA("SurfaceAppearance") then
        add(obj.ColorMap) add(obj.NormalMap) add(obj.RoughnessMap) add(obj.MetalnessMap)
    end
    if obj:IsA("Sky") then
        add(obj.SkyboxBk) add(obj.SkyboxDn) add(obj.SkyboxFt) add(obj.SkyboxLf) add(obj.SkyboxRt) add(obj.SkyboxUp)
    end
    if obj:IsA("VideoFrame") then add(obj.Video) end
    if obj:IsA("ImageHandleAdornment") then add(obj.Image) end
    if obj:IsA("Handles") or obj:IsA("ArcHandles") then add(obj.TextureId) end
    if obj:IsA("Sound") then add(obj.SoundId) end

    pcall(function()
        if obj:IsA("EditableImage") then add(obj.Image) end
    end)
    return assets
end

local PROJECT_FOLDER = "AssetScope"
local IMAGE_FOLDER = PROJECT_FOLDER .. "/Images"
local CONFIG_FILE = PROJECT_FOLDER .. "/config.json"

local function ensureFolders()
    if makefolder then
        pcall(function() makefolder(PROJECT_FOLDER) end)
        pcall(function() makefolder(IMAGE_FOLDER) end)
    elseif writefolder then
        pcall(function() writefolder(PROJECT_FOLDER) end)
        pcall(function() writefolder(IMAGE_FOLDER) end)
    end
end

local function loadConfig()
    ensureFolders()
    local defaultConfig = { SearchMode = "Name" }
    if readfile and isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then
            return { SearchMode = data.SearchMode or "Name" }
        end
    end
    if writefile then
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(defaultConfig)) end)
    end
    return defaultConfig
end

local function saveConfig(cfg)
    if type(cfg) ~= "table" then cfg = { SearchMode = "Name" } end
    if not writefile or not HttpService then return end
    ensureFolders()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(cfg) end)
    if not ok then warn("Config encode failed") return end
    pcall(function() writefile(CONFIG_FILE, encoded) end)
end

local config = loadConfig()

local function saveImageFromAsset(image, customFolder, imageName)
    local assetId = extractAssetId(image)
    if assetId == "" then return false, "No asset id" end
    if not request or not writefile then return false, "Executor missing request/writefile" end

    local thumbUrl = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"
    local res = request({ Url = thumbUrl, Method = "GET" })
    if not res or not res.Body then return false, "Thumbnail request failed" end

    local ok, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not ok or not decoded or not decoded.data or not decoded.data[1] then return false, "No thumbnail data" end

    local imageUrl = decoded.data[1].imageUrl
    if not imageUrl then return false, "No image URL" end

    local imgRes = request({ Url = imageUrl, Method = "GET" })
    if not imgRes or not imgRes.Body then return false, "Image download failed" end

    customFolder = customFolder or IMAGE_FOLDER
    ensureFolders()
    imageName = sanitize(imageName or ("Image_" .. assetId))
    local fileName = customFolder .. "/" .. imageName .. "_" .. assetId .. ".png"
    writefile(fileName, imgRes.Body)
    return true, fileName
end

pcall(function() -- removes a duplicate of the ui if it exists
	game.CoreGui:FindFirstChild("asset scope"):Destroy() 
end)

local gui = Instance.new("ScreenGui")
gui.Name = "asset scope"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game.CoreGui
gui.IgnoreGuiInset = true

local function previewImagePopup(imageStr, titleName)
    local existing = gui:FindFirstChild("previewpopup")
    if existing then
        existing:Destroy()
    end

    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "previewpopup"
    popupFrame.Size = UDim2.fromOffset(400, 430)
    popupFrame.Position = UDim2.fromScale(0.5, 0.5)
    popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    popupFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    popupFrame.BorderSizePixel = 0
	popupFrame.Draggable = true
	popupFrame.Active = true
	popupFrame.Selectable = true
    popupFrame.ZIndex = 5
    popupFrame.Parent = gui

    Instance.new("UICorner", popupFrame).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", popupFrame)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85

    local topText = titleName:lower()
    if #topText > 45 then
        topText = topText:sub(1, 45) .. "..."
    end

    local topLabel = Instance.new("TextLabel")
    topLabel.Size = UDim2.new(1, -40, 0, 30)
    topLabel.Position = UDim2.fromOffset(15, 5)
    topLabel.BackgroundTransparency = 1
    topLabel.Text = topText
    topLabel.Font = Enum.Font.GothamBold
    topLabel.TextSize = 12
    topLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
    topLabel.ZIndex = 5
    topLabel.Parent = popupFrame

    local closePopup = Instance.new("TextButton")
    closePopup.Size = UDim2.fromOffset(24, 24)
    closePopup.Position = UDim2.new(1, -34, 0, 8)
    closePopup.BackgroundTransparency = 1
    closePopup.Text = "×"
    closePopup.Font = Enum.Font.GothamBold
    closePopup.TextSize = 18
    closePopup.TextColor3 = Color3.fromRGB(150, 150, 160)
    closePopup.ZIndex = 5
    closePopup.Parent = popupFrame
    closePopup.MouseButton1Click:Connect(function() popupFrame:Destroy() end)

    local mainImg = Instance.new("ImageLabel")
    mainImg.Size = UDim2.fromOffset(370, 370)
    mainImg.Position = UDim2.fromOffset(15, 45)
    mainImg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainImg.BackgroundTransparency = 0.5
    mainImg.Image = imageStr
    mainImg.ZIndex = 5
    mainImg.Parent = popupFrame
    Instance.new("UICorner", mainImg).CornerRadius = UDim.new(0, 6)
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(920, 670)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.88

local sideBar = Instance.new("Frame")
sideBar.Name = "SideBar"
sideBar.Size = UDim2.new(0, 210, 1, 0)
sideBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sideBar.BackgroundTransparency = 0.75
sideBar.BorderSizePixel = 0
sideBar.Parent = mainFrame

local sideCorner = Instance.new("UICorner", sideBar)
sideCorner.CornerRadius = UDim.new(0, 14)

local sideDivider = Instance.new("Frame")
sideDivider.Name = "SideDivider"
sideDivider.Size = UDim2.new(0, 1, 1, 0)
sideDivider.Position = UDim2.new(1, -1, 0, 0)
sideDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sideDivider.BackgroundTransparency = 0.92
sideDivider.BorderSizePixel = 0
sideDivider.Parent = sideBar

local brandingContainer = Instance.new("Frame")
brandingContainer.Name = "Branding"
brandingContainer.Size = UDim2.new(1, 0, 0, 60)
brandingContainer.BackgroundTransparency = 1
brandingContainer.Parent = sideBar

local brandTitle = Instance.new("TextLabel")
brandTitle.Size = UDim2.new(1, -20, 1, 0)
brandTitle.Position = UDim2.fromOffset(16, 0)
brandTitle.BackgroundTransparency = 1
brandTitle.Text = "asset scope"
brandTitle.Font = Enum.Font.GothamBold
brandTitle.TextSize = 16
brandTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
brandTitle.TextXAlignment = Enum.TextXAlignment.Left
brandTitle.Parent = brandingContainer

local filterScroller = Instance.new("ScrollingFrame")
filterScroller.Name = "FilterScroller"
filterScroller.Size = UDim2.new(1, 0, 1, -120)
filterScroller.Position = UDim2.fromOffset(0, 60)
filterScroller.BackgroundTransparency = 1
filterScroller.BorderSizePixel = 0
filterScroller.ScrollBarThickness = 0
filterScroller.Parent = sideBar

local filterLayout = Instance.new("UIListLayout")
filterLayout.Padding = UDim.new(0, 4)
filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
filterLayout.Parent = filterScroller

local actionTray = Instance.new("Frame")
actionTray.Name = "ActionTray"
actionTray.Size = UDim2.new(1, 0, 0, 60)
actionTray.Position = UDim2.new(0, 0, 1, -60)
actionTray.BackgroundTransparency = 1
actionTray.Parent = sideBar

local saveAllBtn = Instance.new("TextButton")
saveAllBtn.Name = "SaveAllButton"
saveAllBtn.Size = UDim2.new(1, -24, 0, 36)
saveAllBtn.Position = UDim2.fromOffset(12, 10)
saveAllBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
saveAllBtn.BackgroundTransparency = 0.92
saveAllBtn.Text = "save all"
saveAllBtn.Font = Enum.Font.GothamBold
saveAllBtn.TextSize = 12
saveAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveAllBtn.AutoButtonColor = false
saveAllBtn.Parent = actionTray

Instance.new("UICorner", saveAllBtn).CornerRadius = UDim.new(0, 8)
local saStroke = Instance.new("UIStroke", saveAllBtn)
saStroke.Color = Color3.fromRGB(255, 255, 255)
saStroke.Transparency = 0.85

local workSpace = Instance.new("Frame")
workSpace.Name = "WorkSpace"
workSpace.Size = UDim2.new(1, -210, 1, 0)
workSpace.Position = UDim2.fromOffset(210, 0)
workSpace.BackgroundTransparency = 1
workSpace.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundTransparency = 1
topBar.Parent = workSpace

local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -380, 0, 36)
searchBox.Position = UDim2.fromOffset(16, 12)
searchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
searchBox.BackgroundTransparency = 0.95
searchBox.PlaceholderText = "search assets..."
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = topBar
searchBox.TextWrapped = true

Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)
local sbPad = Instance.new("UIPadding", searchBox)
sbPad.PaddingLeft = UDim.new(0, 12)
local sbStroke = Instance.new("UIStroke", searchBox)
sbStroke.Color = Color3.fromRGB(255, 255, 255)
sbStroke.Transparency = 0.9

local engineModeContainer = Instance.new("Frame")
engineModeContainer.Name = "QueryFilters"
engineModeContainer.Size = UDim2.new(0, 240, 0, 36)
engineModeContainer.Position = UDim2.new(1, -354, 0, 12)
engineModeContainer.BackgroundTransparency = 1
engineModeContainer.Parent = topBar

local searchModeLayout = Instance.new("UIListLayout")
searchModeLayout.FillDirection = Enum.FillDirection.Horizontal
searchModeLayout.Padding = UDim.new(0, 4)
searchModeLayout.Parent = engineModeContainer

local windowControls = Instance.new("Frame")
windowControls.Name = "WindowControls"
windowControls.Size = UDim2.fromOffset(90, 36)
windowControls.Position = UDim2.new(1, -98, 0, 12)
windowControls.BackgroundTransparency = 1
windowControls.Parent = topBar

local controlLayout = Instance.new("UIListLayout")
controlLayout.FillDirection = Enum.FillDirection.Horizontal
controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
controlLayout.Padding = UDim.new(0, 4)
controlLayout.Parent = windowControls

local function createSysBtn(text, parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(26, 26)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundTransparency = 0.95
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(180, 180, 190)
    b.AutoButtonColor = false
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke", b)
    bs.Color = Color3.fromRGB(255, 255, 255)
    bs.Transparency = 0.9
    return b
end

local minBtn = createSysBtn("−", windowControls)
local maxBtn = createSysBtn("□", windowControls)
local closeBtn = createSysBtn("×", windowControls)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local scrolling = Instance.new("ScrollingFrame")
scrolling.Name = "AssetScroller"
scrolling.Size = UDim2.new(1, 0, 1, -74)
scrolling.Position = UDim2.fromOffset(0, 64)
scrolling.BackgroundTransparency = 1
scrolling.BorderSizePixel = 0
scrolling.ScrollBarThickness = 4
scrolling.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
scrolling.ScrollBarImageTransparency = 0.85
scrolling.Parent = workSpace

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = scrolling

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrolling.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 20)
end)

do
    local dragging = false 
	local dragStart 
	local startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = mainFrame.Position
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local minimized = false
local maximized = false
local oldSize = mainFrame.Size
local oldPos = mainFrame.Position
local oldAnchor = mainFrame.AnchorPoint

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targets = {scrolling, searchBox, engineModeContainer, sideBar, saveAllBtn}
    for _, t in ipairs(targets) do t.Visible = not minimized end
    if minimized then
        oldSize = mainFrame.Size
        mainFrame.Size = UDim2.fromOffset(mainFrame.AbsoluteSize.X, 60)
    else
        mainFrame.Size = oldSize
    end
end)

maxBtn.MouseButton1Click:Connect(function()
    if maximized then
        mainFrame.AnchorPoint = oldAnchor mainFrame.Size = oldSize mainFrame.Position = oldPos
    else
        oldSize = mainFrame.Size oldPos = mainFrame.Position oldAnchor = mainFrame.AnchorPoint
        mainFrame.AnchorPoint = Vector2.zero mainFrame.Position = UDim2.new(0, 0, 0, 0) mainFrame.Size = UDim2.new(1, 0, 1, 0)
    end
    maximized = not maximized
end)

local searchMode = config.SearchMode or "Name"

local function createModeButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(56, 28)
    b.Text = text:lower()
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(240, 240, 245)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundTransparency = 0.95
    b.AutoButtonColor = false
    b.Parent = engineModeContainer
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local strokeObj = Instance.new("UIStroke", b)
    strokeObj.Color = Color3.fromRGB(255, 255, 255)
    strokeObj.Transparency = 0.9
    return b
end

local nameModeBtn = createModeButton("Name")
local idModeBtn = createModeButton("ID")
local locationModeBtn = createModeButton("Path")
local typeModeBtn = createModeButton("Type")

local function updateModeButtons()
    local btns = {Name = nameModeBtn, ID = idModeBtn, Location = locationModeBtn, Type = typeModeBtn}
    for mode, button in pairs(btns) do
        if searchMode == mode then
            button.BackgroundTransparency = 0.8
            button.UIStroke.Transparency = 0.5
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundTransparency = 0.95
            button.UIStroke.Transparency = 0.9
            button.TextColor3 = Color3.fromRGB(160, 160, 170)
        end
    end
end
updateModeButtons()

local entries = {}
local seenAssets = {}
local categoryCounts = {
    All = 0,
    UI = 0,
    Texture = 0,
    MeshTexture = 0,
    Particles = 0,
    Beam = 0,
    Trail = 0,
    Mesh = 0,
    Surfaces = 0,
    Sky = 0,
    Sound = 0,
    Remotes = 0,
    Video = 0,
    Handles = 0,
    Other = 0
}

local function getCategory(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        return "Remotes"

    elseif obj:IsA("ParticleEmitter") then
        return "Particles"

    elseif obj:IsA("Beam") then
        return "Beam"

    elseif obj:IsA("Trail") then
        return "Trail"

    elseif obj:IsA("MeshPart") or obj:IsA("SpecialMesh") then
        return "Mesh"

    elseif obj:IsA("Sound") then
        return "Sound"

    elseif obj:IsA("SurfaceAppearance") then
        return "MeshTexture"

    elseif obj:IsA("Sky") then
        return "Sky"

    elseif obj:IsA("VideoFrame") then
        return "Video"

    elseif obj:IsA("ImageHandleAdornment") or obj:IsA("Handles") or obj:IsA("ArcHandles") then
        return "Handles"

    elseif obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
        return "UI"

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        return "Texture"

    elseif obj:IsA("SurfaceGui") then
        return "UI"

    else
        return "Other"
    end
end

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "asset scope",
            Text = text,
            Duration = 3
        })
    end)
end

local function updateCategoryTabLabels()
    for _, child in ipairs(filterScroller:GetChildren()) do
        if child:IsA("TextButton") and child.Name:find("CategoryButton_") then
            local rawCat = child.Name:gsub("CategoryButton_", "")
            local totalForCat = categoryCounts[rawCat] or 0
            child.Text = string.format("%s (%d)", rawCat:lower(), totalForCat)
        end
    end
end

local function createEntry(obj, image)
    local isRemote = obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
    local assetId = isRemote and "remote" or extractAssetId(image)
    
    local entryKey = isRemote and obj:GetFullName() or assetId
    if entryKey == "" or seenAssets[entryKey] then return end
    seenAssets[entryKey] = true

    local fullPath = obj:GetFullName()

    local container = Instance.new("Frame")
    container.Name = "AssetCard"
    container.Size = UDim2.new(1, -32, 0, 190)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BackgroundTransparency = 0.97
    container.Parent = scrolling
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    
    local itemStroke = Instance.new("UIStroke", container)
    itemStroke.Color = Color3.fromRGB(255, 255, 255)
    itemStroke.Transparency = 0.94

    local preview = Instance.new("ImageLabel")
    preview.Size = UDim2.fromOffset(80, 80)
    preview.Position = UDim2.fromOffset(15, 15)
    preview.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    preview.BackgroundTransparency = 0.6
    
    if isRemote then
        preview.Image = "rbxasset://textures/Debugger/Breakpoints/disabled_valid.png"
    elseif obj:IsA("Sound") then
        preview.Image = "rbxasset://textures/Volume.png"
    else
        preview.Image = image
    end
    
    preview.Parent = container
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 8)
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -480, 0, 20)
    name.Position = UDim2.fromOffset(110, 14)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.Parent = container

    local function updateCardName()
        local nameText = obj.Name:lower()
        if #nameText > 15 then
            nameText = nameText:sub(1, 15) .. "..."
        end
        name.Text = nameText
    end
    updateCardName()
    obj:GetPropertyChangedSignal("Name"):Connect(updateCardName)

	local typeName = obj.ClassName:lower()

	if obj:IsA("Sky") then
		if image == obj.SkyboxFt then
			typeName = "skyft"
		elseif image == obj.SkyboxBk then
			typeName = "skybk"
		elseif image == obj.SkyboxLf then
			typeName = "skylf"
		elseif image == obj.SkyboxRt then
			typeName = "skyrt"
		elseif image == obj.SkyboxUp then
			typeName = "skyup"
		elseif image == obj.SkyboxDn then
			typeName = "skydn"
		end
	end

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.fromOffset(140, 18)
    typeLabel.Position = UDim2.fromOffset(110, 32)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = "[" .. typeName .. "]"
    typeLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Font = Enum.Font.GothamSemibold
    typeLabel.TextSize = 11
    typeLabel.Parent = container

    local asset = Instance.new("TextBox")
    asset.Size = UDim2.new(1, -440, 0, 24)
    asset.Position = UDim2.fromOffset(110, 56)
    asset.ClearTextOnFocus = false
    asset.TextEditable = false
    asset.Text = isRemote and "[remotepath]" or image
    asset.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    asset.BackgroundTransparency = 0.7
    asset.TextColor3 = Color3.fromRGB(180, 180, 190)
    asset.TextXAlignment = Enum.TextXAlignment.Left
    asset.Font = Enum.Font.Code
    asset.TextSize = 11
    asset.Parent = container
    Instance.new("UICorner", asset).CornerRadius = UDim.new(0, 6)
    local assetPad = Instance.new("UIPadding", asset) assetPad.PaddingLeft = UDim.new(0,8)

    local pathBox = Instance.new("TextBox")
    pathBox.Name = "InstancePathBox"
    pathBox.Size = UDim2.new(1, -126, 0, 54)
    pathBox.Position = UDim2.fromOffset(110, 88)
    pathBox.ClearTextOnFocus = false
    pathBox.TextEditable = false
    pathBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    pathBox.BackgroundTransparency = 0.8
    pathBox.TextColor3 = Color3.fromRGB(130, 150, 180)
    pathBox.TextXAlignment = Enum.TextXAlignment.Left
    pathBox.TextYAlignment = Enum.TextYAlignment.Top
    pathBox.Font = Enum.Font.Code
    pathBox.TextSize = 10
    pathBox.TextWrapped = true
    pathBox.MultiLine = true
    pathBox.Parent = container
    Instance.new("UICorner", pathBox).CornerRadius = UDim.new(0, 6)
    local pathPad = Instance.new("UIPadding", pathBox) 
    pathPad.PaddingLeft = UDim.new(0,8)
    pathPad.PaddingTop = UDim.new(0,6)
    pathPad.PaddingRight = UDim.new(0,8)

	local bottomTray = Instance.new("Frame")
	bottomTray.Name = "BottomTray"
	bottomTray.Size = UDim2.new(0, 220, 0, 26)
	bottomTray.Position = UDim2.fromOffset(110, 146)
	bottomTray.BackgroundTransparency = 1
	bottomTray.Parent = container

	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Padding = UDim.new(0, 5)
	bottomLayout.Parent = bottomTray

    local function updatePathBox()
        pathBox.Text = obj:GetFullName()
    end
    updatePathBox()
    obj:GetPropertyChangedSignal("Name"):Connect(updatePathBox)

    local buttonTray = Instance.new("Frame")
    buttonTray.Name = "ButtonTray"
    buttonTray.Size = UDim2.new(1, -320, 0, 28)
    buttonTray.Position = UDim2.new(0, 305, 0, 14)
    buttonTray.BackgroundTransparency = 1
    buttonTray.Parent = container

    local trayLayout = Instance.new("UIListLayout")
    trayLayout.FillDirection = Enum.FillDirection.Horizontal
    trayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    trayLayout.SortOrder = Enum.SortOrder.LayoutOrder
    trayLayout.Padding = UDim.new(0, 5)
    trayLayout.Parent = buttonTray

    local function createEntryButton(text, layoutOrder, parent)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(85, 28)
		b.Text = text:lower()
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
		b.TextColor3 = Color3.fromRGB(230,230,235)
		b.BackgroundColor3 = Color3.fromRGB(255,255,255)
		b.BackgroundTransparency = 0.95
		b.AutoButtonColor = false
		b.LayoutOrder = layoutOrder
		b.Parent = parent or buttonTray

		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)

		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(255,255,255)
		s.Transparency = 0.9

		return b
	end

    local copyPathBtn = createEntryButton("copy path", 10)
    
    if isRemote then
        local executeBtn = createEntryButton("execute", 1, bottomTray)
        executeBtn.MouseButton1Click:Connect(function()
            if obj:IsA("RemoteEvent") then
                local ok, err = pcall(function() obj:FireServer() end)
                notify(ok and "fired remoteevent!" or "execution error.")
            elseif obj:IsA("RemoteFunction") then
                task.spawn(function()
                    local ok, res = pcall(function() return obj:InvokeServer() end)
                    notify(ok and "fired remotefunction!" or "execution error.")
                end)
            end
        end)
        
        local previewBtn = createEntryButton("preview", 2, bottomTray)
        previewBtn.MouseButton1Click:Connect(function()
            previewImagePopup(preview.Image, obj.Name)
        end)
    else
        local copyIdBtn = createEntryButton("copy id", 8)
        copyIdBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(assetId) notify("id copied!") end
        end)

		local copyNameBtn = createEntryButton("copy name", 5)
		copyNameBtn.MouseButton1Click:Connect(function()
			if setclipboard then
				setclipboard(obj.Name)
				notify("full name copied!")
			end
		end)

        local previewBtn = createEntryButton("preview", 1, bottomTray)
        previewBtn.MouseButton1Click:Connect(function()
            previewImagePopup(preview.Image, obj.Name)
        end)
        
        local saveImgBtn = createEntryButton("save img", 4)
        saveImgBtn.MouseButton1Click:Connect(function()
            local ok, result = saveImageFromAsset(image, nil, obj.Name)
            notify(ok and "stored in workspace!" or "failed to save image...")
        end)
    end

    local isViewableInstance = obj:IsA("PVInstance") or obj:IsA("MeshPart") or obj:IsA("SpecialMesh")
    if isViewableInstance then
        local viewBtn = createEntryButton("view", 2, bottomTray)
        
        local function checkCameraSubject()
            local camera = workspace.CurrentCamera
            if not camera then return end
            
            local targetObj = obj
            if obj:IsA("SpecialMesh") then
                targetObj = obj.Parent
            end
            
            if camera.CameraSubject == targetObj then
                viewBtn.Text = "unview"
            else
                viewBtn.Text = "view"
            end
        end
        
        checkCameraSubject()
        
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            local camera = workspace.CurrentCamera
            if camera then
                camera:GetPropertyChangedSignal("CameraSubject"):Connect(checkCameraSubject)
            end
            checkCameraSubject()
        end)
        
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(checkCameraSubject)
        end
        
        viewBtn.MouseButton1Click:Connect(function()
            local camera = workspace.CurrentCamera
            if not camera then return end
            
            local targetObj = obj
            if obj:IsA("SpecialMesh") then
                targetObj = obj.Parent
            end
            
            if camera.CameraSubject == targetObj then
                local hud = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hud then
                    camera.CameraSubject = hud
                else
                    camera.CameraSubject = player.Character or workspace
                end
            else
                if targetObj and (targetObj:IsA("BasePart") or targetObj:IsA("Model")) then
                    camera.CameraSubject = targetObj
                else
                    notify("instance cannot be focused.")
                end
            end
        end)
    end

    if obj:IsA("Sound") then
        local SoundService = game:GetService("SoundService")
        local playBtn = createEntryButton("play", 1, bottomTray)
        local playing = false
        local currentClone

        playBtn.MouseButton1Click:Connect(function()
            if playing then
                if currentClone then
                    currentClone:Stop()
                    currentClone:Destroy()
                    currentClone = nil
                end
                playBtn.Text = "play"
                playing = false
                return
            end

            local soundToPlay = obj
            if not obj.Parent or obj.SoundId == "" then
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("Sound") and v ~= obj and v.SoundId == obj.SoundId then
                        soundToPlay = v
                        break
                    end
                end
            end

            if not soundToPlay or soundToPlay.SoundId == "" then
                notify("no playable sound found!")
                return
            end

            local oldArchivable = soundToPlay.Archivable
            pcall(function() soundToPlay.Archivable = true end)

            local ok, cloneResult = pcall(function() return soundToPlay:Clone() end)
            currentClone = (ok and cloneResult)

            pcall(function() soundToPlay.Archivable = oldArchivable end)

            if not currentClone then
                local fallbackSound = Instance.new("Sound")
                fallbackSound.SoundId = soundToPlay.SoundId
                fallbackSound.Volume = soundToPlay.Volume or 0.5
                fallbackSound.Pitch = soundToPlay.Pitch or 1
                fallbackSound.PlaybackSpeed = soundToPlay.PlaybackSpeed or 1
                currentClone = fallbackSound
            end

            if currentClone then
                currentClone.Parent = SoundService
                currentClone:Play()

                currentClone.Ended:Connect(function()
                    if currentClone then
                        currentClone:Destroy()
                        currentClone = nil
                    end
                    playing = false
                    playBtn.Text = "play"
                end)

                playBtn.Text = "stop"
                playing = true
            else
                notify("failed to play audio.")
            end
        end)
    end

    copyPathBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(obj:GetFullName()) notify("path copied!") end
    end)

    local category = getCategory(obj)
    
    categoryCounts.All = categoryCounts.All + 1
    if categoryCounts[category] then
        categoryCounts[category] = categoryCounts[category] + 1
    end
    updateCategoryTabLabels()

    local entryData = {
        Name = obj.Name, NameLower = obj.Name:lower(),
        Path = obj:GetFullName(), PathLower = obj:GetFullName():lower(),
        AssetId = tonumber(assetId) or 0,
        Type = obj.ClassName, TypeLower = obj.ClassName:lower(),
        Category = category, CategoryLower = category:lower(),
        Frame = container
    }

    obj:GetPropertyChangedSignal("Name"):Connect(function()
        entryData.Name = obj.Name
        entryData.NameLower = obj.Name:lower()
        entryData.Path = obj:GetFullName()
        entryData.PathLower = obj:GetFullName():lower()
    end)

    table.insert(entries, entryData)
end

local selectedCategories = {}

local function getActiveCategoryName()
    if next(selectedCategories) == nil then
        return "all"
    end

    local count = 0
    local lastCat = ""

    for cat, active in pairs(selectedCategories) do
        if active then
            count += 1
            lastCat = cat
        end
    end

    if count == 0 then
        return "all"
    elseif count == 1 then
        return lastCat:lower()
    else
        return "multi"
    end
end

local function refreshSearch()
    local text = (searchBox and searchBox.Text or ""):lower()
    for _, entry in ipairs(entries) do
        local visible = false
        if text == "" then visible = true
        elseif searchMode == "Name" then visible = entry.NameLower:find(text, 1, true) ~= nil
        elseif searchMode == "ID" then visible = tostring(entry.AssetId):find(text, 1, true) ~= nil
        elseif searchMode == "Location" then visible = entry.PathLower:find(text, 1, true) ~= nil
        elseif searchMode == "Type" then visible = entry.TypeLower:find(text, 1, true) ~= nil
        end
        local categoryMatch

		if next(selectedCategories) == nil then
			categoryMatch = true
		else
			categoryMatch = selectedCategories[entry.Category] == true
		end
        entry.Frame.Visible = visible and categoryMatch
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(refreshSearch)

local function hookMode(btn, mode)
    btn.MouseButton1Click:Connect(function()
        searchMode = mode config = config or {} config.SearchMode = searchMode
        saveConfig(config) updateModeButtons() refreshSearch()
    end)
end
hookMode(nameModeBtn, "Name")
hookMode(idModeBtn, "ID")
hookMode(locationModeBtn, "Location")
hookMode(typeModeBtn, "Type")

local function hookObject(obj)
    pcall(function()
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            obj:GetPropertyChangedSignal("Image"):Connect(function()
                for _, image in ipairs(getImageAsset(obj)) do createEntry(obj, image) end
            end)
        end
    end)
end

game.DescendantAdded:Connect(function(obj)
    hookObject(obj)
    local oldEntryCount = #entries
    for _, image in ipairs(getImageAsset(obj)) do createEntry(obj, image) end
    if #entries > oldEntryCount then
        refreshSearch()
        brandTitle.Text = "asset scope"
    end
end)

task.spawn(function()
    local allObjects = game:GetDescendants()
    local batch = {}
    for _, obj in ipairs(allObjects) do
        hookObject(obj)
        for _, image in ipairs(getImageAsset(obj)) do table.insert(batch, {obj = obj, image = image}) end
    end
    table.sort(batch, function(a, b) return a.obj.Name < b.obj.Name end)
    for _, item in ipairs(batch) do createEntry(item.obj, item.image) end
    refreshSearch()
    brandTitle.Text = "asset scope"
end)

saveAllBtn.MouseButton1Click:Connect(function()
    if savingAll then cancelSaveAll = true return end
    savingAll = true cancelSaveAll = false
    notify("saving...")

    local MarketplaceService = game:GetService("MarketplaceService")
    local gameName = "UnknownGame"
    pcall(function() gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)

    local folderName = IMAGE_FOLDER .. "/" .. sanitize(gameName) .. "_" .. getTimeFolderName()
    pcall(function() makefolder(folderName) end)

    local processed = {} local total = 0
    for _, entry in ipairs(entries) do
        local categoryMatch

		if next(selectedCategories) == nil then
			categoryMatch = true
		else
			categoryMatch = selectedCategories[entry.Category] == true
		end
		
        if categoryMatch then
            local assetId = tostring(entry.AssetId)
            if not processed[assetId] then processed[assetId] = true total += 1 end
        end
    end
    table.clear(processed)

    local saved = 0 local current = 0
    for _, entry in ipairs(entries) do
        if cancelSaveAll then notify("saving cancelled.") break end
        local categoryMatch

		if next(selectedCategories) == nil then
			categoryMatch = true
		else
			categoryMatch = selectedCategories[entry.Category] == true
		end

        if categoryMatch and entry.Category ~= "Remotes" then
            local assetId = tostring(entry.AssetId)
            if not processed[assetId] then
                processed[assetId] = true current += 1
                saveAllBtn.Text = string.format("saving %d/%d", current, total)
                local image = "rbxassetid://" .. assetId
                local ok = saveImageFromAsset(image, folderName, entry.Name)
                if ok then saved += 1 end
            end
        end
        task.wait()
    end

    if not cancelSaveAll then
        saveAllBtn.Text = string.format("saved %d/%d", saved, total)
        notify(string.format("saved %d/%d items successfully!", saved, total))
    end
    task.wait(2) 
    savingAll = false cancelSaveAll = false
    saveAllBtn.Text = "save " .. getActiveCategoryName()
end)

local categories = {
    "All",
    "UI",
    "Texture",
    "MeshTexture",
    "Particles",
    "Beam",
    "Trail",
    "Mesh",
    "Surfaces",
    "Sky",
    "Sound",
    "Remotes",
    "Video",
    "Handles"
}

for _, cat in ipairs(categories) do
    local btn = Instance.new("TextButton")
    btn.Name = "CategoryButton_" .. cat
    btn.Size = UDim2.new(1, -24, 0, 32)
    btn.Text = cat:lower() .. " (0)"
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = cat == "All" and 0.9 or 0.98
    btn.TextColor3 = cat == "All" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = filterScroller
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Transparency = cat == "All" and 0.8 or 0.95

    btn.MouseButton1Click:Connect(function()
		if cat == "All" then
			selectedCategories = {}
		else
			selectedCategories["All"] = nil
			if selectedCategories[cat] then
				selectedCategories[cat] = nil
			else
				selectedCategories[cat] = true
			end
		end

		refreshSearch()

        if not savingAll then
            saveAllBtn.Text = "save " .. getActiveCategoryName()
        end

        for _, child in ipairs(filterScroller:GetChildren()) do
            if child:IsA("TextButton") then
                local rawCat = child.Name:gsub("CategoryButton_", "")
                local active = rawCat == "All" and (next(selectedCategories) == nil) or (selectedCategories[rawCat] == true)
                child.BackgroundTransparency = active and 0.9 or 0.98
                child.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
                child.UIStroke.Transparency = active and 0.8 or 0.95
            end
        end
    end)
end

updateCategoryTabLabels()