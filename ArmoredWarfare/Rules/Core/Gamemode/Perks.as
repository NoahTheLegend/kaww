
shared class PerkStats {
    string name;
    u8 id;
    // Camouflage
    bool ghillie;
    bool climbtree;
    f32 fire_in_damage; // modifier
    f32 ignite_self_chance; // %

    PerkStats()
    {
        name = "";
        id = 0;
        ghillie = false; climbtree = false; fire_in_damage = 1.0f; ignite_self_chance = 0.0f;
    }
};

shared class PerkCamouflage : PerkStats {
    PerkCamouflage()
    {
        super();
        name = "Camouflage";
        id = 1;
        ghillie = true;
        climbtree = true;
        fire_in_damage = 2.0f;
        ignite_self_chance = 0.33f;
    }
};

