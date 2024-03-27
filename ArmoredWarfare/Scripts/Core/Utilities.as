#include "ClientVars.as"

ClientVars@ getVars()
{
    ClientVars@ vars;
    if (getRules().get("ClientVars", @vars))
    {
        return vars;
    }
    
    return null;
}

u8 wasMouseScroll()
{
    CControls@ controls = getControls();
    if (controls is null) return 0;

    if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN))) return 1;
    else if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT))) return 2;

    return 0;
}