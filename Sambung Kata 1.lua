-- =========================================================
-- 🌟 RAMKUN - ULTRA COMPACT & OMNISCIENT AI 🌟
-- [Mini Glass UI | 2-Column Grid | Dynamic Learning]
-- by moonmango
-- =========================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- 🧠 STATE & CONFIGURATION
-- =========================================================
local Config = { TypingDelayMS = 150, AutoPlay = false, Humanize = true, Playstyle = "Easy Win" }
local State = {
    MatchActive = false, IsMyTurn = false, ServerLetter = "",
    UsedWords = {}, TriedThisTurn = {}, PermanentBlacklist = {}, VerifiedWords = {},
    TurnID = 0, IsTyping = false, HasSubmitted = false, BotExecuting = false, 
    ValidationResult = nil, LastSubmittedWord = ""
}

local Playstyles = {"Easy Win", "Combo", "Longest", "Shortest", "Normal"}
local currentStyleIndex = 1

-- 🌳 TRIE DATA STRUCTURE & GLOBAL MEMORY
local Dictionary = {} 
local TrieRoot = { children = {}, wordPointers = {} }
local WordsStartingWith = {} 
local KnownWords = {} 
local totalWords = 0

local sbyte, lower, sub, random = string.byte, string.lower, string.sub, math.random

local KeyboardAdjacent = {
    a="sz", b="n", c="v", d="xc", e="df", f="rv", g="tb", h="bn",
    i="uo", j="uin", k="ij", l="ok", m="k", n="m", o="lk", p="ol", q="wa",
    r="ef", s="az", t="g", u="yj", v="gb", w="qs", x="zc", y="g", z="a"
}

-- =========================================================
-- 💾 BATCH I/O MANAGER
-- =========================================================
local WriteQueue = { blacklist = {}, verified = {}, cache = {} }
local function ensureFolder() if isfolder and not isfolder("WORD") then pcall(makefolder, "WORD") end end

local function queueWrite(type, word) table.insert(WriteQueue[type], word) end

local function flushWriteQueue()
    ensureFolder()
    for fileType, queue in pairs(WriteQueue) do
        if #queue > 0 then
            local data = table.concat(queue, "\n") .. "\n"
            local filename = fileType == "cache" and "master_cache.txt" or (fileType .. ".txt")
            if appendfile then pcall(function() appendfile("WORD/" .. filename, data) end)
            elseif writefile and readfile then
                pcall(function()
                    local existing = isfile and isfile("WORD/" .. filename) and readfile("WORD/" .. filename) or ""
                    writefile("WORD/" .. filename, existing .. data)
                end)
            end
            table.clear(queue)
        end
    end
end

task.spawn(function() while true do task.wait(2); flushWriteQueue() end end)

-- =========================================================
-- 🌳 DYNAMIC WORD PROCESSOR
-- =========================================================
local function insertToTrie(word, index)
    local node = TrieRoot
    for i = 1, #word do
        local char = sub(word, i, i)
        if not node.children[char] then node.children[char] = { children = {}, wordPointers = {} } end
        node = node.children[char]
        table.insert(node.wordPointers, index)
    end
end

local function getFromTrie(prefix)
    local node = TrieRoot
    for i = 1, #prefix do
        local char = sub(prefix, i, i)
        if not node.children[char] then return {} end
        node = node.children[char]
    end
    return node.wordPointers
end

local function processWord(word, isNewFromWeb, isVerified)
    local lw = lower(word)
    if #lw >= 2 and #lw <= 40 and not KnownWords[lw] and not State.PermanentBlacklist[lw] then
        KnownWords[lw] = true; totalWords = totalWords + 1; Dictionary[totalWords] = lw  
        insertToTrie(lw, totalWords)
        local s2 = sub(lw, 1, 2); WordsStartingWith[s2] = (WordsStartingWith[s2] or 0) + 1
        local s3 = sub(lw, 1, 3); WordsStartingWith[s3] = (WordsStartingWith[s3] or 0) + 1
        if isNewFromWeb then queueWrite("cache", lw) end
        if isVerified then State.VerifiedWords[lw] = true; queueWrite("verified", lw) end
    end
end

