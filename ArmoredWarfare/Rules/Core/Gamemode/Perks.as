shared class PerkStats {
    string name;
    u8 id;
    // MOD - base value is multiplied by N, % - base value is multiplied by N-1.0f
    // Camouflage
    bool ghillie;
    bool climbtree;
    f32 fire_in_damage;     // mod
    u8 ignite_self_chance; // %

    // Sharp Shooter
    f32 reload_time;        // mod, also used by Bull
    f32 accuracy;           // mod
    f32 additional_vision_distance; // value 
    f32 damage_body;        // mod
    f32 damage_head;        // mod

    // Bloodthirsty
    f32 regen;              // mod
    f32 kill_heal;          // value

    // Operator
    u8 demontage_time;      // base value is 150
    bool sprint;
    f32 mg_overheat;        // mod
    f32 ftw_overheat;       // mod
    u8 wrench_repair_time;  // base value is 30
    Vec2f heli_velo;        // mod
    f32 plane_velo;         // value
    u8 top_angle;
    u8 down_angle;

    // Lucky
    u8 aos_taken_time;      // cooldown on activation
    u8 aos_healed_time;     // cooldown on heal
    u8 aos_invulnerability_time;

    // Wealthy
    u8 kill_coins;          // base value is 2
    u8 coins_income;        // base value is 1

    // Death Incarnate
    f32 damage_in;          // mod, also used by bull
    f32 exp;                // mod

    // Paratrooper
    f32 para_damage_in;     // mod, used while parachute is enabled
    f32 fall_damage_in;     // mod

    // Bull
    f32 sprint_factor;
    f32 walk_factor;
    f32 walk_factor_air;
    f32 jump_factor;
    f32 walk_extra_factor;  // bull abilities
    f32 walk_extra_factor_air;
    f32 jump_extra_factor;
    u16 kill_bonus_time;

    // Field Engineer
    bool parachute;

    PerkStats()
    {
        name = "";
        id = 0;
        
        //
        ghillie = false; climbtree = false; fire_in_damage = 1.0f; ignite_self_chance = 0.0f;
        //
        reload_time = 1.0f; accuracy = 1.0f; additional_vision_distance = 0; damage_body = 1.0f; damage_head = 1.0f;
        //
        regen = 1.0f; kill_heal = 0;
        //
        demontage_time = 150; sprint = true; mg_overheat = 1.0f; ftw_overheat = 1.0f; wrench_repair_time = 30;
            heli_velo = Vec2f(0,0); plane_velo = 0; top_angle = 0; down_angle = 0;
        //
        aos_taken_time = 0; aos_healed_time = 0; aos_invulnerability_time = 0;
        //
        kill_coins = 2; coins_income = 1;
        //
        damage_in = 1.0f; exp = 1.0f;
        //
        para_damage_in = 1.0f; fall_damage_in = 1.0f;
        //
        sprint_factor = 1.1f; walk_factor = 1.0f; walk_factor_air = 1.0f; jump_factor = 1.0f;
            walk_extra_factor = 1.0f; walk_extra_factor_air = 1.0f; jump_extra_factor = 1.0f; kill_bonus_time = 0;
        //
        parachute = true;
    }
};

/* Template
    CPlayer@ p = this.getPlayer();
    bool stats_loaded = false;
    PerkStats@ stats;
    if (p !is null && p.get("PerkStats", @stats) && stats !is null)
        stats_loaded = true;
*/

shared class PerkCamouflage : PerkStats {
    PerkCamouflage()
    {
        super();
        name = "Camouflage";
        id = 1;
        ghillie = true;
        climbtree = true;
        fire_in_damage = 2.0f;
        ignite_self_chance = 33;
        walk_factor = 1.1f;
    }
};

shared class PerkSharpShooter : PerkStats {
    PerkSharpShooter()
    {
        super();
        name = "Sharp Shooter";
        id = 2;
        reload_time = 1.5f;
        accuracy = 1.50f;
        additional_vision_distance = 0.15f;
        damage_body = 1.25f;
        damage_head = 1.25f;
    }
};

shared class PerkBloodthirsty : PerkStats {
    PerkBloodthirsty()
    {
        super();
        name = "Bloodthirsty";
        id = 3;
        regen = 0.5f;
        kill_heal = 2.0f;
    }
};

shared class PerkOperator : PerkStats {
    PerkOperator()
    {
        super();
        name = "Operator";
        id = 4;
        demontage_time = 75;
        sprint = false;
        walk_factor = 0.95f;
        mg_overheat = 0.85f;
        ftw_overheat = 0.75f;
        wrench_repair_time = 22;
        heli_velo = Vec2f(0.25f, 0.75f);
        plane_velo = 0.033f;
        top_angle = 3;
        down_angle = 4;
    }
};

shared class PerkLucky : PerkStats {
    PerkLucky()
    {
        super();
        name = "Lucky";
        id = 5;
        aos_taken_time = 30;
        aos_healed_time = 180;
        aos_invulnerability_time = 15;
    }
};

shared class PerkWealthy : PerkStats {
    PerkWealthy()
    {
        super();
        name = "Wealthy";
        id = 6;
        kill_coins = 6;
        coins_income = 2;
    }
};

shared class PerkDeathIncarnate : PerkStats {
    PerkDeathIncarnate()
    {
        super();
        name = "Death Incarnate";
        id = 7;
        damage_in = 2.0f;
        exp = 5.0f;
    }
};

shared class PerkBull : PerkStats {
    PerkBull()
    {
        super();
        name = "Bull";
        id = 8;
        damage_in = 0.66f;
        walk_factor = 1.05f;
        walk_factor_air = 1.1f;
        jump_factor = 1.3f;
        walk_extra_factor = 1.2f;
        walk_extra_factor_air = 1.15f;
        jump_extra_factor = 1.5f;
        reload_time = 0.8f;
        kill_bonus_time = 150;
    }
};

shared class PerkParatrooper : PerkStats {
    PerkParatrooper()
    {
        super();
        name = "Paratrooper";
        id = 9;
        para_damage_in = 0.5f;
        fall_damage_in = 1.5f;
    }
};

shared class PerkFieldEngineer : PerkStats {
    PerkFieldEngineer()
    {
        super();
        name = "Field Engineer";
        id = 10;

        parachute = false;
    }
};

PerkStats@ getPerkStats(CPlayer@ p, bool &out stats_loaded)
{
    stats_loaded = false;
	PerkStats@ stats;
	if (p !is null && p.get("PerkStats", @stats))
		stats_loaded = true;
    
    return stats;
} 

PerkStats@ getPerkStats(CBlob@ b, bool &out stats_loaded)
{
    if (b is null) return null;
    return getPerkStats(b.getPlayer(), stats_loaded);
} 