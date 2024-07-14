void Setup(CBlob@ this)
{
	Vehicle_Setup(this,
	    0.0f, // move speed
	    0.25f,  // turn speed
	    Vec2f(0.0f, -2.5f), // jump out velocity
	    true);  // inventory access
}

void LoadStats(CBlob@ this)
{
	TurretStats stats;

    switch (this.getName().getHash())
    {
        case _m60turret:
        {
            M60Turret override_stats;
	        stats = override_stats;
            break;
        }
		case _leopard1turret:
		{
			Leopard1Turret override_stats;
			stats = override_stats;
			break;
		}
		case _t10turret:
		{
			T10Turret override_stats;
			stats = override_stats;
			break;
		}
		case _pszh4turret:
		{
			PSZH4Turret override_stats;
			stats = override_stats;
			break;
		}
		case _btrturret:
		{
			BTRTurret override_stats;
			stats = override_stats;
			break;
		}
		case _bradleyturret:
		{
			BradleyTurret override_stats;
			stats = override_stats;
			break;
		}
		case _artilleryturret:
		{
			ArtilleryTurret override_stats;
			stats = override_stats;
			break;
		}
		case _gradturret:
		{
			GradTurret override_stats;
			stats = override_stats;
			break;
		}
		case _mausturret:
		case _desertmausturret:
		case _pinkmausturret:
		{
			MausTurret override_stats;
			stats = override_stats;
			break;
		}
		case _bc25turret:
		{
			BC25Turret override_stats;
			stats = override_stats;
			break;
		}
		case _m103turret:
		{
			M103Turret override_stats;
			stats = override_stats;
			break;
		}
		case _is7turret:
		{
			IS7Turret override_stats;
			stats = override_stats;
			break;
		}
    }

	if (stats.fixed)
		this.Tag("no turn");

	this.set("TurretStats", @stats);
}

void InitGun(CBlob@ this, TurretStats@ stats, VehicleInfo@ v)
{
    u8 h_a = stats.high_angle;
	u8 l_a = stats.low_angle;
	u8 l_a_b = stats.low_angle_back;
	this.set_u8("init_high_angle", h_a);
	this.set_u8("init_low_angle", l_a);
	this.set_u8("init_low_angle_back", l_a_b);
	this.set_u8("high_angle", h_a);
	this.set_u8("low_angle", l_a);
	this.set_u8("low_angle_back", l_a_b);

	this.set_u8("cassette_size", stats.cassette_size);

	Vehicle_AddAmmo(this, v,
	    stats.cooldown_time, // fire delay (ticks)
	    1, // fire bullets amount
	    1, // fire cost
	    stats.ammo, // bullet ammo config name
	    stats.ammo_description, // name for ammo selection
	    stats.projectile, // bullet config name
	    //"sound_100mm", // fire sound
		stats.fire_sound,
	    "EmptyFire", // empty fire sound
	    Vehicle_Fire_Style::custom,
	    Vec2f_zero, // fire position offset
	    1); // charge time

	v.cassette_size = stats.cassette_size;
	v.origin_cooldown = stats.cooldown_time;

	Vehicle_SetWeaponAngle(this, l_a, v);
}

void CreateMachineGun(CBlob@ this, TurretStats@ stats)
{
	if (getNet().isServer())
	{
		CBlob@ bow = server_CreateBlob(stats.mg);	

		if (bow !is null)
		{
			bow.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo(bow, "BOW");
			this.set_u16("bowid", bow.getNetworkID());

			bow.SetFacingLeft(this.isFacingLeft());
		}
	}
}

void Restock(CBlob@ this, TurretStats@ stats, u16 quantity)
{
	if (!isServer()) return;
	
    CBlob@ ammo = server_CreateBlob(stats.ammo);
	if (ammo !is null)
	{
		if (quantity != 0) ammo.server_SetQuantity(quantity);

		if (!this.server_PutInInventory(ammo))
			ammo.server_Die();
	}
}

void CalculateCooldown(CBlob@ this, TurretStats@ stats, VehicleInfo@ v, const u8 _charge)
{
	v.last_charge = _charge;
	v.charge = 0;

	if (v.fired_amount < stats.cassette_size)
	{
		v.getCurrentAmmo().fire_delay = stats.cycle_cooldown;
		v.cooldown_time = stats.cycle_cooldown;
		v.fire_time = 0;
	}
	else
	{
		v.getCurrentAmmo().fire_delay = stats.cooldown_time;
		v.cooldown_time = stats.cooldown_time;
		v.fired_amount = 0;
	}

	this.set_u32("fired_amount", v.fired_amount);
}

