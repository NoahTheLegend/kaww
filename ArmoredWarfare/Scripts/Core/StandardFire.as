
//  StandardFire.as - Vamist

#include "GunStandard.as";
 
void gunInit(CBlob@ this) 
{
	//Set vars
	setGunVars(this);
}

void setGunVars(CBlob@ this)
{
	if (this is null || this.hasTag("dead")) return;
	InfantryInfo@ infantry;
	if (!this.get("infantryInfo", @infantry )) return;
	
	this.set_u8("TTL",					infantry.bullet_lifetime);
	this.set_u8("speed",				infantry.bullet_velocity);
	this.set_Vec2f("KB",				Vec2f_zero); // maybe add this later?
	this.set_Vec2f("grav",				Vec2f(0, 0.001f));
}