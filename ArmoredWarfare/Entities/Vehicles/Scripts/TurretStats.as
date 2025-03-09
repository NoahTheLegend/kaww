#include "AllHashCodes.as";

class TurretStats
{
    string name;
    int hash;

    u16 cooldown_time;
    u8 high_angle;
    u8 low_angle;
    u8 low_angle_back;
    f32 elevation_speed;
    string elevation_sound;

    u8 cassette_size;
    u8 cycle_cooldown;

    string emitsound;
    f32 emitsound_volume;
    string fire_sound;

    // only spritelayers! offsets for bullet are calculated differently
    f32 arm_z;
    u8 barrel_compression; // gun recoil effect
    s16 init_gun_angle;
    s16 arm_height;
    Vec2f arm_joint_offset;

    string projectile;
    string ammo;
    string ammo_description;
    s16 ammo_quantity; // to give onInit()
    f32 projectile_vel;
    Vec2f bullet_pos_offset;
    s16 muzzle_offset;
    Vec2f arm_offset;
    Vec2f secondary_gun_offset;

    string mg;
    bool javelin;
    bool fixed; // can't rotate

    Vec2f shape_offset;
    s16 recoil_force;

    TurretStats()
    {
        name = ""; hash = 0;
        cooldown_time = 90; high_angle = 90; low_angle = 90; low_angle_back = 90; elevation_speed = 1.0f; elevation_sound = "Hydraulics.ogg";
        cassette_size = 1; cycle_cooldown = 1;
        emitsound = "Hydraulics.ogg"; emitsound_volume = 1.0f; fire_sound = "sound_105mm";
        arm_offset = Vec2f_zero; arm_z = 0; barrel_compression = 0; init_gun_angle = 0; muzzle_offset = -16.0f; arm_height = 0.0f; arm_joint_offset = Vec2f(-0.5f, 15.5f);
        projectile = "ballista_bolt"; ammo = "mat_bolts"; ammo_description = "Tank Shells"; ammo_quantity = 0; projectile_vel = -27.5f;
        mg = ""; javelin = false; bullet_pos_offset = Vec2f(0,0);
        shape_offset = Vec2f(0, -12); recoil_force = 0;
        fixed = false;
        secondary_gun_offset = Vec2f_zero;
    }
};

class M60Turret : TurretStats
{
    M60Turret()
    {
        super();

        name = "m60turret"; hash = _m60turret;
        cooldown_time = 210; high_angle = 70; low_angle = 101; low_angle_back = 93;
        arm_offset = Vec2f(-13.5f, -28.5f); arm_z = -50.0f; barrel_compression = 9; init_gun_angle = -3;
        mg = "m2browning";
        recoil_force = 750;
        bullet_pos_offset = Vec2f(0,-1);
    }
};

class E50Turret : TurretStats
{
    E50Turret()
    {
        super();

        name = "e50turret"; hash = _e50turret;
        cooldown_time = 180; high_angle = 70; low_angle = 100; low_angle_back = 102;
        arm_offset = Vec2f(-14.0f, -30.0f); arm_z = -50.0f; barrel_compression = 8; init_gun_angle = -3;
        recoil_force = 700; projectile_vel = -30.0f;
        secondary_gun_offset = arm_offset + Vec2f(0,9);
    }
};

class Obj430Turret : TurretStats
{
    Obj430Turret()
    {
        super();

        name = "obj430turret"; hash = _obj430turret;
        cooldown_time = 240; high_angle = 76; low_angle = 96; low_angle_back = 94;
        arm_offset = Vec2f(-6.0f, -27.5f); arm_z = -50.0f; barrel_compression = 10; init_gun_angle = 2;
        mg = "dshk";
        recoil_force = 750;
    }
};

class T10Turret : TurretStats
{
    T10Turret()
    {
        super();

        name = "t10turret"; hash = _t10turret;
        cooldown_time = 270; high_angle = 75; low_angle = 97; low_angle_back = 92; muzzle_offset = -22.0f;
        arm_offset = Vec2f(-13.0f, -27.0f); arm_z = -50.0f; barrel_compression = 11; init_gun_angle = 2;
        mg = "dshk";
        recoil_force = 850;
        elevation_speed = 0.8f;
        bullet_pos_offset = Vec2f(0,-6);
    }
};

class PSZH4Turret : TurretStats
{
    PSZH4Turret()
    {
        super();

        name = "pszh4turret"; hash = _pszh4turret;
        cooldown_time = 300; high_angle = 75; low_angle = 98;
        cassette_size = 10; cycle_cooldown = 8;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        arm_offset = Vec2f(-2.5f, -24.0f); arm_z = -50.0f; barrel_compression = 6; init_gun_angle = 3;
        recoil_force = 50; fire_sound = "sound_14mm";
        shape_offset = Vec2f(0, -10); arm_height = -3.5f; muzzle_offset = -8;
        bullet_pos_offset = Vec2f(0,5);
        fixed = true;
    }
};

