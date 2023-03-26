void onInit(CBlob@ this)
{
  this.Tag("heavy weight");
  this.Tag("special");

  if (getNet().isServer())
  {
    this.set_u8('decay step', 2);
  }

  this.maxQuantity = 3;

  this.getCurrentScript().runFlags |= Script::remove_after_this;
}
