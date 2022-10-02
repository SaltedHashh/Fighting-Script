-- Made By SaltedHash#7231

local Reach = 4; -- How far the player can reach with punches

--------- Define Variables for networking
local RS = game:GetService("ReplicatedStorage");
local CombatRemotes = RS:WaitForChild("CombatRemotes");
local LPunchRemote = CombatRemotes:WaitForChild("LightPunch");
local Debounce = false;

--------- Styles metatable
local Styles = {};
Styles.__index = Styles;
Styles.CurrentStyle = nil;
--------- Animations Object For Making Styles Easier
local Animations = {}
function Animations.new(ID, Speed)
	Speed = Speed or 1;
	local AnimTable = {
		["ID"]="rbxassetid://"..ID,
		["Speed"] = Speed
	}
	return AnimTable;
end
---------

--------- Define Variables for animation and character stuff
local Char = script.Parent;
local Animate = Char:WaitForChild("Animate");
--------- GET RID OF UNNEEDED STUFF
local Idle = Animate:WaitForChild("idle");
local IdleAnim2 = Idle:FindFirstChild("Animation2");
if IdleAnim2 then IdleAnim2:Destroy(); end
--------- Create Animation Stuff
local AnimationFolder = Instance.new("Folder");
AnimationFolder.Name = "Anims";
AnimationFolder.Parent = Animate;

local LightPunchAnimations = Instance.new("Folder");
LightPunchAnimations.Name = "LPAnims";
LightPunchAnimations.Parent = AnimationFolder;
---------




function ClearChildren(Folder)
	local Children = Folder:GetChildren()
	if #Children > 0 then
		for _,v in next,Children do
			if v:IsA("Animation") then
				v:Destroy();
			end
		end
	end
end

----- Animation functions
function ChangeIdleAnimation(AnimationObj)
	local Animate = Char:WaitForChild("Animate");
	local Idle = Animate:WaitForChild("idle");
	local IdleAnim = Idle:WaitForChild("Animation1");

	IdleAnim.AnimationId = AnimationObj.ID;
end

function ChangeLPunchAnimations(AOs)
	ClearChildren(LightPunchAnimations);
	for Index,AnimationObj in next,AOs do
		local Animation = Instance.new("Animation");
		Animation.Name = "LightPunch"..tostring(Index);
		Animation.AnimationId = AnimationObj.ID;
		Animation.Parent = LightPunchAnimations;
	end
end
-----


function Styles.new(Name, Info)
	local NewStyle = {
		["Name"] = Name,
		["IdleAnimation"] = 0,
		["LightPunch"] = {
			["basedmg"] = 0,
			["animations"] = {}
		},
		["HeavyPunch"] = {
			["basedmg"] = 0,
			["animations"] = {}
		}
	}
	if Info then
		NewStyle["IdleAnimation"] = Info["Idle"];
		NewStyle["LightPunch"] = Info["LightPunch"];
		NewStyle["HeavyPunch"] = Info["HeavyPunch"];
		
		return setmetatable(NewStyle, Styles);
	end
	
	return setmetatable(NewStyle, Styles);
end
function Styles:ChangeIdle(NewIdle)
	self.IdleAnimation = NewIdle;
	ChangeIdleAnimation(self.IdleAnimation);
end
function Styles:ChangeLightDmg(NewDmg)
	self.LightPunch.dmg = NewDmg;
end
function Styles:ChangeLightAnimations(NewAnims)
	self.LightPunch.animations = NewAnims;
end

function Styles:SetCurrentStyle(NewStyle)
	self.CurrentStyle = NewStyle;
	ChangeIdleAnimation(NewStyle.IdleAnimation);
	ChangeLPunchAnimations(NewStyle.LightPunch.animations);
end


SFS = Styles.new("Street Fighting",
	{
		["Idle"] = Animations.new(11141169348),
		["LightPunch"] = {
			["basedmg"] = 5,
			["animations"] = {Animations.new(11148142938, 1.2)};
		},
		["HeavyPunch"] = {
			["basedmg"] = 10,
			["animations"] = {0}
		}
	}
)

