
void onInit(CBlob@ this)
{
  if (getNet().isServer())
  {
    this.set_u8("decay step", 3);
  }

  this.maxQuantity = 50;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
