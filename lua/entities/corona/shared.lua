ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName		= "Corona"
ENT.Author			= "Jordan"
ENT.Contact			= "https://steamcommunity.com/id/jordiebg/"
ENT.Purpose			= "Malicious intent."
ENT.Instructions	= "The entity used by the Corona virus. Do not spawn this since it won't do anything unless it's issued by the swep."

if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		timer.Simple( 1, function( )
			if ( IsValid( self ) ) then
				SafeRemoveEntity( self )
			end
		end )
	end
else
	killicon.AddAlias( "corona", "default" )
	function ENT:Draw( flags )
		return false
	end
end
