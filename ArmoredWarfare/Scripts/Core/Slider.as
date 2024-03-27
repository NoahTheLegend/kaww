class Slider
{
    string name;
    Vec2f pos;
    Vec2f dim;
    Vec2f button_pos;
    Vec2f button_dim;
    Vec2f capture_margin; // extra area to capture
    f32 start_pos;
    u8 snap_points;
    Vec2f step; // snap step in both axis
    u8 mode;
    string description;
    string[] descriptions;

    bool captured;
    f32 scrolled;

    Vec2f tl;
    Vec2f br;

    Slider(string _name, Vec2f _pos, Vec2f _dim, Vec2f _button_dim, Vec2f _capture_margin = Vec2f_zero, f32 _start_pos = 0, u8 _snap_points = 0)
    {
        name = _name;
        pos = _pos;
        dim = _dim;
        button_dim = _button_dim;
        capture_margin = _capture_margin;
        start_pos = _start_pos;
        snap_points = _snap_points;
        step = Vec2f(0,0);
        mode = 0; // 0 - shows %, 1 - shows snapped point, 2 - shows descriptions[]
        description = "";

        captured = false;

        button_pos = pos + (dim-button_dim)*start_pos;
        tl = pos;
        br = pos+dim;
        scrolled = 0;
    }

    void recalculatePos()
    {
        button_pos = pos + (dim-button_dim)*scrolled;
        tl = pos;
        br = pos+dim;
    }

    void render(u8 alpha)
    {
        CControls@ controls = getControls();
        if (controls is null) return;

        GUI::SetFont("score-smaller");
        u8 style = 0;

        Vec2f mpos = controls.getInterpMouseScreenPos();
        if (hover(mpos) || captured)
        {
            if ((controls.isKeyPressed(KEY_LBUTTON) || controls.isKeyPressed(KEY_RBUTTON)))
            {
                requestUpdate(mpos, button_pos);
                captured = true;
                button_pos = mpos-(dim.x >= dim.y ? Vec2f(9,0) : Vec2f(0,8));
            }
            else captured = false;
            
            style = 1;
        }
        
        Vec2f snap_point = button_pos;
        if (snap_points > 0)
        {
            snap_point = getNearestSnapPoint();
        }

        Vec2f snap = getSnap();
        Vec2f aligned_dim = Vec2f(dim.x-button_dim.x, dim.y-button_dim.y);
        button_pos = clampPos(snap_point);
        
        Vec2f drawpos = button_pos + (dim.y > dim.x ? Vec2f(-aligned_dim.x/2, 0) : Vec2f(0, -aligned_dim.y/2));

        scrolled = Maths::Round((tl-button_pos).Length()/(dim.x > dim.y ? aligned_dim.x : aligned_dim.y)*100.0f)/100.0f;
        // track
        GUI::DrawFramedPane(tl, br);
        // button
        GUI::DrawSunkenPane(drawpos, drawpos+button_dim);
    }

    void requestUpdate(Vec2f a, Vec2f b)
    {
        if (a != b) getRules().Tag("update_clientvars");
    }

    u16 getSnapPoint()
    {
        if (snap_points > 0) return scrolled*snap_points;
        return scrolled;
    }

    Vec2f clampPos(Vec2f raw_pos)
    {
        return Vec2f(Maths::Clamp(raw_pos.x, tl.x, br.x-button_dim.x), Maths::Clamp(raw_pos.y, tl.y, br.y-button_dim.y));
    }
    
    Vec2f getSnap()
    {
        if (snap_points > 0) return Vec2f(br.x/snap_points, br.y/snap_points);
        return Vec2f_zero;
    }

    void setSnap(int snap)
    {
        snap_points = snap-1;
    }

    f32 adjust(f32 x, f32 a, f32 b, f32 n, int&out interval_pos) 
    {
        f32 interval = (b - a) / n + 0.5f;
        f32 nearest_anchor = a + interval * int((x - a) / interval + 0.5f);
        interval_pos = Maths::Round((nearest_anchor - a) / interval);

        //printf("x: "+x+" a: "+a+" b: "+b+" n: "+n+" anch "+nearest_anchor);
        return Maths::Max(a, Maths::Min(b, nearest_anchor));
    }

    Vec2f getNearestSnapPoint() // must include button pos properly to negate skipping snappoints if button is too big
    {
        Vec2f point = Vec2f(adjust(button_pos.x, pos.x, pos.x+dim.x-button_dim.x, snap_points, step.x),adjust(button_pos.y, pos.y, pos.y+dim.y-button_dim.y, snap_points, step.y));

        return point;
    }

    bool hover(Vec2f mpos)
    {
        Vec2f edge_tl = button_pos-capture_margin;
        Vec2f edge_br = button_pos+button_dim+capture_margin;
        return mpos.x >= edge_tl.x && mpos.x <= edge_br.x
            && mpos.y >= edge_tl.y && mpos.y <= edge_br.y;
    }

    void setScroll(f32 dist)
    {
        scrolled = dist;
        button_pos = pos + (dim-button_dim)*dist;
    }

    void scrollBy(f32 dist, const bool do_snap = false) // positive/negative value corresponds by x and y axis
    {
        Vec2f snap = getSnap();
        Vec2f scroll_vec = do_snap ? Vec2f(dist*snap.x, dist*snap.y) : Vec2f(dist, dist);

        if (snap_points > 0)
        {
            scroll_vec = Vec2f(Maths::Ceil(dist/snap.x)*snap.x, Maths::Ceil(dist/snap.y)*snap.y);
        }
        button_pos += scroll_vec;
    }
}