Styles:SetCurrentStyle(SFS);

local SequentialPunches = 1;
--------- REMOTE STUFF

--- Define Variables For Damage Indicator
local ServerStorage = game:GetService("ServerStorage");
local Debris = game:GetService("Debris");
local PunchingAssets = ServerStorage:WaitForChild("PunchingAssets");
local DamageIndicator = PunchingAssets:WaitForChild("DI");
---

--- DAMAGE FUNCTIONS



function DoDamage(Dmg) -- The damage indicator is based off of the right arm, this can be changed to anything else I just don't like relying on other clients.
	local HRP = Char:WaitForChild("HumanoidRootPart");
	local RArm = Char:WaitForChild("Right Arm");
	local RO = HRP.Position;
	local RD = HRP.CFrame.LookVector*Reach;
	
	local Raycast = workspace:Raycast(RO, RD);
	if Raycast then
		local HitPart = Raycast.Instance;
		local Character = HitPart.Parent or HitPart.Parent.Parent or nil;
		if Character and Character:IsA("Model") then
			local Humanoid = Character:FindFirstChild("Humanoid");
			if Humanoid then
				if Humanoid.Health < 0 then return; end -- Don't do anything if player is dead.
				Humanoid.Health -= Dmg;
				local DIT = coroutine.create(function()
					local DI = DamageIndicator:Clone();
					local BGUI = DI:WaitForChild("Hit");
					local Label = BGUI:WaitForChild("DMG");
					Label.Text = tostring(Dmg);
					DI.CFrame = RArm.CFrame*CFrame.new(0,-3,0);
					DI.Parent = workspace;
					local TargetCFrame = DI.CFrame+Vector3.new(0,5,0);
					for i=0,1,0.1 do
						DI.CFrame = DI.CFrame:lerp(TargetCFrame,0.1);
						task.wait();
					end
					TargetCFrame = DI.CFrame-Vector3.new(0,5,0);
					for i=0,1,0.1 do
						DI.CFrame = DI.CFrame:lerp(TargetCFrame,0.05);
						task.wait();
					end
					Debris:AddItem(DI,0.5);
				end)
				coroutine.resume(DIT);
			end
		end
	end
end
---


LPunchRemote.OnServerEvent:Connect(function(Plr)
	if Plr.Character ~= Char then return; end -- Don't do anything if we did not fire the remote.
	
	
	----- DEBOUNCE
	if Debounce then return; end -- Do nothing if debounce
	Debounce = true
	----- DEFINE VARIABLES
	local Humanoid = Char:WaitForChild("Humanoid");
	local Animator = Humanoid:WaitForChild("Animator");
	local CurStyle = Styles.CurrentStyle;
	local LightPunch = CurStyle.LightPunch;
	local LPunchAnims = LightPunch.animations;
	----- PLAY ANIMATION
	local PunchAnim = LightPunchAnimations["LightPunch"..tostring(SequentialPunches)];
	local PunchAnimObj = LPunchAnims[SequentialPunches];
	local Speed = PunchAnimObj.Speed;
	local BaseDmg = LightPunch.basedmg;
	
	local Damage = math.random(BaseDmg, BaseDmg+5);
	
	if PunchAnim then
		local PunchTrack = Animator:LoadAnimation(PunchAnim);
		PunchTrack:Play();
		PunchTrack:AdjustSpeed(Speed);
		wait((PunchTrack.Length/Speed)/2);
		----- Do damage in the middle of the animation.
			DoDamage(Damage);
		-----
		wait((PunchTrack.Length/Speed)/2);
		PunchTrack:Destroy();
	end
	----- MISC
	SequentialPunches += 1;
	SequentialPunches = SequentialPunches > #LPunchAnims and 1 or SequentialPunches; --- If SequentialPunches is greater than the lightpunch animations set it to 1, otherwise leave it the same
	Debounce = false;
	-----
end)
---------
