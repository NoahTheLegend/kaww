
void onInit(CBlob@ this)
{
  if (getNet().isServer())
  {
    this.set_u8("decay step", 10);
  }

  this.maxQuantity = 100;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
