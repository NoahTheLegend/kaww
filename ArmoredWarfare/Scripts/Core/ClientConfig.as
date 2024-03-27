#define CLIENT_ONLY

#include "ClientVars.as";
#include "Slider.as";
#include "CheckBox.as";

class ConfigMenu {
    Vec2f pos;
    Vec2f dim;

    u8 global_alpha;
    u32 state_change_time;
    u8 state; // closed icon > expand X axis > expand Y axis and vice-versa

    Vec2f tl;
    Vec2f br;
    Section[] sections;

    Vec2f target_dim;

    ConfigMenu(Vec2f _pos, Vec2f _dim)
    {
        pos = _pos;
        dim = _dim;

        tl = pos;
        br = pos+dim;

        global_alpha = 0;
        state_change_time = 0;
        state = 0;

        target_dim = Vec2f(32,32);
    }

    void addSection(Section@ section)
    {
        sections.push_back(section);
    }

    bool hover(Vec2f mpos, Vec2f etl, Vec2f ebr)
    {
        return mpos.x >= etl.x && mpos.x <= ebr.x
            && mpos.y >= etl.y && mpos.y <= ebr.y;
    }

    bool isOpening()
    {
        return state == 1;
    }

    bool isClosing()
    {
        return state == 3;
    }

    bool isResizing()
    {
        return isOpening() || isClosing();
    }

    void render()
    {
        CControls@ controls = getControls();
        if (controls is null) return;

        Vec2f mpos = controls.getInterpMouseScreenPos();
        Vec2f btn_dim = Vec2f(32,32);
        bool hovering = hover(mpos, tl, tl+btn_dim);

        if (state == 0)
        {
            if (hovering && (controls.isKeyPressed(KEY_LBUTTON) || controls.isKeyPressed(KEY_RBUTTON)))
            {
                state = 1;
            }
        
            GUI::DrawPane(tl, tl+btn_dim, SColor(hovering?200:100,255,255,255));
            global_alpha = 0;
        }

        if (isResizing())
        {
            if (isOpening())
            {
                target_dim.x = Maths::Lerp(target_dim.x, dim.x, 0.35f);
                if (target_dim.x >= dim.x-1)
                {
                    target_dim.y = Maths::Lerp(target_dim.y, dim.y, 0.35f);
                    global_alpha = Maths::Min(255, global_alpha+15);
                }
                if (target_dim.y >= dim.y-1)
                    state = 2;

                GUI::DrawPane(tl, pos+target_dim, SColor(155,255,255,255));

                for (u8 i = 0; i < sections.size(); i++)
                {
                    if (sections[i].pos.y+sections[i].dim.y > target_dim.y) continue;
                    sections[i].render(global_alpha);
                }
            }
            else
            {
                target_dim.x = Maths::Lerp(target_dim.x, 32, 0.5f);
                target_dim.y = Maths::Lerp(target_dim.y, 32, 0.5f);

                GUI::DrawPane(tl, pos+target_dim, SColor(155,255,255,255));

                for (u8 i = 0; i < sections.size(); i++)
                {
                    if (sections[i].pos.y+sections[i].dim.y >= target_dim.y
                        || sections[i].pos.x+sections[i].dim.x >= target_dim.x) continue;
                    sections[i].render(global_alpha);
                }

                if (target_dim.x <= 33 && target_dim.y <= 33)
                {
                    getRules().Tag("update_clientvars");
                    state = 0;
                    target_dim = Vec2f(32,32);
                }
            }
        }
        else if (state == 2)
        {
            GUI::DrawPane(tl, br, SColor(155,255,255,255));

            if (hovering && (controls.isKeyPressed(KEY_LBUTTON) || controls.isKeyPressed(KEY_RBUTTON)))
                state = 3;

            global_alpha = Maths::Min(255, global_alpha+25);
            for (u8 i = 0; i < sections.size(); i++)
            {
                sections[i].render(global_alpha);
            }
        }

        GUI::DrawIcon("SettingsMenuIcon.png", 0, btn_dim, tl, 0.5f, 0.5f, SColor(hovering?200:100,255,255,255));
    }
};

class Section {
    string title;
    Vec2f pos;
    Vec2f dim;
    Vec2f padding;

    Vec2f tl;
    Vec2f br;
    Option[] options;

    Vec2f title_dim;

    Section(string _title, Vec2f _pos, Vec2f _dim)
    {
        title = _title;
        pos = _pos;
        dim = _dim;

        tl = pos;
        br = pos+dim;
        padding = Vec2f(15, 10);
        
        GUI::GetTextDimensions(title, title_dim);
    }

    void addOption(Option@ option)
    {
        options.push_back(option);
    }

    void render(u8 alpha)
    {
        SColor col_white = SColor(alpha,255,255,255);
        SColor col_grey = SColor(alpha,235,235,235);

        GUI::DrawPane(tl, br, SColor(55,255,255,255));
        {
            GUI::SetFont("score-small");
            GUI::DrawText(title, pos + Vec2f(title_dim.x + padding.x/2, padding.y), col_white);
        }
        GUI::DrawRectangle(tl+padding + Vec2f(0,28), Vec2f(br.x-padding.x, tl.y+padding.y + 30), col_grey);
        
        for (u8 i = 0; i < options.size(); i++)
        {
            options[i].render(alpha);
        }
    }
};

class Option {
    string text;
    Vec2f pos;
    bool has_slider;
    f32 slider_startpos;
    bool has_check;

    Slider slider;
    CheckBox check;

    Option(string _text, Vec2f _pos, bool _has_slider, bool _has_check)
    {
        text = _text;
        pos = _pos;
        has_slider = _has_slider;
        has_check = _has_check;
        slider_startpos = 0.5f;

        if (has_slider)
        {
            slider = Slider("option_slider", pos+Vec2f(0,23), Vec2f(100,15), Vec2f(15,15), Vec2f(8,8), slider_startpos, 0);
        }
        if (has_check)
            check = CheckBox(false, pos+Vec2f(0,1), Vec2f(18,18));
    }

    void setSliderPos(f32 scroll)
    {
        slider.setScroll(scroll);
    }

    void setSliderTextMode(u8 mode)
    {
        slider.mode = mode;
    }

    void setCheck(bool flagged)
    {
        check.state = flagged;
    }

    void render(u8 alpha)
    {
        GUI::SetFont("menu");
        SColor col_white = SColor(alpha,255,255,255);
        if (has_slider)
        {
            slider.render(alpha);
            string text = Maths::Round(slider.scrolled*100)+"%";
            if (slider.mode == 1)
                text = ""+Maths::Abs(Maths::Clamp(slider.step.x+1,1,slider.snap_points+1));
            else if (slider.mode == 2)
                text = slider.descriptions[slider.getSnapPoint()];

            GUI::DrawText(text, slider.pos+Vec2f(0, slider.dim.y), SColor(255,255,235,120));
        }
        if (has_check)
        {
            check.render(alpha);
        }

        GUI::SetFont("score-smaller");
        GUI::DrawText(text, has_check?pos+Vec2f(25,0):pos, col_white);
    }
};