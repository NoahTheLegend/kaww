void onTick(CRules@ this)
{
	this.set_f32("RenderTime", 0);
}

void onRender(CRules@ this)
{
	this.add_f32("RenderTime", getRenderApproximateCorrectionFactor());
}