-- =========================================================
-- 🛡️ SMART VALIDATION
-- =========================================================
if remotes:FindFirstChild("PlayerHit") then
    remotes.PlayerHit.OnClientEvent:Connect(function(target)
        local isMe = false
        if typeof(target) == "Instance" and target == LocalPlayer then isMe = true end
        if type(target) == "string" and target == LocalPlayer.Name then isMe = true end
        if isMe and State.IsTyping and State.HasSubmitted then State.ValidationResult = "INVALID" end
    end)
end

if remotes:FindFirstChild("PlayerCorrect") then
    remotes.PlayerCorrect.OnClientEvent:Connect(function()
        if State.LastSubmittedWord ~= "" then
            local lw = lower(State.LastSubmittedWord)
            if not State.VerifiedWords[lw] then
                State.VerifiedWords[lw] = true; queueWrite("verified", lw)
                if not KnownWords[lw] then processWord(lw, false, true) end
            end
            State.ValidationResult = "SUCCESS"
        end
    end)
end

-- =========================================================
-- 🎨 GUI V15 (ULTRA COMPACT -25% SIZE)
-- =========================================================
local uiName = "AutoType_V15_UltraCompact"
local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild(uiName) then parentGui[uiName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = uiName; ScreenGui.ResetOnSpawn = false; ScreenGui.Parent = parentGui

-- [DIKECILKAN] Main Frame: 220x260 (Sangat mungil)
local MainFrame = Instance.new("Frame"); MainFrame.Size = UDim2.new(0, 220, 0, 260); MainFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); MainFrame.BackgroundTransparency = 0.25 
MainFrame.BorderSizePixel = 0; MainFrame.ClipsDescendants = true; MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke", MainFrame); UIStroke.Color = Color3.fromRGB(100, 150, 250); UIStroke.Transparency = 0.5; UIStroke.Thickness = 1.2

-- Top Bar (Tinggi dikurangi jadi 30)
local TopBar = Instance.new("Frame"); TopBar.Size = UDim2.new(1, 0, 0, 30); TopBar.BackgroundTransparency = 1; TopBar.Active = true; TopBar.Parent = MainFrame
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Size = UDim2.new(0, 100, 1, 0); TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "RAMA V1"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.Font = Enum.Font.GothamBlack; TitleLabel.TextSize = 10; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.Parent = TopBar

-- Tombol Settings (Gear)
local SettingsBtn = Instance.new("TextButton"); SettingsBtn.Size = UDim2.new(0, 25, 0, 30); SettingsBtn.Position = UDim2.new(1, -75, 0, 0)
SettingsBtn.BackgroundTransparency = 1; SettingsBtn.Text = "⚙️"; SettingsBtn.TextColor3 = Color3.fromRGB(200, 200, 200); SettingsBtn.Font = Enum.Font.GothamBold; SettingsBtn.TextSize = 12; SettingsBtn.ZIndex = 2; SettingsBtn.Parent = TopBar

local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 25, 0, 30); MinBtn.Position = UDim2.new(1, -50, 0, 0)
MinBtn.BackgroundTransparency = 1; MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 12; MinBtn.ZIndex = 2; MinBtn.Parent = TopBar
local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 25, 0, 30); CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "✕"; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 12; CloseBtn.ZIndex = 2; CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Status Label
local StatusLabel = Instance.new("TextLabel"); StatusLabel.Size = UDim2.new(1, -16, 0, 18); StatusLabel.Position = UDim2.new(0, 8, 0, 30)
StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "⏳ Memuat Database..."; StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255); StatusLabel.Font = Enum.Font.GothamSemibold; StatusLabel.TextSize = 10; StatusLabel.TextXAlignment = Enum.TextXAlignment.Left; StatusLabel.Parent = MainFrame

-- Scroll Frame untuk Kata (Grid lebih padat)
local ScrollFrame = Instance.new("ScrollingFrame"); ScrollFrame.Size = UDim2.new(1, -12, 1, -55); ScrollFrame.Position = UDim2.new(0, 6, 0, 50)
ScrollFrame.BackgroundTransparency = 1; ScrollFrame.ScrollBarThickness = 2; ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 250); ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0); ScrollFrame.Parent = MainFrame
local GridLayout = Instance.new("UIGridLayout"); GridLayout.CellSize = UDim2.new(0.48, 0, 0, 22); GridLayout.CellPadding = UDim2.new(0.03, 0, 0, 4); GridLayout.SortOrder = Enum.SortOrder.LayoutOrder; GridLayout.Parent = ScrollFrame
GridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 5) end)

