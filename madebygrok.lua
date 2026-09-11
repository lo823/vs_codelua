--[[
	VS Code Lua - Full IDE UI
	Single-file LocalScript
	Dark theme | Touch + Mouse | Real GUI
	Icons: verified Lucide rbxassetid only
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ====================== ICONS (verified Lucide) ======================
local Icons = {
	Explorer     = "rbxassetid://10723387563", -- folder
	Search       = "rbxassetid://10734943674",
	SourceControl= "rbxassetid://10723396676", -- git-branch
	RunDebug     = "rbxassetid://10734923549", -- play
	Extensions   = "rbxassetid://10734930886", -- puzzle
	Settings     = "rbxassetid://10734950309",
	Terminal     = "rbxassetid://10734982144",
	Problems     = "rbxassetid://10709782845", -- bug
	File         = "rbxassetid://10723374641",
	FolderOpen   = "rbxassetid://10723386277",
	Close        = "rbxassetid://10747384394", -- x
	Minimize     = "rbxassetid://10734896206", -- minus
	Maximize     = "rbxassetid://10709811261", -- columns (approx)
	ChevronRight = "rbxassetid://10709791437",
	ChevronDown  = "rbxassetid://10709790948",
	Plus         = "rbxassetid://10734924532",
	Command      = "rbxassetid://10709811365",
	Book         = "rbxassetid://10709781824",
	Bell         = "rbxassetid://10709775704",
	Code         = "rbxassetid://10709810463",
}

-- ====================== THEME ======================
local Theme = {
	BgDark       = Color3.fromRGB(30, 30, 30),
	BgSide       = Color3.fromRGB(37, 37, 38),
	BgActivity   = Color3.fromRGB(51, 51, 51),
	BgEditor     = Color3.fromRGB(30, 30, 30),
	BgTab        = Color3.fromRGB(45, 45, 45),
	BgTabActive  = Color3.fromRGB(30, 30, 30),
	BgStatus     = Color3.fromRGB(0, 122, 204),
	BgPanel      = Color3.fromRGB(37, 37, 38),
	BgInput      = Color3.fromRGB(60, 60, 60),
	Border       = Color3.fromRGB(60, 60, 60),
	Text         = Color3.fromRGB(212, 212, 212),
	TextDim      = Color3.fromRGB(150, 150, 150),
	Accent       = Color3.fromRGB(0, 122, 204),
	Hover        = Color3.fromRGB(70, 70, 70),
	Danger       = Color3.fromRGB(244, 71, 71),
	Success      = Color3.fromRGB(78, 201, 176),
}

-- ====================== STATE ======================
local State = {
	ActiveView = "Explorer",
	SideVisible = true,
	BottomVisible = true,
	BottomHeight = 180,
	SideWidth = 280,
	IsMaximized = false,
	WindowPos = UDim2.new(0.05, 0, 0.05, 0),
	WindowSize = UDim2.new(0.9, 0, 0.9, 0),
	SavedPos = nil,
	SavedSize = nil,
	OpenTabs = {"main.luau", "config.luau"},
	ActiveTab = 1,
	Notifications = {},
}

-- ====================== ROOT ======================
local screen = Instance.new("ScreenGui")
screen.Name = "VSCodeLua"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
screen.DisplayOrder = 50
screen.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "MainWindow"
main.Size = State.WindowSize
main.Position = State.WindowPos
main.BackgroundColor3 = Theme.BgDark
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Theme.Border
stroke.Thickness = 1
stroke.Parent = main

-- ====================== TITLE BAR ======================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Theme.BgActivity
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VS Code Lua"
titleLabel.TextColor3 = Theme.Text
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Window controls
local function createWinBtn(name, icon, xOffset, callback)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 36, 0, 32)
	btn.Position = UDim2.new(1, xOffset, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Image = icon
	btn.ImageColor3 = Theme.TextDim
	btn.ScaleType = Enum.ScaleType.Fit
	btn.Parent = titleBar

	btn.MouseEnter:Connect(function()
		btn.BackgroundTransparency = 0
		btn.BackgroundColor3 = name == "Close" and Theme.Danger or Theme.Hover
		btn.ImageColor3 = Color3.new(1,1,1)
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 1
		btn.ImageColor3 = Theme.TextDim
	end)
	btn.Activated:Connect(callback)
	return btn
end

createWinBtn("Minimize", Icons.Minimize, -108, function()
	main.Visible = false
	-- could show a taskbar icon here
end)

createWinBtn("Maximize", Icons.Maximize, -72, function()
	if State.IsMaximized then
		main.Size = State.SavedSize or UDim2.new(0.9,0,0.9,0)
		main.Position = State.SavedPos or UDim2.new(0.05,0,0.05,0)
		State.IsMaximized = false
	else
		State.SavedSize = main.Size
		State.SavedPos = main.Position
		main.Size = UDim2.new(1,0,1,0)
		main.Position = UDim2.new(0,0,0,0)
		State.IsMaximized = true
	end
end)

createWinBtn("Close", Icons.Close, -36, function()
	screen:Destroy()
end)

-- Drag title bar
local dragging = false
local dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ====================== ACTIVITY BAR ======================
local activityBar = Instance.new("Frame")
activityBar.Name = "ActivityBar"
activityBar.Size = UDim2.new(0, 48, 1, -32)
activityBar.Position = UDim2.new(0, 0, 0, 32)
activityBar.BackgroundColor3 = Theme.BgActivity
activityBar.BorderSizePixel = 0
activityBar.Parent = main

local activityList = {
	{id = "Explorer", icon = Icons.Explorer},
	{id = "Search", icon = Icons.Search},
	{id = "SourceControl", icon = Icons.SourceControl},
	{id = "RunDebug", icon = Icons.RunDebug},
	{id = "Extensions", icon = Icons.Extensions},
}

local activityButtons = {}
for i, item in ipairs(activityList) do
	local btn = Instance.new("ImageButton")
	btn.Name = item.id
	btn.Size = UDim2.new(0, 48, 0, 48)
	btn.Position = UDim2.new(0, 0, 0, (i-1)*48)
	btn.BackgroundTransparency = 1
	btn.Image = item.icon
	btn.ImageColor3 = Theme.TextDim
	btn.ScaleType = Enum.ScaleType.Fit
	btn.Parent = activityBar

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 3, 0, 24)
	indicator.Position = UDim2.new(0, 0, 0.5, -12)
	indicator.BackgroundColor3 = Theme.Accent
	indicator.BorderSizePixel = 0
	indicator.Visible = (item.id == State.ActiveView)
	indicator.Parent = btn

	btn.MouseEnter:Connect(function()
		if State.ActiveView \~= item.id then
			btn.ImageColor3 = Theme.Text
		end
	end)
	btn.MouseLeave:Connect(function()
		if State.ActiveView \~= item.id then
			btn.ImageColor3 = Theme.TextDim
		end
	end)

	activityButtons[item.id] = {btn = btn, indicator = indicator}
end

-- Settings & Wiki at bottom of activity
local settingsBtn = Instance.new("ImageButton")
settingsBtn.Name = "Settings"
settingsBtn.Size = UDim2.new(0, 48, 0, 48)
settingsBtn.Position = UDim2.new(0, 0, 1, -96)
settingsBtn.BackgroundTransparency = 1
settingsBtn.Image = Icons.Settings
settingsBtn.ImageColor3 = Theme.TextDim
settingsBtn.ScaleType = Enum.ScaleType.Fit
settingsBtn.Parent = activityBar

local wikiBtn = Instance.new("ImageButton")
wikiBtn.Name = "Wiki"
wikiBtn.Size = UDim2.new(0, 48, 0, 48)
wikiBtn.Position = UDim2.new(0, 0, 1, -48)
wikiBtn.BackgroundTransparency = 1
wikiBtn.Image = Icons.Book
wikiBtn.ImageColor3 = Theme.TextDim
wikiBtn.ScaleType = Enum.ScaleType.Fit
wikiBtn.Parent = activityBar

-- ====================== SIDE BAR ======================
local sideBar = Instance.new("Frame")
sideBar.Name = "SideBar"
sideBar.Size = UDim2.new(0, State.SideWidth, 1, -32)
sideBar.Position = UDim2.new(0, 48, 0, 32)
sideBar.BackgroundColor3 = Theme.BgSide
sideBar.BorderSizePixel = 0
sideBar.ClipsDescendants = true
sideBar.Parent = main

local sideHeader = Instance.new("TextLabel")
sideHeader.Size = UDim2.new(1, -16, 0, 28)
sideHeader.Position = UDim2.new(0, 12, 0, 4)
sideHeader.BackgroundTransparency = 1
sideHeader.Text = "EXPLORER"
sideHeader.TextColor3 = Theme.TextDim
sideHeader.TextSize = 11
sideHeader.Font = Enum.Font.GothamBold
sideHeader.TextXAlignment = Enum.TextXAlignment.Left
sideHeader.Parent = sideBar

local sideContent = Instance.new("ScrollingFrame")
sideContent.Name = "Content"
sideContent.Size = UDim2.new(1, 0, 1, -36)
sideContent.Position = UDim2.new(0, 0, 0, 36)
sideContent.BackgroundTransparency = 1
sideContent.BorderSizePixel = 0
sideContent.ScrollBarThickness = 4
sideContent.ScrollBarImageColor3 = Theme.Border
sideContent.CanvasSize = UDim2.new(0, 0, 0, 0)
sideContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
sideContent.Parent = sideBar

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 2)
sideLayout.Parent = sideContent

