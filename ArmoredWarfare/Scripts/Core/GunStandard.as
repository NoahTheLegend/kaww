
void shootGun(const u16 hoomanID, const f32 aimangle, const Vec2f pos, const Vec2f aimpos,
	const f32 bulletSpread, const u8 burst_size, const s8 type) 
{
	CRules@ rules = getRules();
	CBitStream params;

	params.write_netid(hoomanID);
	params.write_f32(aimangle);
	params.write_Vec2f(pos);
	params.write_Vec2f(aimpos);
	params.write_f32(bulletSpread);
	params.write_u8(burst_size);
	params.write_s8(type);
	params.write_u32(getGameTime());

	rules.SendCommand(rules.getCommandID("fireGun"), params);
}

void shootVehicleGun(const u16 hoomanID, const u16 gunID, const f32 aimangle, const Vec2f pos, const Vec2f aimpos,
	const f32 bulletSpread, const u8 burst_size, const s8 type, const f32 damage, const f32 head_damage, const s8 pen,
	const u8 TTL, const u8 speed, const s32 hitter)
{
	CRules@ rules = getRules();
	CBitStream params;

	params.write_netid(hoomanID);
	params.write_netid(gunID);
	params.write_f32(aimangle);
	params.write_Vec2f(pos);
	params.write_Vec2f(aimpos);
	params.write_f32(bulletSpread);
	params.write_u8(burst_size);
	params.write_s8(type);
	params.write_f32(damage);
	params.write_f32(head_damage);
	params.write_s8(pen);
	params.write_u8(TTL);
	params.write_u8(speed);
	params.write_s32(hitter);
	params.write_u32(getGameTime());

	rules.SendCommand(rules.getCommandID("fireVehicleGun"), params);
}