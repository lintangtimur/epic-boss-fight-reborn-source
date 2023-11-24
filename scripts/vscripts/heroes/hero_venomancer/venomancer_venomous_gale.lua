venomancer_venomous_gale = class({})

function venomancer_venomous_gale:OnSpellStart()
	self.speed = self:GetSpecialValueFor( "speed" )
	self.width = self:GetSpecialValueFor( "radius" )
	self.distance = self:GetTrueCastRange()

	EmitSoundOn( "Hero_Venomancer.VenomousGale", self:GetCaster() )

	local vPos = nil
	if self:GetCursorTarget() then
		vPos = self:GetCursorTarget():GetOrigin()
	else
		vPos = self:GetCursorPosition()
	end

	local vDirection = vPos - self:GetCaster():GetOrigin()
	vDirection.z = 0.0
	vDirection = vDirection:Normalized()
	
	local info = {
		EffectName = "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
		Ability = self,
		vSpawnOrigin = self:GetCaster():GetOrigin(), 
		fStartRadius = self.width,
		fEndRadius = self.width,
		vVelocity = vDirection * self.speed,
		fDistance = self.distance,
		Source = self:GetCaster(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	}

	ProjectileManager:CreateLinearProjectile( info )
end

--------------------------------------------------------------------------------

function venomancer_venomous_gale:OnProjectileHit( hTarget, vLocation )
	if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) and not hTarget:TriggerSpellAbsorb( self ) then
		local caster = self:GetCaster()
		hTarget:AddNewModifier(self:GetCaster(), self, "modifier_venomancer_venomous_gale_cancer", {duration = self:GetSpecialValueFor("duration")})
		EmitSoundOn( "Hero_Venomancer.VenomousGaleImpact", hTarget )
		
		local vDirection = vLocation - self:GetCaster():GetOrigin()
		vDirection.z = 0.0
		vDirection = vDirection:Normalized()
		
		local damage = self:GetSpecialValueFor("strike_damage")
		if caster:IsRealHero( ) and self:GetSpecialValueFor("create_wards") > 0 and hTarget:IsConsideredHero() then
			local ward = caster:FindAbilityByName("venomancer_plague_ward")
			if ward and ward:IsTrained() then
				for i = 1, self:GetSpecialValueFor("create_wards") do
					local position  = hTarget:GetAbsOrigin() + RandomVector(250)
					caster:SetCursorPosition( position )
					ward:OnSpellStart( )
				end
			end
		end
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_venomous_gale_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
		ParticleManager:SetParticleControlForward( nFXIndex, 1, vDirection )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
		
		self:DealDamage( caster, hTarget, damage )
	end
	return false
end

LinkLuaModifier( "modifier_venomancer_venomous_gale_cancer", "heroes/hero_venomancer/venomancer_venomous_gale", LUA_MODIFIER_MOTION_NONE )
modifier_venomancer_venomous_gale_cancer = class({})

function modifier_venomancer_venomous_gale_cancer:OnCreated()
	self:OnRefresh()
	self:StartIntervalThink( self.tick )
end

function modifier_venomancer_venomous_gale_cancer:OnRefresh()
	self.tick = self:GetSpecialValueFor("tick_interval")
	self.movespeed = self:GetAbility():GetSpecialValueFor("movement_slow")
	self.msReduction = self.tick * self.movespeed / self:GetRemainingTime()
	self.tick_damage = self:GetAbility():GetSpecialValueFor("tick_damage")
end

function modifier_venomancer_venomous_gale_cancer:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		if caster:IsRealHero( ) and caster:HasScepter( ) and parent:IsConsideredHero() then
			self.nova = self:GetCaster():FindAbilityByName("venomancer_poison_nova")
			if self.nova then
				self.nova:PoisonNova( parent )
			end
		end
	end
end

function modifier_venomancer_venomous_gale_cancer:OnIntervalThink()
	self.movespeed = math.min( self.movespeed - self.msReduction, 0 )
	if IsServer() then 
		local caster = self:GetCaster()
		local damage = self.tick_damage
		self:GetAbility():DealDamage( caster, self:GetParent(), damage )
	end
end

function modifier_venomancer_venomous_gale_cancer:DeclareFunctions()
	funcs = {
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
			}
	return funcs
end

function modifier_venomancer_venomous_gale_cancer:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed
end

function modifier_venomancer_venomous_gale_cancer:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_venomancer_venomous_gale_cancer:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_gale_poison_debuff.vpcf"
end