-- Demo Explorer items
local function addExplorerItem(name, isFolder, depth)
	local item = Instance.new("TextButton")
	item.Size = UDim2.new(1, -8, 0, 24)
	item.BackgroundTransparency = 1
	item.Text = ""
	item.AutoButtonColor = false
	item.Parent = sideContent

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8 + depth * 16)
	pad.Parent = item

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 16, 0, 16)
	icon.Position = UDim2.new(0, 0, 0.5, -8)
	icon.BackgroundTransparency = 1
	icon.Image = isFolder and Icons.FolderOpen or Icons.File
	icon.ImageColor3 = Theme.TextDim
	icon.Parent = item

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 1, 0)
	label.Position = UDim2.new(0, 22, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Theme.Text
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = item

	item.MouseEnter:Connect(function()
		item.BackgroundTransparency = 0
		item.BackgroundColor3 = Theme.Hover
	end)
	item.MouseLeave:Connect(function()
		item.BackgroundTransparency = 1
	end)
end

addExplorerItem("src", true, 0)
addExplorerItem("main.luau", false, 1)
addExplorerItem("modules", true, 1)
addExplorerItem("Editor.lua", false, 2)
addExplorerItem("Core.lua", false, 2)
addExplorerItem("config.luau", false, 0)

-- ====================== EDITOR AREA ======================
local editorArea = Instance.new("Frame")
editorArea.Name = "EditorArea"
editorArea.Size = UDim2.new(1, -(48 + State.SideWidth), 1, -(32 + 22 + State.BottomHeight))
editorArea.Position = UDim2.new(0, 48 + State.SideWidth, 0, 32)
editorArea.BackgroundColor3 = Theme.BgEditor
editorArea.BorderSizePixel = 0
editorArea.Parent = main

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 35)
tabBar.BackgroundColor3 = Theme.BgTab
tabBar.BorderSizePixel = 0
tabBar.Parent = editorArea

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 1)
tabLayout.Parent = tabBar

