if not game:IsLoaded() then
    print("waiting")
    game.Loaded:Wait()
end

print("Loaded")

local workspace = game.Workspace
local tweenService = game:GetService("TweenService")
local JSON = loadstring(game:HttpGet("https://gist.githubusercontent.com/lvzixun/80e5b900b82059ebf5d7/raw/4e6ce4f28fef30bf32e485996892dd50ad2fa944/json.lua"))()

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

local ts = game:GetService("TeleportService") 

local resources = {}
local resourcePositions = {}

function teleportToOtherServer(player)
	--local id = "cbff7bf6-1f90-47a3-b3f7-51d9d6cc67e1"

	local jsonHTTP = game:HttpGet("https://games.roblox.com/v1/games/99995671928896/servers/public?limit=100&excludeFullGames=true")

	local tbl = JSON:decode(jsonHTTP)

	if (tbl.errors ~= nil) then
		task.wait(20)
		teleportToOtherServer(player)
	end

	queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/ShiroXXBlank/luascript/refs/heads/main/lastVersion.lua'))()")

	ts:TeleportToPlaceInstance(game.PlaceId, tbl.data[math.random(1, tableLength(tbl))]["id"], player) 
end

function distance(obj1, obj2)
    if (obj1 == nil or obj2 == nil) then return end
	return math.sqrt((obj2.X - obj1.X)^2 + (obj2.Y - obj1.Y)^2 + (obj2.Z - obj1.Z)^2)
end

function tableLength(T)
    if T == nil then return end
    
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function getPosition(obj)
	return obj:GetBoundingBox().Position
end

-- Get Resource
function getResources(resourceName) 
	local harvestables = workspace.Harvestable:GetChildren()
	local resourceTable = {}
	local playerPosition = getPlayerPosition(localPlayer)

	for _, obj in pairs(harvestables) do
		if (obj.Name == resourceName and obj:FindFirstChildOfClass("ProximityPrompt") ~= nil) then
			table.insert(resourceTable, obj)
		end
	end

	-- Sort table by closest to player
	table.sort(resourceTable, function(resource1, resource2) return distance(getPosition(resource1), playerPosition) < distance(getPosition(resource2), playerPosition) end)

	return resourceTable
end

-- Interact with Resource
function interactWithObj(resourceObj)
	fireproximityprompt(resourceObj:FindFirstChildOfClass("ProximityPrompt"))
end

function getPlayerPosition(player) 
    if (player.Character == nil) then return end
	return player.Character.HumanoidRootPart.Position
end

function tweenTeleport(position, speed)
	local time = distance(position, getPlayerPosition(localPlayer)) / speed
	print("Starting teleport")

	local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)

	local cf = CFrame.new(position)
	local a = tweenService:Create(players.LocalPlayer.Character.HumanoidRootPart, tweenInfo, {CFrame=cf})
	a:Play()
	a.Completed:Wait()
	print("Teleporting Done!")
end

function farm(resource)
    local args = {
        [1] = {
            ["player"] = game:GetService("Players").LocalPlayer,
            ["Object"] = getResources(resource.Name)[1],
            ["Action"] = "Chop"
        }
    }

    game:GetService("Players").LocalPlayer.Character.CharacterHandler.Input.Events.Interact:FireServer(unpack(args))
end

function farmResource(resource)
	local resourceName = resource.Name
	local resourcePosition = getPosition(resource)

	if (resource:FindFirstChildOfClass("ProximityPrompt") == nil) then
		return
	end

	if (resourceName == "Platinum" and resourcePosition.Y < 200 and math.floor(resourcePosition.Y) ~= 168) then
		resourcePosition = Vector3.new(resourcePosition.X, resourcePosition.Y - 3, resourcePosition.Z)
	end

	-- Teleport
	tweenTeleport(resourcePosition, 100)
	if (resource:FindFirstChildOfClass("ProximityPrompt") ~= nil) then
		farm(resource)
	end

	--Hover While Farming
	while localPlayer.PlayerGui.GUI.ProgressBars:FindFirstChild("ProgressFrame") ~= nil do
		if (resourceName == "Platinum" and resourcePosition.Y < 200 or math.floor(resourcePosition.Y) ~= 168) then
			game.Workspace.Alive.ShiroXXBlank:SetPrimaryPartCFrame(CFrame.new(resourcePosition))
		end
		task.wait(0.005)
	end

	if (resource:FindFirstChildOfClass("ProximityPrompt") ~= nil) then
		farmResource(resource)
	end
end

function clickRandomServer()
	local serverList = localPlayer.PlayerGui
end

local noFallDmgCo = coroutine.create(function()
	local players = game:GetService("Players")
	local localPlayer = players.LocalPlayer
	
	if localPlayer.Character == nil then return end

	while task.wait(0.005) do
		if (localPlayer:GetAttribute("CO") == false) then
			coroutine.yield()
		end
    	localPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
	end
end)

-- Create the attribute to turn on and off coroutine
function toggleCO()
    if (localPlayer == nil) then return end
	if (localPlayer:GetAttribute("CO") == false or localPlayer:GetAttribute("CO") == nil) then
		coroutine.resume(noFallDmgCo)
		localPlayer:SetAttribute("CO", true)
	elseif (localPlayer:GetAttribute("CO")) then
		localPlayer:SetAttribute("CO", false)
	end
end

if (localPlayer.PlayerGui:WaitForChild("Menu", 10) ~= nil) then
    local args = {
        [1] = {
            ["config"] = "start_screen"
        }
    }

    game:GetService("Players").LocalPlayer.ClientNetwork:WaitForChild("MenuOptions"):FireServer(unpack(args)) -- Hit continue button

    args = {
        [1] = {
            ["config"] = "slots",
            ["slot"] = "Slot_1"
        }
    }
    
    task.wait(5)

    game:GetService("Players").LocalPlayer.ClientNetwork:WaitForChild("MenuOptions"):FireServer(unpack(args)) -- Hit Character Slot
else
    local resource = "Platinum"
    resources = getResources(resource)

    if (tableLength(resources) == 0) then
        print("NO ORE JOINING DIFFERENT SERVER")
        teleportToOtherServer(localPlayer)
    else
        toggleCO()

        for _, v in pairs(resources) do
            print(v)
            farmResource(v)
            resources = getResources(resource)
        end

        print("finished mining proceeding to hop servers")

        toggleCO()

        teleportToOtherServer(localPlayer)
    end
end
