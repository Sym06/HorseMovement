math.randomseed(tick())

local debris = game:GetService("Debris")
local runservice = game:GetService("RunService")
local serverStorage = game:GetService("ServerStorage")
local tweenservice = game:GetService("TweenService")
local horse = script.Parent.Parent
local humanoid = horse["Horse Coloring Section"].Humanoid
local hrp = horse["Horse Coloring Section"].HumanoidRootPart
local saddle = horse.Saddle
local proximityPrompt = saddle.ProximityPrompt
local event = script.HorseEvents
local physicsService = game:GetService("PhysicsService")
local dataModule = require(game.ServerScriptService.PlayerData.Manager)

local throttle, steer = 0, 0
local maxSpeed, minSpeed = 40, 0
local maxSpeed2, minSpeed2 = 10, 0
local acceleration = 0.5
local fadeTime = 0.3
local walkMode = true

local loopOn = false

local animator = humanoid:FindFirstChildOfClass("Animator")
local animation1 = Instance.new("Animation")
animation1.AnimationId = 'rbxassetid://12911768657'
local animation2 = Instance.new("Animation")
animation2.AnimationId = 'rbxassetid://12911746373'
local animation3 = Instance.new("Animation")
animation3.AnimationId = 'rbxassetid://12911750135'
local animation4 = Instance.new("Animation")
animation4.AnimationId = 'rbxassetid://12919445902'
local animation5 = Instance.new("Animation")
animation5.AnimationId = 'rbxassetid://14249363716'
local animation6 = Instance.new("Animation")
animation6.AnimationId = 'rbxassetid://14249360466'

local animationChar1 = Instance.new("Animation")
local animationChar2 = Instance.new("Animation")
local animationChar3 = Instance.new("Animation")
animationChar3.AnimationId = 'rbxassetid://12911933318'
animationChar1.AnimationId = 'rbxassetid://14251316154'
animationChar2.AnimationId = 'rbxassetid://14263560434'

local animationRunning = animator:LoadAnimation(animation1)
local animationWalking = animator:LoadAnimation(animation2)
local animationIdle = animator:LoadAnimation(animation3)
local animationDeath = animator:LoadAnimation(animation4)
local animationLeft = animator:LoadAnimation(animation5)
local animationRight = animator:LoadAnimation(animation6)

local sfxGallop = hrp.horse_gallop
local sfxWalk = hrp.horse_walksound2

local randomDamage = {
	hrp.horse_breath,
	hrp.horse_scream
}

local angularVelocity = Instance.new("AngularVelocity")
angularVelocity.Parent = hrp
angularVelocity.MaxTorque = math.huge
angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
angularVelocity.Attachment0 = hrp.RootAttachment

