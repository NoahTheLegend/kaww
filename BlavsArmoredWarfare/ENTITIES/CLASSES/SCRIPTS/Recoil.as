void Recoil(CBlob@ this, CBlob@ holder, f32 myrecoil, s8 recoildirection)
{
	CControls@ controls = this.getControls();

	if (isFullscreen())
	{
		//controls.setMousePosition(controls.getMouseScreenPos() + Vec2f(recoildirection * myrecoil * sidewaysrecoil, -myrecoil*5.5));
	}
	else
	{
		//controls.setMousePosition(controls.getMouseScreenPos() + Vec2f(recoildirection * myrecoil * sidewaysrecoil, -myrecoil*5.5) + Vec2f(5, 5));
	}
	
}