#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("apc");
	this.Tag("engine_can_get_stuck");
	this.Tag("ignore fall");
	this.Tag("radar");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    5500.0f, // move speed 125
	    1.1f,  // turn speed
	    Vec2f(0.0f, 0.56f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_AddAmmo(this, v,
        90, // fire delay (ticks)
        1, // fire bullets amount
        1, // fire cost
        "mat_arrows", // bullet ammo config name
        "Arrows", // name for ammo selection
        "arrow", // bullet config name
        "BowFire", // fire sound
        "EmptyFire" // empty fire sound
       );

	v.charge = 400;

	Vehicle_SetupGroundSound(this, v, "BTREngine",  // movement sound
		0.7f, // movement sound volume modifier   0.0f = no manipulation
		-0.3f); // movement sound pitch modifier     0.0f = no manipulation

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(15.5f, 10.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(14.0f, 10.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-0.5f, 10.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-2.0f, 10.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-15.5f, 10.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-17.0f, 10.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	this.getShape().SetOffset(Vec2f(0, 2));

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	bool facing_left = this.getTeamNum() == teamright;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);

	CSpriteLayer@ front = sprite.addSpriteLayer("radar", sprite.getConsts().filename, 48, 32);
	if (front !is null)
	{
		front.addAnimation("default", 0, true);
		int[] frames = {15,16,17,18,19,20,21,22};
		front.animation.AddFrames(frames);
		front.SetRelativeZ(-0.8f);
		front.SetOffset(Vec2f(-9.0f, -20.0f));
	}

	this.addCommandID("sync_charge");
	this.addCommandID("request_sync");
	this.addCommandID("client_input");

	u8 rnd = 2+XORRandom(2);
	this.set_u16("target_spot_timer_initial", rnd);
	this.set_u16("target_spot_timer", rnd);
	this.set_u16("step", 1);
	this.set_s32("charge", 0);
	this.set_s32("quiz_change", getGameTime() + default_quiz_time);

	setNewQuiz(this);

	if (isClient())
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("request_sync"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("client_input"))
	{
		bool is_correct = params.read_bool();

		if (is_correct)
		{
			if (isServer()) this.set_s32("charge", Maths::Min(this.get_s32("charge") + reward + XORRandom(reward_rnd), max_charge));
		}
		else
		{
			if (isServer())  this.set_s32("charge", Maths::Max(this.get_s32("charge") - reward, min_charge));
			if (isClient()) this.getSprite().PlaySound("NoAmmo.ogg", 0.5f, 1.0f);
		}

		SyncCharge(this);
	}
	else if (cmd == this.getCommandID("sync_charge"))
	{
		if (!isClient()) return;

		setNewQuiz(this);
		this.set_s32("charge", params.read_s32());

	}
	else if (cmd == this.getCommandID("request_sync"))
	{
		if (!isServer()) return;

		SyncCharge(this);
	}
}

const Vec2f _quiz_window_dim = Vec2f(200, 175);
const Vec2f _question_window_dim = Vec2f(200, 25);

const u16 max_charge = 5*30*60;
const s16 min_charge = -max_charge/2;
const u16 reward = 30*30;
const u16 reward_rnd = 16*30;
const u16 default_quiz_time = 10*30;
const u8 quiz_options = 6;

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	CPlayer@ local = getLocalPlayer();
	if (local is null) return;

	CBlob@ local_blob = local.getBlob();
	if (local_blob is null) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	CCamera@ camera = getCamera();
	if (camera is null) return;

	Vec2f pos = blob.getPosition();
	Vec2f oldpos = blob.getOldPosition();
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor()));

	GUI::SetFont("menu");

	if (local_blob.getTeamNum() == blob.getTeamNum() && (controls.getInterpMouseScreenPos() - pos2d).Length() < 64.0f * camera.targetDistance)
	{
		// remaining time
		s32 charge = blob.get_s32("charge");
		if (charge != 0)
		{
			string time = "Time: " + Maths::Floor(charge / 30 / 60) + "m " + Maths::Floor(charge / 30 % 60) + "s";
			GUI::DrawTextCentered(time, pos2d + Vec2f(0, 32), SColor(255, 255, 255, 255));
		}
	}

	if (!(local_blob.isAttachedTo(blob) && local_blob.isAttachedToPoint("DRIVER"))) return;

	Vec2f quiz_window_dim = Vec2f(200, 175);
	Vec2f question_window_dim = Vec2f(200, 25);
	Vec2f offset = Vec2f(0.0f, -156.0f);

	// outer border
	GUI::DrawPane(pos2d + offset - quiz_window_dim/2, pos2d + offset + quiz_window_dim/2, SColor(125,155,155,155));

	// canvas
	Vec2f canvas_extra = Vec2f(4, 4);
	GUI::DrawPane(pos2d + offset - quiz_window_dim/2 + canvas_extra, pos2d + offset + quiz_window_dim/2 - canvas_extra, SColor(125,0,0,0)); // inner border
	
	// quiz
	GUI::DrawText(blob.get_string("quiz"), pos2d + offset+Vec2f(8,0) - quiz_window_dim/2 + Vec2f(0, 10), SColor(255,255,255,255));

	Vec2f grid_start = pos2d + offset - quiz_window_dim/2 + Vec2f(0, _question_window_dim.y) + canvas_extra;
	Vec2f grid_dim = Vec2f(_question_window_dim.x, _quiz_window_dim.y - _question_window_dim.y) - canvas_extra*2; // remaining space for the grid
	u8 cols = 2;
	u8 rows = quiz_options / cols;
	Vec2f option_dim = Vec2f(grid_dim.x / cols, grid_dim.y / rows);

	string[] solutions;
	if (!blob.get("solutions", solutions))
	{
		string[] setter = {"Something", "went", "wrong", "wait", "for a", "hotfix"};
		solutions = setter;
	}

	bool disable_other = false;
	for (u8 i = 0; i < quiz_options; i++)
	{
		u8 col = i % cols;
		u8 row = i / cols;
		Vec2f option_pos = grid_start + Vec2f(col * option_dim.x, row * option_dim.y);

		if (!disable_other && mouseOn(blob, option_pos, option_dim, solutions[i]))
		{
			GUI::DrawPane(option_pos, option_pos + option_dim, SColor(125,255,255,255));
			disable_other = true;
		}
		else
		{
			GUI::DrawPane(option_pos, option_pos + option_dim, SColor(125,155,155,155));
		}

		GUI::DrawTextCentered(""+solutions[i], option_pos + option_dim/2, SColor(255,255,255,255));
	}

	// remaining quiz time
	s32 quiz_change = blob.get_s32("quiz_change");
	
	// remaining quiz time bar
	Vec2f bar_start = pos2d + offset + Vec2f(0,_question_window_dim.y) + Vec2f(-quiz_window_dim.x / 2 + 10, quiz_window_dim.y / 2 - 20);
	Vec2f bar_dim = Vec2f(quiz_window_dim.x - 20, 10);
	Vec2f bar_end = bar_start + bar_dim;

	GUI::DrawPane(bar_start, bar_end, SColor(125, 155, 155, 155));

	float progress = float(quiz_change - getGameTime()) / float(default_quiz_time);
	Vec2f progress_end = bar_start + Vec2f(bar_dim.x * progress, bar_dim.y);

	GUI::DrawPane(bar_start, progress_end, SColor(255, 0, 255, 0));
	
	mouseWasPressed1 = controls.mousePressed1;
}

