#include "AllHashCodes.as";

class TurretStats
{
    string name;
    int hash;

    u16 cooldown_time;
    u8 high_angle;
    u8 low_angle;
    f32 elevation_speed;

    u8 cassette_size;
    u8 cycle_cooldown;

    string emitsound;
    f32 emitsound_volume;
    string fire_sound;

    // only spritelayers! offsets for bullet are calculated differently
    Vec2f arm_offset;
    f32 arm_z;
    u8 barrel_compression; // gun recoil effect
    s16 init_gun_angle;
    s16 arm_height;
    Vec2f arm_joint_offset;

    string projectile;
    string ammo;
    string ammo_description;
    u16 ammo_quantity; // to give onInit()
    f32 projectile_vel;
    Vec2f bullet_pos_offset;
    s16 muzzle_offset;

    string mg;
    bool javelin;

    Vec2f shape_offset;
    s16 recoil_force;

    TurretStats()
    {
        name = ""; hash = 0;
        cooldown_time = 90; high_angle = 90; low_angle = 90; elevation_speed = 1.0f;
        cassette_size = 1; cycle_cooldown = 1;
        emitsound = "Hydraulics.ogg"; emitsound_volume = 1.0f; fire_sound = "sound_105mm";
        arm_offset = Vec2f_zero; arm_z = 0; barrel_compression = 0; init_gun_angle = 0; muzzle_offset = -16.0f; arm_height = 0.0f; arm_joint_offset = Vec2f(-0.5f, 15.5f);
        projectile = "ballista_bolt"; ammo = "mat_bolts"; ammo_description = "105mm Shells"; ammo_quantity = 0; projectile_vel = -27.5f;
        mg = ""; javelin = false; bullet_pos_offset = Vec2f(0,0);
        shape_offset = Vec2f(5, -12); recoil_force = 0;
    }
};

class M60Turret : TurretStats
{
    M60Turret()
    {
        super();

        name = "m60turret"; hash = _m60turret;
        cooldown_time = 210; high_angle = 70; low_angle = 102;
        arm_offset = Vec2f(-19.0f, -29.0f); arm_z = -50.0f; barrel_compression = 9; init_gun_angle = -3;
        mg = "heavygun";
        recoil_force = 750;
    }
};

class T10Turret : TurretStats
{
    T10Turret()
    {
        super();

        name = "t10turret"; hash = _t10turret;
        cooldown_time = 280; high_angle = 75; low_angle = 97; muzzle_offset = -22.0f;
        arm_offset = Vec2f(-19.0f, -27.0f); arm_z = -50.0f; barrel_compression = 11; init_gun_angle = -3;
        mg = "heavygun";
        recoil_force = 850;
        elevation_speed = 0.85f;
        bullet_pos_offset = Vec2f(0,-6);
    }
};

class PSZH4Turret : TurretStats
{
    PSZH4Turret()
    {
        super();

        name = "pszh4turret"; hash = _pszh4turret;
        cooldown_time = 105; high_angle = 75; low_angle = 98;
        arm_offset = Vec2f(-2.5f, -24.0f); arm_z = -50.0f; barrel_compression = 6; init_gun_angle = -3;
        recoil_force = 350; fire_sound = "sound_14mm";
        shape_offset = Vec2f(0, -10); arm_height = -3.5f; muzzle_offset = -8;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        bullet_pos_offset = Vec2f(0,5);
    }
};

class BTRTurret : TurretStats
{
    BTRTurret()
    {
        super();

        name = "btrturret"; hash = _btrturret;
        cooldown_time = 90; high_angle = 35; low_angle = 95;
        arm_offset = Vec2f(-9.0f, -22.5f); arm_z = -50.0f; barrel_compression = 6; init_gun_angle = -3;
        recoil_force = 300; fire_sound = "sound_14mm";
        shape_offset = Vec2f(8, -12); arm_height = -3.5f;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        bullet_pos_offset = Vec2f(0,-4);
    }
};

