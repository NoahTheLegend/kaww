#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(-50); //background

	//INIT COSTS
	InitCosts();

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(16, 4));
	this.set_string("shop description", "Construct a Vehicle");
	this.set_u8("shop icon", 15);

	this.Tag("ignore_arrow");
	this.Tag("builder always hit");

	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Bradley M2", "$bradley$", "bradley", "Light but armed with medium cannon APC.\nAlso has a javelin on the turret.\n\nExcellent engine power, fast, good elevation angles\nWeak armor\n\nUses 105mm and optionally HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 45);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 65);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Maus", "$maus$", "maus", "Super heavy tank.\n\nThick armor, best turret armor, big cannon damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 110);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Bomber Plane", "$bomberplane$", "bomberplane", "A bomber plane.\nUses bomber bombs.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 60);
	}
	{
		ShopItem@ s = addShopItem(this, "Build UH1 Helicoptrer", "$uh1$", "uh1", "A helicopter with heavy machinegun.\nPress SPACEBAR to launch HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy MachineGun", "$crate$", "heavygun", "Heavy MachineGun.\nOpen nearby a tank to attach on its turret.\n\nUses 7.62mm.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$crate$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 18);
	}
	/*
	{
		ShopItem@ s = addShopItem(this, "Gutseeker Launcher", "$crate$", "launcher_gutseeker", "Cluster Missile launcher.\n\nSingle use.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	*/
}

void onTick(CBlob@ this)
{
	if (getGameTime() % 51 == 0 && XORRandom(5) == 0)
	{
		for (uint i = 0; i < 4; i ++)
		{
			Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

			velr *= 0.4f;

			ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("projectile") && blob.getTeamNum() != this.getTeamNum())
		return true;
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum()) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/UpgradeT2.ogg" );
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ item = getBlobByNetworkID(params.read_netid());
		if (item !is null && caller !is null)
		{
			if (item.getName() == "maus" && caller.getPlayer() !is null && caller.getPlayer().getSex() == 1)
			{
				CBitStream params;
				params.write_bool(true);
				item.SendCommand(item.getCommandID("sync_color"), params);
			}
		}
	}
}