#include "CustomBlocks.as";

const f32 max_distance = 512.0f;

void onInit(CBlob@ this)
{
	this.SetLight(false);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(155, 255, 230, 180));

	this.addCommandID("toggle_light");
	this.set_bool("enabled", false);

	makeLight(this);
}

void makeLight(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ blob = server_CreateBlobNoInit("projector_light");
		if (blob is null) return;

		blob.setPosition(this.getPosition());
		blob.Init();

		blob.set_u16("remote_id", this.getNetworkID());
		this.set_u16("remote_id", blob.getNetworkID());
	}
}

void onTick(CBlob@ this)
{
	this.SetLight(this.get_bool("enabled"));

	if (isServer())
	{
		if (this.getVelocity() != Vec2f_zero || this.isAttached()) //only tick if moving 
		{
			bool flip = this.isFacingLeft();
			f32 angle = this.getAngleDegrees();
			f32 aim_distance = max_distance;

			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
			CBlob@ holder = point.getOccupied();
			if (holder !is null)
			{
				aim_distance = Maths::Abs((holder.getAimPos() - this.getPosition()).Length());
				angle = getAimAngle(this, holder);
				this.setAngleDegrees(angle);
			}

			Vec2f hitPos;
			Vec2f dir = Vec2f((this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
			Vec2f startPos = this.getPosition();
			Vec2f endPos = startPos + dir * aim_distance;

			HitInfo@[] hitInfos;
			bool mapHit = getMap().rayCastSolid(startPos, endPos, hitPos);
			f32 length = (hitPos - startPos).Length();
			bool blobHit = getMap().getHitInfosFromRay(startPos, angle, length, this, @hitInfos);
			
			int exceed = 25;
			int tries = 0;

			while (mapHit && tries < exceed)
			{
				tries++;

				Tile tile = getMap().getTile(hitPos);
				break;
			}

			Vec2f finalPos = mapHit ? hitPos : endPos;
			if (mapHit && (hitPos - startPos).Length() < aim_distance)
			{
				finalPos = hitPos;
			}

			CBlob@ light = getBlobByNetworkID(this.get_u16("remote_id"));
			if (light !is null)
			{
				light.setPosition(Vec2f_lerp(light.getPosition(), finalPos, 0.33f));
			}
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	onDie(this);
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	makeLight(this);
}

void onDie(CBlob@ this)
{
	if (!isServer()) return;
	CBlob@ light = getBlobByNetworkID(this.get_u16("remote_id"));
	if (light !is null) light.server_Die();
}

f32 getAimAngle(CBlob@ this, CBlob@ holder)
{
	Vec2f aimvector = holder.getAimPos() - (this.hasTag("place45") /*&& this.hasTag("a1"))*/ ? holder.getInterpolatedPosition() : this.getInterpolatedPosition());
	f32 angle = holder.isFacingLeft() ? -aimvector.Angle() + 180.0f : -aimvector.Angle();
	if (holder.isAttached()) this.SetFacingLeft(holder.isFacingLeft());
	return angle;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.isAttachedTo(caller)) return;
	bool enabled = this.get_bool("enabled");

	CBitStream params;
	caller.CreateGenericButton(enabled ? 27 : 23, Vec2f_zero, this, this.getCommandID("toggle_light"), "Toggle Light", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("toggle_light"))
	{
		bool lightState = this.get_bool("enabled");
		
		this.set_bool("enabled", !lightState);
		this.SetLight(!lightState);
	}
}