void onInit(CBlob@ this)
{
  this.Tag("medium weight");

  if (getNet().isServer())
  {
    this.set_u8('decay step', 1);
  }

  this.maxQuantity = 4;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