void ManageMG(CBlob@ this, bool fl)
{
	if (!isServer()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW");
	if (point !is null && point.getOccupied() !is null)
	{
		CBlob@ mg = point.getOccupied();
		mg.SetFacingLeft(fl);
	}
}

void ArtilleryFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge, Vec2f bullet_pos)
{
	TurretStats@ stats;
    if (!this.get("TurretStats", @stats)) return;

	this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);
	if (bullet !is null)
	{
		Vec2f pos = this.getPosition();
        bool fl = this.isFacingLeft();
        s8 ff = fl ? -1 : 1;

        f32 deg = this.getAngleDegrees();
		f32 angle = this.get_f32("gunelevation") + deg;
		Vec2f vel = Vec2f(0.0f, stats.projectile_vel+XORRandom(16)*0.1f).RotateBy(angle);
		
		bullet.setVelocity(vel);
		bullet.setPosition(bullet_pos);

		bullet.set_f32("proj_ex_radius", 96.0f);
		bullet.Tag("rpg"); // effects
		bullet.Tag("artillery"); // shrapnel

		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null)
		{
			CBlob@ b = gunner.getOccupied();
			if (b.getPlayer() !is null)
			{
				bullet.set_u16("ownerplayer_id", b.getPlayer().getNetworkID());
				bullet.set_u16("ownerblob_id", b.getNetworkID());
				b.Tag("camera_offset");
				bullet.server_SetPlayer(b.getPlayer());
			}
		}

		bullet.AddScript("ShrapnelOnDie.as");
		bullet.set_u8("shrapnel_count", 10+XORRandom(7));
		bullet.set_f32("shrapnel_vel", 9.0f+XORRandom(5)*0.1f);
		bullet.set_f32("shrapnel_vel_random", 1.5f+XORRandom(16)*0.1f);
		bullet.set_Vec2f("shrapnel_offset", Vec2f(0,-1));
		bullet.set_f32("shrapnel_angle_deviation", 10.0f);
		bullet.set_f32("shrapnel_angle_max", 45.0f+XORRandom(21));

		CBlob@ hull = getBlobByNetworkID(this.get_u16("tankid"));

		bool not_found = true;

		if (hull !is null)
		{
			hull.AddForce(Vec2f(this.isFacingLeft() ? stats.recoil_force : -stats.recoil_force, 0.0f));
		}

		if (isClient())
		{
			CShape@ shape = this.getShape();
			Vec2f shape_vel = shape.getVelocity();

			bool facing = this.isFacingLeft();
			for (f32 i = 0; i < 16; i++)
			{
				ParticleAnimated("LargeSmokeGray", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(10+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2 + XORRandom(2), -0.0031f, true);
				//ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 6 + XORRandom(3), -0.0031f, true);
			}

			for (f32 i = 0; i < 6; i++)
			{
				float angle = Maths::ATan2(vel.y, vel.x) + 20;
				ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle2 = Maths::ATan2(vel.y, vel.x) - 20;
				ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle3 = Maths::ATan2(vel.y, vel.x) + 10;
				ParticleAnimated("LargeSmokeGray", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle4 = Maths::ATan2(vel.y, vel.x) - 10;
				ParticleAnimated("LargeSmokeGray", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);

				ParticleAnimated("LargeSmokeGray", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 10 + XORRandom(3), -0.0031f, true);
				ParticleAnimated("Explosion", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.0065f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 2, -0.0031f, true);
			}
		}
	}

	CalculateCooldown(this, stats, v, _charge);
}

void GradFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge, Vec2f bullet_pos)
{
	TurretStats@ stats;
    if (!this.get("TurretStats", @stats)) return;

	this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);
	if (bullet !is null)
	{
		Vec2f pos = this.getPosition();
        bool fl = this.isFacingLeft();
        s8 ff = fl ? -1 : 1;

        f32 deg = this.getAngleDegrees();
		f32 angle = this.get_f32("gunelevation") + deg;
		Vec2f vel = Vec2f(0.0f, stats.projectile_vel+XORRandom(11)*0.1f).RotateBy(angle);

		bullet.setVelocity(vel);
		bullet.setPosition(bullet_pos);

		bullet.set_f32("map_damage_radius", 8);
		bullet.set_f32("proj_ex_radius", 32.0f);
		bullet.Tag("rpg");
		bullet.Tag("artillery");

		CBlob@ hull = getBlobByNetworkID(this.get_u16("tankid"));
		bool not_found = true;

		if (hull !is null)
		{
			hull.AddForce(Vec2f(this.isFacingLeft() ? stats.recoil_force : -stats.recoil_force, 0.0f));
		}

		if (isClient())
		{
			bool facing = fl;
			CShape@ shape = this.getShape();
			Vec2f shape_vel = shape.getVelocity();

			for (int i = 0; i < 4; i++)
			{
				float angle = Maths::ATan2(vel.y, vel.x) + 20;
				ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.4f + XORRandom(40) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle2 = Maths::ATan2(vel.y, vel.x) - 20;
				ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.4f + XORRandom(40) * 0.01f, 4 + XORRandom(3), -0.0031f, true);

				ParticleAnimated("Explosion", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2, -0.0031f, true);
			}
		}

		makeGibParticle(
		"EmptyShell",               		// file name
		this.getPosition(),                 // position
		(Vec2f(0.0f,-0.5f) + getRandomVelocity(90, 2, 360)), // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		0.5f,                               // scale?
		0,                                  // ?
		"ShellCasing",                      // sound
		this.get_u8("team_color"));         // team number
	}	

	CalculateCooldown(this, stats, v, _charge);
}