class BTRTurret : TurretStats
{
    BTRTurret()
    {
        super();

        name = "btrturret"; hash = _btrturret;
        cooldown_time = 420; high_angle = 35; low_angle = 95; low_angle_back = 90;
        cassette_size = 12; cycle_cooldown = 10; ammo_quantity = 72;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        arm_offset = Vec2f(-1.0f, -22.5f); arm_z = -50.0f; barrel_compression = 6; init_gun_angle = 5;
        recoil_force = 50; fire_sound = "sound_14mm";
        shape_offset = Vec2f(0, -12); arm_height = -3.5f;
        bullet_pos_offset = Vec2f(0,-4);
    }
};

class BMPTurret : TurretStats
{
    BMPTurret()
    {
        super();

        name = "bmpturret"; hash = _bmpturret;
        cooldown_time = 480; high_angle = 40; low_angle = 94; low_angle_back = 94;
        cassette_size = 16; cycle_cooldown = 8; ammo_quantity = 72;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        arm_offset = Vec2f(-4.0f, -24.0f); arm_z = -40.0f; barrel_compression = 5; init_gun_angle = 2;
        recoil_force = 50; fire_sound = "sound_14mm";
        shape_offset = Vec2f(0, -12); arm_height = -3.5f;
        bullet_pos_offset = Vec2f(0,-4);
    }
};

class Pak38Turret : TurretStats
{
    Pak38Turret()
    {
        super();

        name = "pak38"; hash = _pak38;
        cooldown_time = 120; high_angle = 80; low_angle = 100;
        arm_z = -5.0f; barrel_compression = 7; init_gun_angle = 5;
        recoil_force = 0; projectile_vel = -35.0f; ammo_quantity = -1;
        arm_offset = Vec2f(7.0f, -17.0f); bullet_pos_offset = Vec2f(0,-2.5f); shape_offset = Vec2f(0, 0);
        elevation_speed = 0.33f; elevation_sound = "";
        fixed = true;
    }
};

class ArtilleryTurret : TurretStats
{
    ArtilleryTurret()
    {
        super();

        name = "artilleryturret"; hash = _artilleryturret;
        cooldown_time = 32*30; high_angle = 15; low_angle = 80; projectile_vel = -47.5f;
        arm_offset = Vec2f(-8.0f, -33.0f); arm_z = -50.0f; barrel_compression = 20; init_gun_angle = 20;
        recoil_force = 900; fire_sound = "sound_128mm"; muzzle_offset = -28; arm_height = -2.0f; arm_joint_offset = Vec2f(-0.5f, 26.0f);
        ammo = "mat_smallbomb"; ammo_description = "Small Bombs";
        elevation_speed = 0.33f;
        bullet_pos_offset = Vec2f(0,-4);
        fixed = true;
    }
};

class M40Turret : TurretStats
{
    M40Turret()
    {
        super();

        name = "m40turret"; hash = _m40turret;
        cooldown_time = 28*30; high_angle = 15; low_angle = 90; projectile_vel = -42.5f;
        arm_offset = Vec2f(14.0f, -41.0f); arm_z = -50.0f; barrel_compression = 20; init_gun_angle = 0;
        recoil_force = 900; fire_sound = "sound_128mm"; muzzle_offset = -28; arm_height = -2.0f; arm_joint_offset = Vec2f(-0.5f, 26.0f);
        ammo = "mat_smallbomb"; ammo_description = "Small Bombs";
        elevation_speed = 0.33f;
        fixed = true;
    }
};

class GradTurret : TurretStats
{
    GradTurret()
    {
        super();

        name = "gradturret"; hash = _gradturret;
        cooldown_time = 60*30; high_angle = 45; low_angle = 90; projectile_vel = -39.0f;
        cassette_size = 24; cycle_cooldown = 10; ammo_quantity = 24;
        arm_offset = Vec2f(10.0f, -25.0f); arm_z = -50.0f; barrel_compression = 0; arm_joint_offset = Vec2f(-0.5f, 10.0f);
        shape_offset = Vec2f(0, -12);
        recoil_force = 30; fire_sound = "Missile_Launch.ogg";
        elevation_speed = 0.25f;
        bullet_pos_offset = Vec2f(0,-2);
        muzzle_offset = -12.0f;
        fixed = true;
    }
};

class BradleyTurret : TurretStats
{
    BradleyTurret()
    {
        super();

        name = "bradleyturret"; hash = _bradleyturret;
        cooldown_time = 540; high_angle = 35; low_angle = 100; low_angle_back = 92;
        cassette_size = 18; cycle_cooldown = 13; ammo_quantity = 72;
        arm_offset = Vec2f(-12.0f, -30.0f); arm_z = -50.0f; barrel_compression = 5; init_gun_angle = 5;
        ammo = "mat_14mmround"; ammo_description = "14mm Rounds";
        recoil_force = 75; fire_sound = "sound_14mm";
        shape_offset = Vec2f(0, -13.5f); arm_height = -1.0f;
        bullet_pos_offset = Vec2f(0,1);
    }
};