local function createTab(name, index)
	local tab = Instance.new("TextButton")
	tab.Name = "Tab_" .. name
	tab.Size = UDim2.new(0, 140, 1, 0)
	tab.BackgroundColor3 = (index == State.ActiveTab) and Theme.BgTabActive or Theme.BgTab
	tab.BorderSizePixel = 0
	tab.Text = ""
	tab.AutoButtonColor = false
	tab.Parent = tabBar

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -28, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Theme.Text
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = tab

	local close = Instance.new("ImageButton")
	close.Size = UDim2.new(0, 16, 0, 16)
	close.Position = UDim2.new(1, -22, 0.5, -8)
	close.BackgroundTransparency = 1
	close.Image = Icons.Close
	close.ImageColor3 = Theme.TextDim
	close.ScaleType = Enum.ScaleType.Fit
	close.Parent = tab

	tab.Activated:Connect(function()
		State.ActiveTab = index
		-- refresh tab colors would go here
	end)
end

for i, name in ipairs(State.OpenTabs) do
	createTab(name, i)
end

-- Breadcrumb
local breadcrumb = Instance.new("Frame")
breadcrumb.Name = "Breadcrumb"
breadcrumb.Size = UDim2.new(1, 0, 0, 22)
breadcrumb.Position = UDim2.new(0, 0, 0, 35)
breadcrumb.BackgroundColor3 = Theme.BgEditor
breadcrumb.BorderSizePixel = 0
breadcrumb.Parent = editorArea