bool mouseWasPressed1 = false;
bool mouseOn(CBlob@ blob, Vec2f pos, Vec2f dim, string text)
{
	CControls@ controls = getControls();
	if (controls is null) return false;
	
	Vec2f mouse = getControls().getMouseScreenPos();
	bool in_area = mouse.x > pos.x && mouse.x < pos.x + dim.x && mouse.y > pos.y && mouse.y < pos.y + dim.y;
	bool is_press = controls.mousePressed1;
	
	if (in_area)
	{
		if (blob !is null && is_press && !mouseWasPressed1)
		{
			CBitStream params;
			params.write_bool(text == ("" + blob.get_s32("result")));
			blob.SendCommand(blob.getCommandID("client_input"), params);

			blob.getSprite().PlaySound("menuclick.ogg");
		}
	}

	return in_area;
}

string generateQuiz(CBlob@ this, u8 difficulty)
{
	string[] operators = {"+", "-", "*"}; // divisor doesn't work well in this algo, investigate later
	u8 operations = 2 + difficulty;
	string quiz = "";
	array<int> numbers;
	array<string> ops;

	for (u8 i = 0; i < operations; i++)
	{
		u8 number = XORRandom(10) + 1;
		numbers.push_back(number);
		quiz += number;

		if (i < operations - 1)
		{
			string operator = operators[XORRandom(operators.length)];
			if (operator == "/")
			{
				while (numbers[i - 1] % numbers[i] != 0)
				{
					operator = operators[XORRandom(operators.length)];
					if (operator != "/")
					{
						break;
					}
					
					numbers[i] = getRandomFactor(numbers[i - 1]);
				}
			}
			ops.push_back(operator);
			quiz += " " + operator + " ";
		}
	}

	int result = evaluateExpression(numbers, ops);

	this.set_s32("result", result);
	this.set("solutions", generateSolutions(result, difficulty));

	return quiz + " = ? ";
}