-- =========================================================
-- ⚙️ SETTINGS PANEL (OVERLAY TERSEMBUNYI)
-- =========================================================
local SettingsPanel = Instance.new("Frame"); SettingsPanel.Size = UDim2.new(1, 0, 1, -30); SettingsPanel.Position = UDim2.new(0, 0, 1, 0)
SettingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25); SettingsPanel.BackgroundTransparency = 0.1; SettingsPanel.BorderSizePixel = 0; SettingsPanel.ZIndex = 5; SettingsPanel.Parent = MainFrame
local SetLayout = Instance.new("UIListLayout"); SetLayout.SortOrder = Enum.SortOrder.LayoutOrder; SetLayout.Padding = UDim.new(0, 6); SetLayout.Parent = SettingsPanel
local SetPad = Instance.new("UIPadding"); SetPad.PaddingTop = UDim.new(0, 10); SetPad.PaddingLeft = UDim.new(0, 10); SetPad.PaddingRight = UDim.new(0, 10); SetPad.Parent = SettingsPanel

local isSettingsOpen = false
SettingsBtn.MouseButton1Click:Connect(function()
    isSettingsOpen = not isSettingsOpen
    if isSettingsOpen then
        SettingsBtn.TextColor3 = Color3.fromRGB(100, 150, 255)
        TweenService:Create(SettingsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 30)}):Play()
    else
        SettingsBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        TweenService:Create(SettingsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 1, 0)}):Play()
    end
end)

local function createToggle(parent, text, default, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 20); frame.BackgroundTransparency = 1; frame.ZIndex = 6; frame.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.6, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(240, 240, 240); lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 6; lbl.Parent = frame
    local bg = Instance.new("TextButton"); bg.Size = UDim2.new(0, 30, 0, 16); bg.Position = UDim2.new(1, -30, 0.5, -8); bg.BackgroundColor3 = default and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70); bg.Text = ""; bg.AutoButtonColor = false; bg.ZIndex = 6; Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0); bg.Parent = frame
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 10, 0, 10); knob.Position = default and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5); knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.ZIndex = 6; Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0); knob.Parent = bg
    local state = default
    bg.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)}):Play()
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)}):Play()
        callback(state)
    end)
end

createToggle(SettingsPanel, "🤖 Auto Play", Config.AutoPlay, function(val) Config.AutoPlay = val end)
createToggle(SettingsPanel, "👤 Humanizer", Config.Humanize, function(val) Config.Humanize = val end)

local ModeBtn = Instance.new("TextButton"); ModeBtn.Size = UDim2.new(1, 0, 0, 24); ModeBtn.BackgroundColor3 = Color3.fromRGB(0,0,0); ModeBtn.BackgroundTransparency = 0.5; ModeBtn.Text = "Mode: " .. Config.Playstyle; ModeBtn.TextColor3 = Color3.fromRGB(240, 240, 240); ModeBtn.Font = Enum.Font.GothamBold; ModeBtn.TextSize = 10; ModeBtn.ZIndex = 6; Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 4); local ModeStroke = Instance.new("UIStroke", ModeBtn); ModeStroke.Color = Color3.fromRGB(100, 150, 255); ModeStroke.Thickness = 1.2; ModeBtn.Parent = SettingsPanel
ModeBtn.MouseButton1Click:Connect(function() currentStyleIndex = (currentStyleIndex % #Playstyles) + 1; Config.Playstyle = Playstyles[currentStyleIndex]; ModeBtn.Text = "Mode: " .. Config.Playstyle end)

local SliderFrame = Instance.new("Frame"); SliderFrame.Size = UDim2.new(1, 0, 0, 25); SliderFrame.BackgroundTransparency = 1; SliderFrame.ZIndex = 6; SliderFrame.Parent = SettingsPanel
local SliderLabel = Instance.new("TextLabel"); SliderLabel.Size = UDim2.new(1, 0, 0, 12); SliderLabel.BackgroundTransparency = 1; SliderLabel.Text = "Speed: " .. Config.TypingDelayMS .. "ms"; SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200); SliderLabel.Font = Enum.Font.GothamMedium; SliderLabel.TextSize = 10; SliderLabel.TextXAlignment = Enum.TextXAlignment.Left; SliderLabel.ZIndex = 6; SliderLabel.Parent = SliderFrame
local Track = Instance.new("TextButton"); Track.Size = UDim2.new(1, 0, 0, 4); Track.Position = UDim2.new(0, 0, 1, -6); Track.BackgroundColor3 = Color3.fromRGB(60, 60, 70); Track.Text = ""; Track.AutoButtonColor = false; Track.ZIndex = 6; Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0); Track.Parent = SliderFrame
local Fill = Instance.new("Frame"); Fill.Size = UDim2.new((Config.TypingDelayMS - 1) / 899, 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255); Fill.ZIndex = 6; Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0); Fill.Parent = Track
local Knob = Instance.new("Frame"); Knob.Size = UDim2.new(0, 10, 0, 10); Knob.Position = UDim2.new(1, -5, 0.5, -5); Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Knob.ZIndex = 6; Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0); Knob.Parent = Fill