local breadLabel = Instance.new("TextLabel")
breadLabel.Size = UDim2.new(1, -12, 1, 0)
breadLabel.Position = UDim2.new(0, 12, 0, 0)
breadLabel.BackgroundTransparency = 1
breadLabel.Text = "src  >  main.luau"
breadLabel.TextColor3 = Theme.TextDim
breadLabel.TextSize = 12
breadLabel.Font = Enum.Font.Gotham
breadLabel.TextXAlignment = Enum.TextXAlignment.Left
breadLabel.Parent = breadcrumb

-- Editor surface (demo TextBox)
local editorSurface = Instance.new("ScrollingFrame")
editorSurface.Name = "EditorSurface"
editorSurface.Size = UDim2.new(1, 0, 1, -57)
editorSurface.Position = UDim2.new(0, 0, 0, 57)
editorSurface.BackgroundColor3 = Theme.BgEditor
editorSurface.BorderSizePixel = 0
editorSurface.ScrollBarThickness = 6
editorSurface.ScrollBarImageColor3 = Theme.Border
editorSurface.CanvasSize = UDim2.new(0, 0, 0, 800)
editorSurface.Parent = editorArea

local lineNumbers = Instance.new("TextLabel")
lineNumbers.Size = UDim2.new(0, 40, 0, 800)
lineNumbers.BackgroundColor3 = Theme.BgSide
lineNumbers.BorderSizePixel = 0
lineNumbers.Text = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15"
lineNumbers.TextColor3 = Theme.TextDim
lineNumbers.TextSize = 13
lineNumbers.Font = Enum.Font.Code
lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
lineNumbers.Parent = editorSurface

local codeBox = Instance.new("TextBox")
codeBox.Name = "CodeEditor"
codeBox.Size = UDim2.new(1, -50, 0, 800)
codeBox.Position = UDim2.new(0, 50, 0, 0)
codeBox.BackgroundTransparency = 1
codeBox.Text = "-- VS Code Lua Editor\n-- Connect your Editor Module here\n\nlocal Core = require(script.Parent.Core)\n\nfunction main()\n    print(\"Hello from VS Code Lua\")\nend\n\nmain()"
codeBox.TextColor3 = Theme.Text
codeBox.TextSize = 14
codeBox.Font = Enum.Font.Code
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.MultiLine = true
codeBox.ClearTextOnFocus = false
codeBox.TextWrapped = false
codeBox.Parent = editorSurface

-- ====================== BOTTOM PANEL ======================
local bottomPanel = Instance.new("Frame")
bottomPanel.Name = "BottomPanel"
bottomPanel.Size = UDim2.new(1, -(48 + State.SideWidth), 0, State.BottomHeight)
bottomPanel.Position = UDim2.new(0, 48 + State.SideWidth, 1, -22 - State.BottomHeight)
bottomPanel.BackgroundColor3 = Theme.BgPanel
bottomPanel.BorderSizePixel = 0
bottomPanel.Parent = main

local bottomTabs = Instance.new("Frame")
bottomTabs.Size = UDim2.new(1, 0, 0, 28)
bottomTabs.BackgroundColor3 = Theme.BgSide
bottomTabs.BorderSizePixel = 0
bottomTabs.Parent = bottomPanel

local termTab = Instance.new("TextButton")
termTab.Size = UDim2.new(0, 100, 1, 0)
termTab.BackgroundTransparency = 1
termTab.Text = "  TERMINAL"
termTab.TextColor3 = Theme.Text
termTab.TextSize = 12
termTab.Font = Enum.Font.GothamMedium
termTab.TextXAlignment = Enum.TextXAlignment.Left
termTab.Parent = bottomTabs

local problemsTab = Instance.new("TextButton")
problemsTab.Size = UDim2.new(0, 100, 1, 0)
problemsTab.Position = UDim2.new(0, 100, 0, 0)
problemsTab.BackgroundTransparency = 1
problemsTab.Text = "  PROBLEMS"
problemsTab.TextColor3 = Theme.TextDim
problemsTab.TextSize = 12
problemsTab.Font = Enum.Font.GothamMedium
problemsTab.TextXAlignment = Enum.TextXAlignment.Left
problemsTab.Parent = bottomTabs

local terminalOut = Instance.new("ScrollingFrame")
terminalOut.Size = UDim2.new(1, 0, 1, -28)
terminalOut.Position = UDim2.new(0, 0, 0, 28)
terminalOut.BackgroundTransparency = 1
terminalOut.BorderSizePixel = 0
terminalOut.ScrollBarThickness = 4
terminalOut.Parent = bottomPanel

