void onInit(CBlob@ this)
{
  this.Tag("material");
  if (getNet().isServer())
  {
    this.set_u8("decay step", 1);
  }

  this.maxQuantity = 250;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}