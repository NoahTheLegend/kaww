class CheckBox {
    bool state;
    Vec2f pos;
    Vec2f dim;

    Vec2f tl;
    Vec2f br;
    bool capture;

    CheckBox(bool _state, Vec2f _pos, Vec2f _dim)
    {
        state = _state;
        pos = _pos;
        dim = _dim;

        tl = pos;
        br = pos+dim;
        capture = false;
    }

    bool check()
    {
        Sound::Play("select.ogg"); // make sure this plays for local player and they hear it
        state = !state;

        getRules().Tag("update_clientvars");
        
        return state;
    }

    void render(u8 alpha)
    {
        CControls@ controls = getControls();
        if (controls is null) return;

        Vec2f mpos = controls.getInterpMouseScreenPos();
        if (hover(mpos))
        {
            if ((controls.isKeyPressed(KEY_LBUTTON) || controls.isKeyPressed(KEY_RBUTTON)))
            {
                if (!capture)
                {
                    this.check();
                    capture = true;
                }
            }
            else capture = false;
        }

        GUI::SetFont("menu");
        GUI::DrawPane(tl, br, SColor(alpha,255,255,255));
        if (state)
            GUI::DrawTextCentered("✓", tl+dim/2-Vec2f(1.5f,0), color_white);
    }

    bool hover(Vec2f mpos)
    {
        return mpos.x >= tl.x && mpos.x <= br.x
            && mpos.y >= tl.y && mpos.y <= br.y;
    }
}