local termText = Instance.new("TextLabel")
termText.Size = UDim2.new(1, -12, 0, 200)
termText.Position = UDim2.new(0, 8, 0, 4)
termText.BackgroundTransparency = 1
termText.Text = "> Ready\n> Sandbox environment loaded\n> Type commands here (connect to your Core Module)"
termText.TextColor3 = Theme.Success
termText.TextSize = 13
termText.Font = Enum.Font.Code
termText.TextXAlignment = Enum.TextXAlignment.Left
termText.TextYAlignment = Enum.TextYAlignment.Top
termText.Parent = terminalOut

-- ====================== STATUS BAR ======================
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, 0, 0, 22)
statusBar.Position = UDim2.new(0, 0, 1, -22)
statusBar.BackgroundColor3 = Theme.BgStatus
statusBar.BorderSizePixel = 0
statusBar.Parent = main

local statusLeft = Instance.new("TextLabel")
statusLeft.Size = UDim2.new(0.5, 0, 1, 0)
statusLeft.Position = UDim2.new(0, 10, 0, 0)
statusLeft.BackgroundTransparency = 1
statusLeft.Text = "main  |  Luau  |  UTF-8"
statusLeft.TextColor3 = Color3.new(1,1,1)
statusLeft.TextSize = 12
statusLeft.Font = Enum.Font.Gotham
statusLeft.TextXAlignment = Enum.TextXAlignment.Left
statusLeft.Parent = statusBar

local statusRight = Instance.new("TextLabel")
statusRight.Size = UDim2.new(0.5, -10, 1, 0)
statusRight.Position = UDim2.new(0.5, 0, 0, 0)
statusRight.BackgroundTransparency = 1
statusRight.Text = "Ln 1, Col 1  |  Spaces: 4  |  Ready"
statusRight.TextColor3 = Color3.new(1,1,1)
statusRight.TextSize = 12
statusRight.Font = Enum.Font.Gotham
statusRight.TextXAlignment = Enum.TextXAlignment.Right
statusRight.Parent = statusBar

-- ====================== COMMAND PALETTE ======================
local cmdOverlay = Instance.new("Frame")
cmdOverlay.Name = "CommandPalette"
cmdOverlay.Size = UDim2.new(1, 0, 1, 0)
cmdOverlay.BackgroundColor3 = Color3.new(0,0,0)
cmdOverlay.BackgroundTransparency = 0.5
cmdOverlay.Visible = false
cmdOverlay.ZIndex = 100
cmdOverlay.Parent = main

local cmdBox = Instance.new("Frame")
cmdBox.Size = UDim2.new(0, 520, 0, 320)
cmdBox.Position = UDim2.new(0.5, -260, 0.15, 0)
cmdBox.BackgroundColor3 = Theme.BgSide
cmdBox.BorderSizePixel = 0
cmdBox.ZIndex = 101
cmdBox.Parent = cmdOverlay

local cmdCorner = Instance.new("UICorner")
cmdCorner.CornerRadius = UDim.new(0, 8)
cmdCorner.Parent = cmdBox

local cmdInput = Instance.new("TextBox")
cmdInput.Size = UDim2.new(1, -24, 0, 36)
cmdInput.Position = UDim2.new(0, 12, 0, 12)
cmdInput.BackgroundColor3 = Theme.BgInput
cmdInput.BorderSizePixel = 0
cmdInput.Text = ""
cmdInput.PlaceholderText = "Type a command..."
cmdInput.TextColor3 = Theme.Text
cmdInput.PlaceholderColor3 = Theme.TextDim
cmdInput.TextSize = 15
cmdInput.Font = Enum.Font.Gotham
cmdInput.ClearTextOnFocus = false
cmdInput.ZIndex = 102
cmdInput.Parent = cmdBox

local cmdInputCorner = Instance.new("UICorner")
cmdInputCorner.CornerRadius = UDim.new(0, 4)
cmdInputCorner.Parent = cmdInput

-- ====================== NOTIFICATION ======================
local notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0, 320, 1, -40)
notifContainer.Position = UDim2.new(1, -340, 0, 20)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 200
notifContainer.Parent = main

