
void onInit(CBlob@ this)
{
  if (getNet().isServer())
  {
    this.set_u8("decay step", 2);
  }

  this.Tag("heavy weight");
  this.maxQuantity = 12;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