local sliding = false
local function updateSlider(input) local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1); Fill.Size = UDim2.new(pos, 0, 1, 0); local val = math.floor(1 + (899 * pos)); Config.TypingDelayMS = val; SliderLabel.Text = "Speed: " .. val .. "ms" end
Track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = true; updateSlider(input) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
UserInputService.InputChanged:Connect(function(input) if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end end)

local ResetBtn = Instance.new("TextButton"); ResetBtn.Size = UDim2.new(1, 0, 0, 22); ResetBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80); ResetBtn.BackgroundTransparency = 0.8; ResetBtn.Text = "🗑️ Reset Blacklist"; ResetBtn.TextColor3 = Color3.fromRGB(255, 150, 150); ResetBtn.Font = Enum.Font.GothamBold; ResetBtn.TextSize = 10; ResetBtn.ZIndex = 6; Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 4); ResetBtn.Parent = SettingsPanel
ResetBtn.MouseButton1Click:Connect(function() State.PermanentBlacklist = {}; if writefile then pcall(function() writefile("WORD/blacklist.txt", "") end) end; ResetBtn.Text = "Cleared!"; task.wait(1); ResetBtn.Text = "🗑️ Reset Blacklist" end)

-- UI Drag & Minimize Logic
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then 
        ScrollFrame.Visible = false; StatusLabel.Visible = false; SettingsBtn.Visible = false; SettingsPanel.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 220, 0, 30)}):Play()
    else 
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 220, 0, 260)}):Play()
        task.wait(0.15); ScrollFrame.Visible = true; StatusLabel.Visible = true; SettingsBtn.Visible = true; SettingsPanel.Visible = true
    end
end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
TopBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

local function updateStatusUI(customMsg, color)
    if customMsg then StatusLabel.Text = customMsg; StatusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255); return end
    if #Dictionary == 0 then return end
    if State.IsMyTurn then StatusLabel.Text = "🔥 Awalan: " .. State.ServerLetter:upper(); StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    else StatusLabel.Text = "💤 Menunggu giliran..."; StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150) end
end

-- =========================================================
-- 🔘 OBJECT POOLING (GRID BUTTONS)
-- =========================================================
local ButtonPool = {}
local function getPoolButton(index)
    if not ButtonPool[index] then
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(0,0,0); btn.BackgroundTransparency = 0.6
        btn.TextColor3 = Color3.fromRGB(240, 240, 240); btn.Font = Enum.Font.GothamMedium; btn.TextSize = 9; btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.AutoButtonColor = false; btn.Parent = ScrollFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(60, 60, 70); stroke.Transparency = 0.5
        
        btn.MouseEnter:Connect(function() if btn.Interactable then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play(); stroke.Color = Color3.fromRGB(100, 150, 255) end end)
        btn.MouseLeave:Connect(function() if btn.Interactable then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play(); stroke.Color = Color3.fromRGB(60, 60, 70) end end)
        
        ButtonPool[index] = {btn = btn, stroke = stroke, word = ""}
        btn.MouseButton1Click:Connect(function() if ButtonPool[index].word ~= "" then typeAndSubmitWord(ButtonPool[index].word, btn) end end)
    end
    
    local p = ButtonPool[index]
    p.btn.Visible = true; p.btn.Interactable = true; p.btn.BackgroundTransparency = 0.6; p.btn.TextColor3 = Color3.fromRGB(240, 240, 240); p.stroke.Color = Color3.fromRGB(60, 60, 70)
    return p
end