local function notify(title, message, duration)
	duration = duration or 4
	local n = Instance.new("Frame")
	n.Size = UDim2.new(1, 0, 0, 64)
	n.BackgroundColor3 = Theme.BgSide
	n.BorderSizePixel = 0
	n.ZIndex = 201
	n.Parent = notifContainer

	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent = n

	local ns = Instance.new("UIStroke")
	ns.Color = Theme.Accent
	ns.Thickness = 1
	ns.Parent = n

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -16, 0, 22)
	t.Position = UDim2.new(0, 12, 0, 8)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = Theme.Text
	t.TextSize = 14
	t.Font = Enum.Font.GothamBold
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 202
	t.Parent = n

	local m = Instance.new("TextLabel")
	m.Size = UDim2.new(1, -16, 0, 28)
	m.Position = UDim2.new(0, 12, 0, 30)
	m.BackgroundTransparency = 1
	m.Text = message
	m.TextColor3 = Theme.TextDim
	m.TextSize = 12
	m.Font = Enum.Font.Gotham
	m.TextXAlignment = Enum.TextXAlignment.Left
	m.TextWrapped = true
	m.ZIndex = 202
	m.Parent = n

	task.delay(duration, function()
		if n and n.Parent then
			n:Destroy()
		end
	end)
end

-- ====================== VIEW SWITCHING ======================
local function setActiveView(id)
	State.ActiveView = id
	for vid, data in pairs(activityButtons) do
		data.indicator.Visible = (vid == id)
		data.btn.ImageColor3 = (vid == id) and Theme.Text or Theme.TextDim
	end
	sideHeader.Text = string.upper(id)
	-- clear and rebuild sideContent based on view (demo keeps explorer)
end

for id, data in pairs(activityButtons) do
	data.btn.Activated:Connect(function()
		setActiveView(id)
		if id == "RunDebug" then
			-- Safe sandbox call only
			notify("Run", "Executing in allowed sandbox...", 3)
			-- Hook point: VSCodeLua.API.RunSandbox(code)
		end
	end)
end

settingsBtn.Activated:Connect(function()
	notify("Settings", "Settings panel opened (connect your Settings Module)", 3)
end)

wikiBtn.Activated:Connect(function()
	notify("Wiki", "Wiki panel opened", 3)
end)

-- ====================== KEYBOARD ======================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		cmdOverlay.Visible = not cmdOverlay.Visible
		if cmdOverlay.Visible then
			cmdInput:CaptureFocus()
		end
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		cmdOverlay.Visible = false
	end
end)

-- ====================== RESIZE HANDLES (simple) ======================
-- Side resize
local sideResize = Instance.new("Frame")
sideResize.Size = UDim2.new(0, 4, 1, -32)
sideResize.Position = UDim2.new(0, 48 + State.SideWidth - 2, 0, 32)
sideResize.BackgroundTransparency = 1
sideResize.Parent = main

local resizingSide = false
sideResize.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizingSide = true
	end
end)
sideResize.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizingSide = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizingSide and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local rel = input.Position.X - main.AbsolutePosition.X - 48
		State.SideWidth = math.clamp(rel, 180, 420)
		sideBar.Size = UDim2.new(0, State.SideWidth, 1, -32)
		editorArea.Size = UDim2.new(1, -(48 + State.SideWidth), 1, -(32 + 22 + State.BottomHeight))
		editorArea.Position = UDim2.new(0, 48 + State.SideWidth, 0, 32)
		bottomPanel.Size = UDim2.new(1, -(48 + State.SideWidth), 0, State.BottomHeight)
		bottomPanel.Position = UDim2.new(0, 48 + State.SideWidth, 1, -22 - State.BottomHeight)
		sideResize.Position = UDim2.new(0, 48 + State.SideWidth - 2, 0, 32)
	end
end)

-- ====================== PUBLIC API (for Editor / Core modules) ======================
local VSCodeLua = {
	API = {
		Notify = notify,
		SetStatus = function(text)
			statusRight.Text = text
		end,
		GetCode = function()
			return codeBox.Text
		end,
		SetCode = function(text)
			codeBox.Text = text
		end,
		RunSandbox = function(code)
			-- ONLY allowed sandbox entry point
			-- Implement your safe sandbox here or require a Core module
			notify("Sandbox", "Code received by allowed sandbox", 2)
			return true
		end,
		OpenCommandPalette = function()
			cmdOverlay.Visible = true
			cmdInput:CaptureFocus()
		end,
	}
}

-- Expose globally for other modules
_G.VSCodeLua = VSCodeLua

-- Initial notification
task.defer(function()
	notify("VS Code Lua", "IDE ready. Ctrl+P for Command Palette", 5)
end)

print("[VS Code Lua] UI loaded successfully")