class ArtilleryTurret : TurretStats
{
    ArtilleryTurret()
    {
        super();

        name = "artilleryturret"; hash = _artilleryturret;
        cooldown_time = 25*30; high_angle = 15; low_angle = 70; projectile_vel = -45.0f;
        arm_offset = Vec2f(-8.0f, -33.0f); arm_z = -50.0f; barrel_compression = 24; init_gun_angle = -30;
        recoil_force = 900; fire_sound = "sound_128mm"; muzzle_offset = -28; arm_height = -2.0f; arm_joint_offset = Vec2f(-0.5f, 26.0f);
        ammo = "mat_smallbomb"; ammo_description = "Small Bombs";
        elevation_speed = 0.5f;
        bullet_pos_offset = Vec2f(0,-4);
    }
};

class BradleyTurret : TurretStats
{
    BradleyTurret()
    {
        super();

        name = "bradleyturret"; hash = _bradleyturret;
        cooldown_time = 105; high_angle = 35; low_angle = 100;
        arm_offset = Vec2f(-12.0f, -27.0f); arm_z = -50.0f; barrel_compression = 5; init_gun_angle = -3;
        recoil_force = 350; fire_sound = "sound_14mm";
        shape_offset = Vec2f(1, -12); arm_height = -1.0f;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        bullet_pos_offset = Vec2f(0,1);
    }
};

class GradTurret : TurretStats
{
    GradTurret()
    {
        super();

        name = "gradturret"; hash = _gradturret;
        cooldown_time = 60*30; high_angle = 45; low_angle = 90; projectile_vel = -40.0f;
        cassette_size = 24; cycle_cooldown = 10; ammo_quantity = 24;
        arm_offset = Vec2f(10.0f, -25.0f); arm_z = -50.0f; barrel_compression = 0; arm_joint_offset = Vec2f(-0.5f, 10.0f);
        shape_offset = Vec2f(1, -12);
        recoil_force = 30; fire_sound = "Missile_Launch.ogg";
        elevation_speed = 0.25f;
        bullet_pos_offset = Vec2f(0,-2);
        muzzle_offset = -12.0f;
    }
};

class BC25Turret : TurretStats
{
    BC25Turret()
    {
        super();
        name = "bc25turret"; hash = _bc25turret;
        cooldown_time = 660; high_angle = 68; low_angle = 105;
        cassette_size = 5; cycle_cooldown = 60; ammo_quantity = 24; muzzle_offset = -26.0f;
        arm_offset = Vec2f(-4.0f, -31.0f); arm_z = -50.0f; barrel_compression = 9; init_gun_angle = -3;
        recoil_force = 375;
        bullet_pos_offset = Vec2f(0,-11);
    }
};

class MausTurret : TurretStats
{
    MausTurret()
    {
        super();

        // haha shit bitch code
        cooldown_time = 360; high_angle = 77; low_angle = 99; arm_joint_offset = Vec2f(-0.5f, 10.0f);
        arm_offset = Vec2f(-16.0f, -11.0f); arm_z = -50.0f; barrel_compression = 12; init_gun_angle = -2;
        recoil_force = 500; elevation_speed = 0.75f;
        shape_offset = Vec2f(-4, -2); recoil_force = 0;
        bullet_pos_offset = Vec2f(0,-6);
    }
};

class Leopard1Turret : TurretStats
{
    Leopard1Turret()
    {
        super();

        name = "leopard1turret"; hash = _leopard1turret;
        cooldown_time = 210; high_angle = 72; low_angle = 100; arm_joint_offset = Vec2f(-0.5f, 16.5f);
        arm_offset = Vec2f(-15.5f, -29.0f); arm_z = -50.0f; barrel_compression = 9; init_gun_angle = -3; muzzle_offset = -22.0f;
        mg = "heavygun";
        recoil_force = 750;
        projectile_vel = -32.5f; elevation_speed = 1.1f;
        bullet_pos_offset = Vec2f(0,-2.5f);
    }
};