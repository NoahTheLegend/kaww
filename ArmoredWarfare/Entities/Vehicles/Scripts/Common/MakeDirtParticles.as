#include "MakeDustParticle.as";

// idk why i made a separated file, though to make it with pixels first but it looked ugly
void smallDirtParticles(Vec2f pos, bool left = true)
{
    if (left) MakeDustParticle(pos, "DustSmall"+XORRandom(3)+"l.png");
    else MakeDustParticle(pos, "DustSmall"+XORRandom(3)+"r.png");
}