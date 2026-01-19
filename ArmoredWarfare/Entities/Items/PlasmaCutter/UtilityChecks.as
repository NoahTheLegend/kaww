#include "CustomBlocks.as";

Tile getSurfaceTile(CBlob@ this)
{
    Tile empty = Tile();
    empty.type = 0;

    if (this is null) return empty;

    CMap@ map = getMap();
    if (map is null) return empty;

    return map.getTile(this.getPosition()+Vec2f(0, this.getRadius() + 4.0f));
}

void getSurfaceTiles(CBlob@ this, TileType &out t1, TileType &out t2)
{
    if (this is null) return;

    CMap@ map = getMap();
    if (map is null) return;

    Vec2f pos = this.getPosition();
    f32 rad = this.getRadius();
    t1 = map.getTile(pos+Vec2f(-4.0f, rad + 4.0f)).type;
    t2 = map.getTile(pos+Vec2f(4.0f, rad + 4.0f)).type;
}

bool inProximity(CBlob@ blob, CBlob@ blob1)
{
    if (blob is null || blob1 is null) return false;

    Vec2f pos1 = blob.getPosition();
    Vec2f pos2 = blob1.getPosition();
    return
        (!getMap().rayCastSolidNoBlobs(pos1, pos2)
        || !getMap().rayCastSolidNoBlobs(pos1 - Vec2f(0,8), pos2 - Vec2f(0,8)));
}

bool posInProximity(Vec2f pos)
{
    CBlob@ local = getLocalPlayerBlob();
    if (local is null) return false;

    Vec2f localPos = local.getPosition();
    return
        (!getMap().rayCastSolidNoBlobs(localPos, pos)
        || !getMap().rayCastSolidNoBlobs(localPos - Vec2f(0,8), pos - Vec2f(0,8)));
}

bool isInAirSpace(Vec2f pos)
{
    return false; //todo
}

bool isInAirSpace(CBlob@ blob)
{
    if (blob is null) return false;
    return isInAirSpace(blob.getPosition());
}

bool hasRadio(CBlob@ blob)
{
    return blob.get_bool("radio_enabled");
}

bool playSoundInProximity(CBlob@ blob, string filename, f32 volume = 1.0f, f32 pitch = 1.0f, bool random = false, f32 falloff_start = 512, f32 max_distance = 512.0f)
{
    if (!isClient()) return false;
    if (blob is null) return false;

    CPlayer@ player = getLocalPlayer();
    if (player is null) return true; // we can hear everything while dead

    Vec2f pos = blob.getPosition();
    CBlob@ local = getLocalPlayerBlob();

    if (local !is null && inProximity(blob, local)) // we see the source
    {
        Vec2f playerpos = local.getPosition();
        f32 dist = (pos - playerpos).Length();

        if (dist < falloff_start)
        {
            f32 volume = 1.0f;
            if (random) blob.getSprite().PlayRandomSound(filename, volume);
            else blob.getSprite().PlaySound(filename, volume);
            return true;
        }
        else if (dist < max_distance)
        {
            f32 volume = 1.0f - Maths::Min((dist - falloff_start) / (max_distance - falloff_start), 1.0f);
            if (random) blob.getSprite().PlayRandomSound(filename, volume);
            else blob.getSprite().PlaySound(filename, volume);
            return true;
        }
    }
    else if (local !is null) // we are behind a wall, the sound is muffled
    {
        Vec2f playerpos = local.getPosition();
        f32 dist = (pos - playerpos).Length();

        if (dist < max_distance / 10)
        {
            f32 volume = 1.0f - Maths::Min(dist / (max_distance / 10), 1.0f);
            if (random) blob.getSprite().PlayRandomSound(filename, volume);
            else blob.getSprite().PlaySound(filename, volume);
            return true;
        }
    }
    else // we are dead and can hear everything
    {
        f32 volume = 1.0f;
        if (random) blob.getSprite().PlayRandomSound(filename, volume);
        else blob.getSprite().PlaySound(filename, volume);
        return true;
    }

    return false;
}

bool playSoundInProximityAtPos(Vec2f pos, string filename, f32 volume = 1.0f, f32 pitch = 1.0f, bool random = false, f32 falloff_start = 512, f32 max_distance = 512.0f)
{
    if (!isClient()) return false;

    CPlayer@ player = getLocalPlayer();
    if (player is null) return true; // we can hear everything while dead

    CBlob@ local = getLocalPlayerBlob();

    if (local !is null && posInProximity(pos)) // we see the source
    {
        Vec2f playerpos = local.getPosition();
        f32 dist = (pos - playerpos).Length();

        if (dist < falloff_start)
        {
            f32 volume = 1.0f;
            if (random) Sound::Play(filename, pos, volume, pitch);
            else Sound::Play(filename, pos, volume, pitch);
            return true;
        }
        else if (dist < max_distance)
        {
            f32 volume = 1.0f - Maths::Min((dist - falloff_start) / (max_distance - falloff_start), 1.0f);
            if (random) Sound::Play(filename, pos, volume, pitch);
            else Sound::Play(filename, pos, volume, pitch);
            return true;
        }
    }
    else if (local !is null) // we are behind a wall, the sound is muffled
    {
        Vec2f playerpos = local.getPosition();
        f32 dist = (pos - playerpos).Length();

        if (dist < max_distance / 10)
        {
            f32 volume = 1.0f - Maths::Min(dist / (max_distance / 10), 1.0f);
            if (random) Sound::Play(filename, pos, volume, pitch);
            else Sound::Play(filename, pos, volume, pitch);
            return true;
        }
    }
    else // we are dead and can hear everything
    {
        f32 volume = 1.0f;
        if (random) Sound::Play(filename, pos, volume, pitch);
        else Sound::Play(filename, pos, volume, pitch);
        return true;
    }

    return false;
}

f32 getSoundFallOff(CBlob@ blob, f32 falloff_start, f32 max_distance = 512.0f)
{
    if (blob is null) return 0.0f;

    CPlayer@ player = getLocalPlayer();
    if (player is null || player.getBlob() is null) return 1.0f; // we can hear everything while dead

    Vec2f pos = blob.getPosition();
    Vec2f playerpos = player.getBlob().getPosition();
    f32 dist = (pos - playerpos).Length();

    return 1.0f - Maths::Min(dist / max_distance , 1.0f);
}

bool isInMenu(CBlob@ blob)
{
    if (blob is null) return false;

    u16 menu_id = blob.get_u16("menu_id");
    CBlob@ menu_runner = menu_id == 0 ? null : getBlobByNetworkID(menu_id);

    if (menu_runner is null)
    {
        resetMenu(blob);
        return false;
    }
    return blob.get_bool("menu_open");
}

void attachMenu(CBlob@ blob, CBlob@ menu_runner)
{
    if (menu_runner is null) return;

    blob.set_bool("menu_open", true);
    blob.set_u16("menu_id", menu_runner.getNetworkID());
}

void resetMenu(CBlob@ blob)
{
    blob.set_bool("menu_open", false);
    blob.set_u16("menu_id", 0);
}