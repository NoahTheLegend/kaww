#define CLIENT_ONLY

u32 FREQ = 5*60*30;

bool show_message = true;
u32 wait = 200;

const string[] textsTips = 
{ 
	"If you are new, stick to an easy class like ranger.",

	"In order you shoot small arms, you must be standing on the ground or on a ladder.",
	"You cannont jump when shooting your gun.",
	"Hold right click to reduce the LMG's recoil.",
	"You automatically heal allies standing next to you as a medic.",
	"The ranger class has great DPS if you can control the recoil spray.",
	"The crewman class is tough and quick; very good for being inside a vehicle.",
	"Snipers can 1 shot all classes except for crewman, unless they are protected in a vehicle or have a helmet.",

	"Gold can be spent to construct useful buildings at a vacant construction yard.",
	"Gold is valuable, keep it safe.",
	"Bunkers will heavily damage vehicles that ram into them.",
	"Build a repair station to repair any type of vehicle.",

	"You can build armories at construction yards to gain access to new classes.",

	"For small arms: the farther to the edge of the screen you aim, the more accurate your shoots will be, but you will have more recoil.",
	"You can swap between nearby seats in a vehicle thats not moving by quickly pressing W then S.",

	"Heat warheads are limited, use them wisely.",
	"The anti-tank class uses heat warheads as ammo.",
	"Rocket lauchers use heat warheads as ammo.",

	"You can refill vehicles or guns with more ammo if you have the correct type.",

	"New vehicles will spawn at your Spawn Truck when old ones are destroyed.",
	"Destroyed tanks will drop their main gun ammo.",

	"Without protection, you will die quickly by enemy vehicles.",
	"Tanks will completely block any small arms fire.",
	"Stand behind tanks for protection.",
	"You will take reduced damage when sitting in a vehicle.",
	"Work as a team with your tank crew to be successful.",
	"A full tank crew is like a pinata for the enemy team, so drive carefully.",

	"Knifes are extremely powerful in close quarters combat.",
	"As an infantryman, you can hide in bushes for a potential ambush.",
	"If your vehicle is stuck, switch to slave and dig it out if you can.",

	"You can avoid being rammed by vehicles by crouching on the ground.",

	"Win the round by either killing all enemy players, or destroying their Spawn Truck.",
	"If the timer runs out, the team with the most kills will win.",
	"Driving your Spawn Truck too close to the enemy team can prove fatal for your team.",
	"Keep your Spawn Truck safe at all costs."
};


void onTick(CRules@ this)
{
	/*
	if ( getGameTime() % FREQ == 0 && textsTips.length > 0 )
	{
		client_AddToChat( "* Tip: " + textsTips[XORRandom(textsTips.length)], SColor(255, 220, 120, 40));
	}

	if (!show_message) return;

	if (wait > 0)
	{
		wait--;
	}
	else
	{
		CPlayer@ localPlayer = getLocalPlayer();
		if (localPlayer is null) return;

		client_AddToChat("* Welcome to King Arthur's Wooden Warfare!", SColor(255, 220, 120, 40));
		show_message = false;
	}
	*/
}