string[] generateSolutions(int result, u8 difficulty)
{
	string[] solutions;

	for (u8 i = 0; i < quiz_options - 1; i++)
	{
		int solution = result + XORRandom(20) - 10;
		while (solution == result || solutions.find("" + solution) != -1)
		{
			solution = result + XORRandom(20) - 10;
		}
		solutions.push_back("" + solution);
	}

	solutions.insertAt(XORRandom(solutions.size()), "" + result);

	return solutions;
}

int getRandomFactor(int number) // doesnt return correct numbers
{
	array<int> factors;
	for (int i = 1; i <= number; i++)
	{
		if (number % i == 0)
		{
			factors.push_back(i);
		}
	}
	return factors[XORRandom(factors.size())];
}

int evaluateExpression(array<int> &numbers, array<string> &ops)
{
	array<int> numStack;
	array<string> opStack;

	for (u8 i = 0; i < numbers.size(); i++)
	{
		numStack.push_back(numbers[i]);

		if (i < ops.size())
		{
			string currentOp = ops[i];

			while (!opStack.isEmpty() && precedence(opStack[opStack.size() - 1]) >= precedence(currentOp))
			{
				int b = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
				int a = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
				string op = opStack[opStack.size() - 1]; opStack.removeAt(opStack.size() - 1);
				numStack.push_back(applyOperation(a, b, op));
			}

			opStack.push_back(currentOp);
		}
	}

	while (!opStack.isEmpty())
	{
		int b = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
		int a = numStack[numStack.size() - 1]; numStack.removeAt(numStack.size() - 1);
		string op = opStack[opStack.size() - 1]; opStack.removeAt(opStack.size() - 1);
		numStack.push_back(applyOperation(a, b, op));
	}

	return numStack[0];
}

int precedence(string op)
{
	if (op == "*" || op == "/") return 2;
	if (op == "+" || op == "-") return 1;
	return 0;
}

int applyOperation(int a, int b, string op)
{
	if (op == "+") return a + b;
	if (op == "-") return a - b;
	if (op == "*") return a * b;
	if (op == "/") return a / b;
	return 0;
}

void setNewQuiz(CBlob@ this)
{
	u8 difficulty = XORRandom(3);
	string new_condition = generateQuiz(this, difficulty);

	this.set_string("quiz", new_condition);
	this.set_s32("quiz_change", getGameTime() + default_quiz_time);
}

void SyncCharge(CBlob@ this)
{
	CBitStream params;
	params.write_s32(this.get_s32("charge"));
	this.SendCommand(this.getCommandID("sync_charge"), params);
}