class BC25Turret : TurretStats
{
    BC25Turret()
    {
        super();
        name = "bc25turret"; hash = _bc25turret;
        cooldown_time = 540; high_angle = 68; low_angle = 105; low_angle_back = 110;
        cassette_size = 5; cycle_cooldown = 60; ammo_quantity = 24; muzzle_offset = -26.0f;
        arm_offset = Vec2f(-4.0f, -31.0f); arm_z = -50.0f; barrel_compression = 9; init_gun_angle = -3;
        recoil_force = 300;
        projectile_vel = -30.0f;
        bullet_pos_offset = Vec2f(0,-11);
    }
};

class KingTigerTurret : TurretStats
{
    KingTigerTurret()
    {
        super();

        name = "kingtigerturret"; hash = _kingtigerturret;
        cooldown_time = 420; high_angle = 70; low_angle = 100; low_angle_back = 102;
        arm_offset = Vec2f(-16.0f, -28.0f); arm_z = -50.0f; barrel_compression = 11; init_gun_angle = -5;
        recoil_force = 700;
        elevation_speed = 0.5f;
        bullet_pos_offset = Vec2f(0,-2);
        fire_sound = "sound_128mm";
        secondary_gun_offset = arm_offset + Vec2f(0,8);
    }
};

class MausTurret : TurretStats
{
    MausTurret()
    {
        super();

        cooldown_time = 420; high_angle = 77; low_angle = 99; low_angle_back = 99; arm_joint_offset = Vec2f(-0.5f, 10.0f);
        arm_offset = Vec2f(-20.0f, -5.0f); arm_z = -50.0f; barrel_compression = 12; init_gun_angle = -2;
        recoil_force = 750; elevation_speed = 0.5f;
        shape_offset = Vec2f(0, 2);
        bullet_pos_offset = Vec2f(0,-6);
        fire_sound = "sound_128mm";
        secondary_gun_offset = arm_offset;
    }
};

class Leopard1Turret : TurretStats
{
    Leopard1Turret()
    {
        super();

        name = "leopard1turret"; hash = _leopard1turret;
        cooldown_time = 210; high_angle = 72; low_angle = 100; low_angle_back = 92; arm_joint_offset = Vec2f(-0.5f, 16.5f);
        arm_offset = Vec2f(-11.5f, -29.0f); arm_z = -50.0f; barrel_compression = 9; init_gun_angle = -3; muzzle_offset = -22.0f;
        mg = "mg42";
        recoil_force = 750;
        projectile_vel = -32.5f; elevation_speed = 1.1f;
        bullet_pos_offset = Vec2f(0,-2.5f);
    }
};

class M103Turret : TurretStats
{
    M103Turret()
    {
        super();

        name = "m103turret"; hash = _m103turret;
        cooldown_time = 180; high_angle = 77; low_angle = 99; low_angle_back = 91;
        arm_offset = Vec2f(-18.0f, -29.5f); arm_z = -50.0f; barrel_compression = 10; init_gun_angle = -3;
        mg = "m2browning";
        recoil_force = 650;
        ammo_quantity = 24;
        muzzle_offset = -24.0f;
        bullet_pos_offset = Vec2f(0,-7.5f);
        elevation_speed = 0.65f;
    }
};

class IS7Turret : TurretStats
{
    IS7Turret()
    {
        super();

        name = "is7turret"; hash = _is7turret;
        cooldown_time = 360; high_angle = 78; low_angle = 95; low_angle_back = 94; muzzle_offset = -22.0f;
        arm_offset = Vec2f(-21.0f, -34.0f); arm_z = -50.0f; barrel_compression = 12; init_gun_angle = 3;
        arm_joint_offset = Vec2f(-0.5f, 22.5f);
        mg = "dshk";
        recoil_force = 850;
        elevation_speed = 0.5f;
        bullet_pos_offset = Vec2f(0,0);
        fire_sound = "sound_128mm";
        shape_offset = Vec2f(0, -13);
    }
};

class M1AbramsTurret : TurretStats
{
    M1AbramsTurret()
    {
        super();

        name = "m1abramsturret"; hash = _m1abramsturret;
        cooldown_time = 150; high_angle = 78; low_angle = 102; low_angle_back = 93; muzzle_offset = -22.0f;
        arm_offset = Vec2f(-12.0f, -35.0f); arm_z = -50.0f; barrel_compression = 11; init_gun_angle = -3;
        arm_joint_offset = Vec2f(-0.5f, 22.5f);
        mg = "m2browning"; ammo_quantity = 24; fire_sound = "sound_105mm";
        recoil_force = 650; projectile_vel = -32.5f;
        elevation_speed = 0.65f;
        bullet_pos_offset = Vec2f(0,-2);
        shape_offset = Vec2f(0, -15);
        secondary_gun_offset = Vec2f(-7,-22);
    }
};