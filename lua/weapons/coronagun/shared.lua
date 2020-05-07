if ( SERVER ) then
	AddCSLuaFile("shared.lua")
end

if ( CLIENT ) then
	SWEP.PrintName = "COVID-19"
	SWEP.Slot = 1
	SWEP.SlotPos = 9
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "JordieBG"
SWEP.Instructions = "Left click to infect player with COVID-19."
SWEP.Contact = "/id/JordieBG"
SWEP.Purpose = "Unleash a deadly plague. Player interaction increases infectivity rate drastically."

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix	 = "pistol"
SWEP.UseHands = true
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.Sound = Sound( "Weapon_USP.SilencedShot ")
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Damage = 1
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.02
SWEP.Primary.Delay = 0.5

SWEP.Category = "COVID-19"
SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 5
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"

----------------------------------------------------------------------------------
-- PLAYER META, INFECTION PROCESS AND EFFECTS. DO NOT TOUCH UNLESS YOU KNOW LUA.
----------------------------------------------------------------------------------

if (SERVER) then

local meta = FindMetaTable( "Player" )
CHAT_PLAYER_ME = 3

function ClampWorldVector(vec)
	vec.x = math.Clamp( vec.x , -16380, 16380 )
	vec.y = math.Clamp( vec.y , -16380, 16380 )
	vec.z = math.Clamp( vec.z , -16380, 16380 )
	return vec
end

function util.CreateSmokeClouds( effectData, pos, destructTime )
	local smokeEffect = ents.Create( "env_smoketrail" )
	smokeEffect:SetKeyValue( "startsize", effectData.startSize or "130" )
	smokeEffect:SetKeyValue( "endsize", effectData.endSize or "30" )
	smokeEffect:SetKeyValue( "spawnradius", effectData.spawnRadius or "70" )
	smokeEffect:SetKeyValue( "minspeed", effectData.minSpeed or "0.1" )
	smokeEffect:SetKeyValue( "maxspeed", effectData.maxSpeed or "1" )
	smokeEffect:SetKeyValue( "startcolor", effectData.startColor or "255 255 255" )
	smokeEffect:SetKeyValue( "endcolor", effectData.endColor or "0 0 0" )
	smokeEffect:SetKeyValue( "opacity", effectData.opacity or "1" )
	smokeEffect:SetKeyValue( "spawnrate", effectData.spawnRate or "10" )
	smokeEffect:SetKeyValue( "lifetime", effectData.lifeTime or "4" )
	smokeEffect:SetPos( pos )
	smokeEffect:Spawn( )
	timer.Simple( destructTime or 0.1, function( )
		smokeEffect:Fire( "kill", "", 1 )
	end )
end

function meta:InfectPlayer( ply, shouldSpread, spreadChance )
	if ( ply:GetObserverMode( ) ~= OBS_MODE_NONE ) then return end
	local entIndex = ply:EntIndex( )
	local patientZero = self
	local chance = spreadChance or 90
	if ( timer.Exists( entIndex .. ":InfectedTimer" ) ) then return end
	--ply:SayMessage( "begins to feel rather ill." )
	timer.Create( entIndex .. ":InfectedTimer", 10, 6, function( )
		if ( !IsValid( ply ) or !IsValid( self ) or !ply:Alive( ) ) then
			timer.Destroy( entIndex .. ":InfectedTimer" )
			return
		end
		local poisonDamage = math.random( 5, 40 )
		local coronaEnt = ents.Create( "corona" )
		coronaEnt:SetPos( Vector( 0, 0, 0 ) )
		coronaEnt:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		coronaEnt:SetNoDraw( true )
		coronaEnt:Spawn( )
		if ( IsValid( patientZero ) ) then
			ply:TakeDamage( poisonDamage, patientZero, coronaEnt )
		else
			ply:TakeDamage( poisonDamage, nil, coronaEnt )
		end
		SafeRemoveEntity( coronaEnt )
		ply:SetVelocity( Vector( 0, 35, 0 ) )
		ply:EmitSound( "ambient/voices/cough" .. math.random(1, 4) .. ".wav", 100, 100 )
		local effectData = { startColor = "45 160 45", endColor = "25 100 45", lifeTime = "1", startSize = "20",
		endSize = "8", startSpeed = "1.5", endSpeed = "0.5", spawnRate = "10", spawnRadius = "15" }
	    util.CreateSmokeClouds( effectData, ply:EyePos( ), 0.1 )
		-- if not ( shouldSpread ) then return end
		local nearbyEnts = ents.FindInBox( ClampWorldVector( ply:GetPos( ) - Vector( 256, 256, 256 ) ), ClampWorldVector( ply:GetPos( ) + Vector( 256, 256, 256 ) ) )
		for index, ent in ipairs ( nearbyEnts ) do
			if ( ply == ent ) then continue end
			if ( IsValid( ent ) and ent:IsPlayer( ) and ent:Alive( ) and ent:GetObserverMode( ) == OBS_MODE_NONE and !ent.isMarkedAFK  ) then
				local chanceToSpread = math.random( 30, 100 )
				if not ( chanceToSpread < chance ) then continue end
				if ( IsValid( patientZero ) ) then
					patientZero:InfectPlayer( ent, shouldSpread, chance )
				end
			end
		end
	end )
end

function meta:CureInfection( )
	timer.Destroy( self:EntIndex( ) .. ":InfectedTimer" )
end

function CrowningMoment(victim)
	victim:CureInfection()
end
hook.Add( "PlayerDeath", "Corona_Uncrowning", CrowningMoment)

end

----------------------------------------------------------------------------------
-- MAIN SWEP SETTINGS, SOUND AND CRAPPY AIMING MECHANIC.
----------------------------------------------------------------------------------

function SWEP:Initialize()
	self:SetHoldType( "pistol" )
	util.PrecacheSound( "ambient/voices/cough1.wav" )
	util.PrecacheSound( "ambient/voices/cough2.wav" )
	util.PrecacheSound( "ambient/voices/cough3.wav" )
	util.PrecacheSound( "ambient/voices/cough4.wav" )
end

function SWEP:Deploy()
	self:SetHoldType( "pistol" )
	return true
end

function SWEP:Holster( )
	return true
end

function SWEP:Reload()
	self.Weapon:DefaultReload( ACT_VM_RELOAD )
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not self:CanPrimaryAttack() then return end

	self.Weapon:EmitSound(self.Primary.Sound)

	local bullet = {}
	bullet.Num = 1
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = Vector(0.1, 0.1, 0)
	bullet.Tracer = 1
	bullet.Force = 5
	bullet.Damage = self.Primary.Damage
	bullet.Callback = function(atk, tr, dmg)
		if ( SERVER and IsValid( tr.Entity ) and tr.Entity:IsPlayer( ) ) then
			self.Owner:InfectPlayer( tr.Entity )
		end
	end
	self.Owner:FireBullets(bullet)
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	self:TakePrimaryAmmo(1)

	self.Owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0))
end

function SWEP:SecondaryAttack()
end