void onTick(CBlob@ this)
{
	s32 charge = this.get_s32("charge");

	if (getNet().isClient())
	{
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ front = sprite.getSpriteLayer("radar");

		CBlob@ local_blob = getLocalPlayerBlob();
		if (front !is null)
		{
			bool is_active = front.animation.time != 0;
			front.animation.time = charge <= 0 ? 0 : charge > 30 ? 4 : 6 - Maths::Floor(charge/10);
			if (is_active && (getGameTime()+this.getNetworkID())%30 == 0)
			{
				f32 distance_factor = 1.0f;
				if (local_blob !is null) distance_factor = Maths::Max(1.0f - (local_blob.getPosition() - this.getPosition()).Length() / 256.0f, 0);
				
				f32 volume = 0.5f * distance_factor;
				#ifndef STAGING
				if (volume < 0.2f) volume = 0;
				#endif
				
				if (volume != 0) this.getSprite().PlaySound("radar_ping.ogg", volume, 0.8f+XORRandom(6)*0.001f);

				u8 rnd = 2+XORRandom(2);
				this.set_u16("target_spot_timer_initial", rnd);
				this.set_u16("target_spot_timer", rnd);
				this.set_u16("step", 1);
			}

			if (is_active)
			{
				u16 target_spot_timer_initial = this.get_u16("target_spot_timer_initial");
				u16 target_spot_timer = this.get_u16("target_spot_timer");
				u16 step = this.get_u16("step");

				if (target_spot_timer > 0) target_spot_timer--;
				else // pulse scan
				{
					CBlob@[] vehicles;
					getBlobsByTag("vehicle", @vehicles);

					CBlob@[] sorted_vehicles;
					for (u16 i = 0; i < vehicles.size(); i++)
					{
						CBlob@ vehicle = vehicles[i];
						if (vehicle is null) continue;
						if (vehicle.getTeamNum() == this.getTeamNum()
							|| vehicle.hasTag("turret") || vehicle.hasTag("machinegun")) continue;

						f32 distance = (vehicle.getPosition() - this.getPosition()).Length();
						bool inserted = false;

						for (u16 j = 0; j < sorted_vehicles.size(); j++)
						{
							if ((sorted_vehicles[j].getPosition() - this.getPosition()).Length() > distance)
							{
								sorted_vehicles.insertAt(j, vehicle);
								inserted = true;

								j = sorted_vehicles.size(); // break this loop
							}
						}

						if (!inserted)
						{
							sorted_vehicles.push_back(vehicle);
						}
					}

					for (u8 i = 0; i < sorted_vehicles.size(); i++)
					{
						CBlob@ target = sorted_vehicles[i];
						if (target is null) continue;
						
						u16 marked_time = getGameTime() + 3*30 + XORRandom(16)*0.1f*30;
						if (target.getName() == "radarapc")
						{
							this.set_u32("radar_mark", marked_time);
						}
						if (target.exists("radar_mark") && target.get_u32("radar_mark") > getGameTime())
						{
							target.set_u32("radar_mark", marked_time);
						}
						else
						{
							target.set_u32("radar_mark", marked_time);
							break;
						}
					}

					target_spot_timer = Maths::Pow(target_spot_timer_initial, step + 1);
					step += 1;
				}

				this.set_u16("target_spot_timer", target_spot_timer);
				this.set_u16("step", step);
			}
		}

		if (getGameTime() > this.get_s32("quiz_change"))
		{
			if (local_blob !is null && local_blob.isAttachedTo(this) && local_blob.isAttachedToPoint("DRIVER"))
				setNewQuiz(this);

			this.set_s32("quiz_change", getGameTime() + default_quiz_time);
		}
	}


	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		Vehicle_StandardControls(this, v);

		if (isServer() && this.isInWater())
		{
			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
			if (ap !is null && ap.getOccupied() is null && (getGameTime() + this.getNetworkID())%120 == 0)
			{
				if (isServer()) this.server_Hit(this, this.getPosition(), Vec2f(0,0), this.getInitialHealth()/(20+XORRandom(11)), Hitters::builder);
				
			}
		}
	}

	if (charge > 0) charge--;
	else if (charge < 0) charge++;
	this.set_s32("charge", charge);

	Vehicle_LevelOutInAir(this);
	if (!this.isOnWall()) Vehicle_DontRotateInWater(this);
	else if (this.getShape() !is null) this.getShape().SetRotationsAllowed(true);
}

// Blow up
void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("/vehicle_die");

	if (this.exists("bowid"))
	{
		CBlob@ bow = getBlobByNetworkID(this.get_u16("bowid"));
		if (bow !is null)
		{
			bow.server_Die();
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("boat"))
	{
		return true;
	}
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle"))
	{
		return true;
	}

	if (blob.hasTag("flesh") && !blob.isAttached())
	{
		return true;
	}
	else
	{
		return Vehicle_doesCollideWithBlob_ground(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player")) attached.Tag("covered");
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	attachedPoint.offsetZ = 1.0f;
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.Untag("covered");
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 0.75f;
	}

	if (customData == HittersAW::bullet)
		return damage * 0.25f;
	if (customData == HittersAW::aircraftbullet)
		return damage * 2.0f;
		
	return damage;
}