local function hideAllButtons() for _, p in ipairs(ButtonPool) do p.btn.Visible = false; p.word = "" end end

-- =========================================================
-- 📚 SMART SYNC ENGINE (10 DATABASES)
-- =========================================================
local function fetchWithRetry(url, maxRetries)
    for i = 1, maxRetries do
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res and #res > 0 then return res end
        task.wait(1)
    end
    return nil
end

task.spawn(function()
    local clock = os.clock; local heartbeat = RunService.Heartbeat

    if isfile and isfile("WORD/blacklist.txt") then
        local ok, content = pcall(readfile, "WORD/blacklist.txt")
        if ok and content then for word in string.gmatch(content, "%a+") do State.PermanentBlacklist[lower(word)] = true end end
    end

    if isfile and isfile("WORD/verified.txt") then
        local ok, content = pcall(readfile, "WORD/verified.txt")
        if ok and content then for word in string.gmatch(content, "%a+") do processWord(word, false, true) end end
    end

    if isfile and isfile("WORD/master_cache.txt") then
        updateStatusUI("📂 Membaca Local Cache...", Color3.fromRGB(100, 150, 255))
        local ok, content = pcall(readfile, "WORD/master_cache.txt")
        if ok and content then
            local startTime = clock()
            for word in string.gmatch(content, "%a+") do
                processWord(word, false, false)
                if clock() - startTime > 0.008 then heartbeat:Wait(); startTime = clock() end
            end
        end
    end

    updateStatusUI("🔄 Sinkronisasi 10 Database...", Color3.fromRGB(100, 200, 255))
    local urls = {
        "https://raw.githubusercontent.com/damzaky/kumpulan-kata-bahasa-indonesia-KBBI/refs/heads/master/legacy/indonesian-words.txt",
        "https://raw.githubusercontent.com/sastrawi/sastrawi/master/data/kata-dasar.txt",
        "https://raw.githubusercontent.com/Bhinneka/indonesian-wordlist/master/indonesian-words.txt",
        "https://raw.githubusercontent.com/Wikidepia/indonesian_datasets/refs/heads/master/dictionary/wordlist/data/wordlist.txt",
        "https://cdn.jsdelivr.net/gh/Biasaemail/SCRIPT-ROBLOX-LUA-ME@refs/heads/main/50000_kata_kbbi_baku.txt",
        "https://cdn.jsdelivr.net/gh/Biasaemail/SCRIPT-ROBLOX-LUA-ME@refs/heads/main/kbbi_72276_kata_baku.txt",
        "https://raw.githubusercontent.com/titoBouzout/Dictionaries/master/Indonesian.txt",
        "https://raw.githubusercontent.com/lorenbrichter/Words/master/Words/id.txt",
        "https://raw.githubusercontent.com/open-dict-data/ipa-dict/master/data/id.txt",
        "https://raw.githubusercontent.com/romadhon8165-max/v/refs/heads/main/Sambung%20Kata%20Jembot.lst"
    }
    
    local pendingTasks = 0; local webChunks = {}
    for _, url in ipairs(urls) do
        pendingTasks = pendingTasks + 1
        task.spawn(function()
            local res = fetchWithRetry(url, 3)
            if res then table.insert(webChunks, res) end
            pendingTasks = pendingTasks - 1
        end)
    end
    while pendingTasks > 0 do heartbeat:Wait() end

    local startTime = clock()
    for _, chunk in ipairs(webChunks) do
        for word in string.gmatch(chunk, "%a+") do
            processWord(word, true, false) 
            if clock() - startTime > 0.008 then heartbeat:Wait(); startTime = clock() end
        end
    end

    flushWriteQueue()
    webChunks = nil; collectgarbage("collect")
    updateStatusUI("✅ Ready! (" .. totalWords .. " Kata)", Color3.fromRGB(100, 255, 150))
    task.wait(2); updateStatusUI()
end)

-- =========================================================
-- 🧠 AI SCORING ALGORITHM
-- =========================================================
local DeadlyEndings = { ["if"]=100000, ["ef"]=100000, ["of"]=100000, ["af"]=100000, ["uf"]=100000, x=90000, z=90000, q=90000, f=80000, v=80000, w=70000, nk=60000, nc=60000, ps=60000, rs=60000, ny=50000, ng=40000 }