humanoid.HealthChanged:Connect(function()
	local randDmgSound = randomDamage[math.random(1, #randomDamage)]
	if not randDmgSound.IsPlaying then
		randDmgSound:Play()
	end
end)

proximityPrompt.Triggered:Connect(function(touched)
	local character = touched.Character
	if character.Bools.IsRidingHorse.Value == true then return end
	local part = Instance.new("Part")
	local tempWeld = Instance.new("WeldConstraint")
	tempWeld.Parent = horse
	part.Name = "CameraSubject"
	part.Transparency = 1
	part.CFrame = saddle.CFrame * CFrame.new(0, 2.5, 0)
	tempWeld.Part0 = saddle
	tempWeld.Part1 = part
	part.Parent = horse
	character.Parent = horse
	local animator = character.Humanoid:FindFirstChildOfClass("Animator")
	sitAnimL = animator:LoadAnimation(animationChar1)
	sitAnimR = animator:LoadAnimation(animationChar2)
	
	character.Humanoid.WalkSpeed = 0
	character.Bools.IsRidingHorse.Value = true
	
	character.Humanoid.AutoRotate = false
	
	weld = Instance.new("WeldConstraint")
	
	local cframe = saddle.CFrame:ToObjectSpace(character.HumanoidRootPart.CFrame)
	
	if cframe.X < 0 then
		character.HumanoidRootPart.CFrame = saddle.CFrame * CFrame.new(-1.5, -1, 0) * CFrame.Angles(0, math.rad(-90), 0)
		sitAnimL:Play()
	else
		character.HumanoidRootPart.CFrame = saddle.CFrame * CFrame.new(1.5, -1, 0) * CFrame.Angles(0, math.rad(90), 0)
		sitAnimR:Play()
	end
	
	weld.Parent = horse
	weld.Part0 = hrp
	proximityPrompt.Enabled = false
	wait(0.8)
	character.HumanoidRootPart.CFrame = saddle.CFrame * CFrame.new(0, 2.5, 0)
	weld.Part1 = character.HumanoidRootPart
	character.Humanoid.AutoRotate = true
	tempWeld:Destroy()
	part:Destroy()
	loopOn = true
	
end)

local player, character
event.OnServerEvent:Connect(function(plr: Player, arg)
	if sitAnimL.IsPlaying or sitAnimR.IsPlaying then return end
	player = plr
	character = plr.Character
	if arg == "W" then
		throttle = 1
	elseif arg == "A" then
		steer = -1
	elseif arg == "D" then
		steer = 1
	end
	
	if arg == "Alt" then
		weld:Destroy()
		character.Parent = workspace
		character.Humanoid.WalkSpeed = 16
		character.Bools.IsRidingHorse.Value = false
		wait(1)
		proximityPrompt.Enabled = true
	end
	
	if arg == "Space" then
		humanoid.Jump = true
		wait(0.5)
		humanoid.Jump = false
	end
	
	if arg == "Control" then
		if not walkMode then
			walkMode = true
		else
			walkMode = false
		end
	end
	
	if arg == "W Lifted" then
		throttle = 0
	elseif arg == "A Lifted" then
		steer = 0
	elseif arg == "D Lifted" then
		steer = 0
	end
end)

humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	if character.Bools.IsRidingHorse.Value == false then return end
	if humanoid.WalkSpeed == maxSpeed then
		if player then
			event:FireClient(game:GetService("Players"):GetPlayerFromCharacter(character), "shake")
		end
	elseif humanoid.WalkSpeed > 0 and humanoid.WalkSpeed ~= maxSpeed then
		if player then
			event:FireClient(game:GetService("Players"):GetPlayerFromCharacter(character), "stop shake")
		end
	else
		if player then
			event:FireClient(game:GetService("Players"):GetPlayerFromCharacter(character), "0 speed")
		end
	end
end)

humanoid.Died:Connect(function()
	horse.Name = "Dead Horse"
	if animationWalking.IsPlaying then
		animationWalking:Stop(fadeTime)
	elseif animationRunning.IsPlaying then
		animationRunning:Stop(fadeTime)
	elseif animationIdle.IsPlaying then
		animationIdle:Stop(fadeTime)
	end

	proximityPrompt.Enabled = false
	angularVelocity:Destroy()
	if weld then
		weld:Destroy()
	end
	character.Humanoid.WalkSpeed = 16
	character.Bools.IsRidingHorse.Value = false
	character.Bools.HorseSpawned.Value = false
	character.Parent = workspace
	animationDeath:Play()
	hrp:Destroy()
	debris:AddItem(horse, 120)
	horse["Horse Coloring Section"].Torso.CustomPhysicalProperties = PhysicalProperties.new(100, 0.05, 2.5, 0.5, 5)
	horse["Horse Coloring Section"].FakeHead.CustomPhysicalProperties = PhysicalProperties.new(100, 0.05, 2.5, 0.5, 5)
	horse["Horse Coloring Section"].TorsoBack.CustomPhysicalProperties = PhysicalProperties.new(100, 0.05, 2.5, 0.5, 5)
	script:Destroy()
end)

while wait() do
	if loopOn == false then
		continue
	end
	
	if character then
		if character.Parent ~= horse then
			throttle, steer = 0, 0
		end
	end

	if walkMode == false then
		if humanoid.WalkSpeed < maxSpeed then
			if throttle == 1 then
				humanoid:Move(hrp.CFrame.LookVector * throttle)
				humanoid.WalkSpeed += acceleration
			end
		else
			humanoid:Move(hrp.CFrame.LookVector * throttle)
		end
	else
		if humanoid.WalkSpeed < maxSpeed2 then
			if throttle == 1 then
				humanoid:Move(hrp.CFrame.LookVector * throttle)
				humanoid.WalkSpeed += acceleration
			end
		elseif humanoid.WalkSpeed == maxSpeed2 then
			humanoid:Move(hrp.CFrame.LookVector * throttle)
		else
			humanoid:Move(hrp.CFrame.LookVector * throttle)
			humanoid.WalkSpeed -= acceleration
		end
	end

	if throttle == 0 and humanoid.WalkSpeed > minSpeed then
		humanoid:Move(hrp.CFrame.LookVector)
		humanoid.WalkSpeed -= 1
	elseif throttle == 0 and humanoid.WalkSpeed == 0 then
		humanoid.WalkSpeed = 0
	end
	
	if humanoid.WalkSpeed == 0 then
		sfxGallop:Stop()
		sfxWalk:Stop()
		animationRunning:Stop(fadeTime)
		animationWalking:Stop(fadeTime)
		if not animationIdle.IsPlaying then
			animationIdle:Play(fadeTime)
		end
	elseif humanoid.WalkSpeed > maxSpeed2 + 15 then
		sfxWalk:Stop()
		animationIdle:Stop(fadeTime)
		animationWalking:Stop(fadeTime)
		if not animationRunning.IsPlaying then
			animationRunning:Play(fadeTime)
		end
		animationRunning:AdjustSpeed(humanoid.WalkSpeed/30)
		if not sfxGallop.IsPlaying then
			sfxGallop:Play()
		end
	elseif humanoid.WalkSpeed <= maxSpeed2 + 15 then
		sfxGallop:Stop()
		animationIdle:Stop(fadeTime)
		animationRunning:Stop(fadeTime)
		if not animationWalking.IsPlaying then
			animationWalking:Play(fadeTime)
		end
		if not sfxWalk.IsPlaying then
			sfxWalk:Play()
		end
	end
	
	if steer == -1 then
		if animationRight.IsPlaying then
			animationRight:Stop(fadeTime)
		end
		if not animationLeft.IsPlaying then
			animationLeft:Play(fadeTime)
		end
	elseif steer == 1 then
		if animationLeft.IsPlaying then
			animationLeft:Stop(fadeTime)
		end
		if not animationRight.IsPlaying then
			animationRight:Play(fadeTime)
		end
	else
		if animationRight.IsPlaying then
			animationRight:Stop(fadeTime)
		elseif animationLeft.IsPlaying then
			animationLeft:Stop(fadeTime)
		end
	end
	
	angularVelocity.AngularVelocity = Vector3.new(0, -2.5 * steer, 0)
end