local function getWordScore(word, mode)
    local len = #word
    if mode == "Easy Win" then
        local s1, s2 = sub(word, -1), sub(word, -2)
        local bonus = DeadlyEndings[s2] or DeadlyEndings[s1] or 0
        local count2 = WordsStartingWith[s2] or 0
        local count3 = WordsStartingWith[sub(word, -3)] or 0
        local baseScore = 50000 - math.min(count2, count3)
        if count2 == 0 or count3 == 0 then baseScore = 150000 end 
        return baseScore + bonus + (len * 10)
    elseif mode == "Combo" then
        local s2, s3 = sub(word, -2), sub(word, -3)
        local count2 = WordsStartingWith[s2] or 0
        local count3 = WordsStartingWith[s3] or 0
        local baseScore = 10000 - math.min(count2, count3)
        if count2 == 0 or count3 == 0 then baseScore = 50000 end
        local staticBonus = DeadlyEndings[s3] or DeadlyEndings[s2] or DeadlyEndings[sub(word, -1)] or 0
        return baseScore + staticBonus + (len * 2)
    elseif mode == "Longest" then return len * 100
    elseif mode == "Shortest" then return 100 - len
    else return random(1, 100) + (len > 4 and 20 or 0) end
end

-- =========================================================
-- ⌨️ HUMANIZED TYPING & SUBMIT LOGIC
-- =========================================================
local function fireTypingSim(word)
    if remotes:FindFirstChild("UpdateCurrentWord") then remotes.UpdateCurrentWord:FireServer(word) end
    if remotes:FindFirstChild("WordUpdate") then remotes.WordUpdate:FireServer(word) end
    if remotes:FindFirstChild("BillboardUpdate") then remotes.BillboardUpdate:FireServer(word) end
end

local function fireSubmitFinal(word)
    if remotes:FindFirstChild("SubmitWord") then remotes.SubmitWord:FireServer(word) end
    if remotes:FindFirstChild("BillboardEnd") then remotes.BillboardEnd:FireServer() end
end

function typeAndSubmitWord(word, uiButton)
    if State.IsTyping or not State.IsMyTurn then return false end
    State.IsTyping = true; State.HasSubmitted = false; State.TriedThisTurn[word] = true; State.LastSubmittedWord = word; State.ValidationResult = nil 

    local currentTyped = State.ServerLetter
    local remaining = sub(word, #currentTyped + 1)
    local baseDelay = Config.TypingDelayMS / 1000

    if Config.Humanize and Config.AutoPlay and #word > 6 then task.wait(random(200, 600) / 1000) end

    for i = 1, #remaining do
        if not State.IsMyTurn then break end
        local correctChar = sub(remaining, i, i)
        
        if Config.Humanize and Config.TypingDelayMS > 10 and random() < 0.03 then
            local adj = KeyboardAdjacent[correctChar]
            if adj then
                local wrongChar = sub(adj, random(1, #adj), random(1, #adj))
                fireTypingSim(currentTyped .. wrongChar)
                if remotes:FindFirstChild("TypeSound") then remotes.TypeSound:FireServer() end
                task.wait(baseDelay * 2) 
                fireTypingSim(currentTyped) 
                if remotes:FindFirstChild("TypeSound") then remotes.TypeSound:FireServer() end
                task.wait(baseDelay * 1.5)
            end
        end

        currentTyped = currentTyped .. correctChar
        fireTypingSim(currentTyped)
        if remotes:FindFirstChild("TypeSound") then remotes.TypeSound:FireServer() end
        
        local variance = Config.Humanize and (random(70, 130) / 100) or 1
        if Config.TypingDelayMS <= 10 then RunService.Heartbeat:Wait() else task.wait(baseDelay * variance) end
    end

    if State.IsMyTurn then
        task.wait(0.05)
        fireSubmitFinal(word)
        State.HasSubmitted = true
        
        local timeout = 0
        while State.ValidationResult == nil and State.IsMyTurn and timeout < 10 do task.wait(0.1); timeout = timeout + 1 end

        if State.ValidationResult == "SUCCESS" then
            State.UsedWords[word] = true; State.IsTyping = false; return true 
        else
            queueWrite("blacklist", word); State.PermanentBlacklist[word] = true
            if uiButton then
                TweenService:Create(uiButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 20, 20)}):Play()
                uiButton.Text = " ❌ " .. word:upper(); uiButton.Interactable = false
            end
            State.IsTyping = false; return false 
        end
    end
    State.IsTyping = false; return false 
end

-- =========================================================
-- 📝 FAST TOP-K INSERTION (TRIE LOOKUP)
-- =========================================================
local function generateAndPlayTurn(prefix)
    hideAllButtons()
    if not prefix or prefix == "" or #Dictionary == 0 then return end

    local lowerPrefix = lower(prefix)
    local searchPool = getFromTrie(lowerPrefix)

    local mode = Config.Playstyle
    local topWords = {} 
    local MAX_WORDS = 150

    for _, dictIndex in ipairs(searchPool) do
        local w = Dictionary[dictIndex]
        if not State.UsedWords[w] and not State.TriedThisTurn[w] and not State.PermanentBlacklist[w] then
            local score = getWordScore(w, mode)
            local insertPos = #topWords + 1
            for i = 1, #topWords do if score > topWords[i].score then insertPos = i; break end end
            if insertPos <= MAX_WORDS then
                table.insert(topWords, insertPos, {word = w, score = score})
                if #topWords > MAX_WORDS then topWords[MAX_WORDS + 1] = nil end
            end
        end
    end

    local uiButtons = {}
    for i = 1, #topWords do
        local p = getPoolButton(i)
        p.word = topWords[i].word
        p.btn.Text = " " .. p.word:upper() .. " (" .. #p.word .. ")"
        uiButtons[i] = p.btn
    end

    if Config.AutoPlay and not State.BotExecuting then
        State.BotExecuting = true
        task.spawn(function()
            task.wait(random(50, 150) / 100) 
            for i = 1, #topWords do
                if not State.IsMyTurn or not Config.AutoPlay then break end
                local targetWord = topWords[i].word
                updateStatusUI("🤖 Mengetik: " .. targetWord:upper(), Color3.fromRGB(100, 150, 255))
                local success = typeAndSubmitWord(targetWord, uiButtons[i])
                if success then break end 
                if State.IsMyTurn and Config.AutoPlay then task.wait(0.2) end
            end
            State.BotExecuting = false
        end)
    end
end

-- =========================================================
-- 📡 ENEMY WORD STEALING (LEARNING AI)
-- =========================================================
local function onEnemyWordUpdate(word)
    if State.MatchActive and word and word ~= "" then 
        local lw = lower(word)
        State.UsedWords[lw] = true 
        if not KnownWords[lw] then processWord(lw, false, true)
        elseif not State.VerifiedWords[lw] then State.VerifiedWords[lw] = true; queueWrite("verified", lw) end
    end
end

if remotes:FindFirstChild("MatchUI") then
    remotes.MatchUI.OnClientEvent:Connect(function(cmd, value)
        if cmd == "ShowMatchUI" then
            State.MatchActive = true; State.IsMyTurn = false; State.UsedWords = {}; State.TriedThisTurn = {}
            hideAllButtons(); updateStatusUI()
        elseif cmd == "HideMatchUI" then
            State.MatchActive = false; State.IsMyTurn = false; State.ServerLetter = ""; State.ValidationResult = "SUCCESS"
            hideAllButtons(); updateStatusUI("🏁 Match Selesai", Color3.fromRGB(150, 150, 150))
        elseif cmd == "StartTurn" then
            State.IsMyTurn = true; State.TriedThisTurn = {}; State.BotExecuting = false; updateStatusUI()
            generateAndPlayTurn(State.ServerLetter)
        elseif cmd == "EndTurn" then
            State.IsMyTurn = false; State.ValidationResult = "SUCCESS"; hideAllButtons(); updateStatusUI()
        elseif cmd == "UpdateServerLetter" then
            State.ServerLetter = value or ""; updateStatusUI()
        end
    end)
end

if remotes:FindFirstChild("BillboardUpdate") then remotes.BillboardUpdate.OnClientEvent:Connect(onEnemyWordUpdate) end
if remotes:FindFirstChild("UpdateCurrentWord") then remotes.UpdateCurrentWord.OnClientEvent:Connect(onEnemyWordUpdate) end
if remotes:FindFirstChild("WordUpdate") then remotes.WordUpdate.OnClientEvent:Connect(onEnemyWordUpdate) end

print("🚀 RAMA V1 LOADED! [Ultra Compact Grid UI Active]")