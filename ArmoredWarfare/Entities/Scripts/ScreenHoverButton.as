#define CLIENT_ONLY

void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    HoverButton@ buttons;
    if (!blob.get("HoverButton", @buttons))
    {
        HoverButton setbuttons(blob);
        setbuttons.offset = Vec2f(0,-32);
        for (u8 i = 0; i < 2; i++)
        {
            SimpleHoverButton btn(blob);
            btn.dim = Vec2f(60, 30);
            if (i == 1) btn.dim = Vec2f(60, 20);

            setbuttons.AddButton(btn);
        }
        setbuttons.draw_overlap = true;
        blob.set("HoverButton", setbuttons);
    }
    if (!blob.get("HoverButton", @buttons)) return;
    if (buttons is null) return;
}

void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    CControls@ controls = getControls();

    HoverButton@ buttons;
    if (!blob.get("HoverButton", @buttons)) return;
    if (buttons is null) return;

    buttons.render();
}

class SimpleHoverButton : HoverButton
{
    bool hover; bool just_pressed; bool pressed;
    bool show;
    u8 cmd;

    SimpleHoverButton(CBlob@ _blob)
    {
        @this.blob = @_blob;
        this.offset = Vec2f(0,0);
        this.dim = Vec2f(0,0);
        this.show = true;
        this.just_pressed = false;
        this.pressed = false;
    }

    void render_button()
    {
        this.EventHover(this.local_blob);
        this.EventPress(this.local_blob);

        if (this.blob is null) return;
        Vec2f drawpos = getDriver().getScreenPosFromWorldPos(this.offset + Vec2f_lerp(this.blob.getOldPosition(), this.blob.getPosition(), getInterpolationFactor()));
        if (this.pressed)
        {
            GUI::DrawButtonPressed(drawpos - (this.dim*0.5), drawpos + (this.dim*0.5));
        }
        else if (this.hover)
        {
            GUI::DrawButtonHover(drawpos - (this.dim*0.5), drawpos + (this.dim*0.5));
        }
        else
        {
            GUI::DrawButton(drawpos - (this.dim*0.5), drawpos + (this.dim*0.5));
        }
    }

    void EventHover(CBlob@ _local_blob)
    {
        if (_local_blob is null) return;

        CControls@ controls = _local_blob.getControls();
        if (controls is null) return;
        Vec2f mpos = controls.getMouseWorldPos() + Vec2f(-2.5f, -3);
        Vec2f blobpos = this.blob.getPosition();
        Vec2f ul = blobpos+this.offset-(dim*0.25f);
        Vec2f br = blobpos+this.offset+(dim*0.25f);

        //printf("mpos "+mpos.x+":"+mpos.y+" | ul "+ul.x+":"+ul.y+" | br "+br.x+":"+br.y);

        this.hover = (mpos.x >= ul.x && mpos.x <= br.x
            && mpos.y >= ul.y && mpos.y <= br.y);
    }

    void EventPress(CBlob@ _local_blob)
    {
        if (_local_blob is null) return;
        if (!this.hover)
        {
            this.pressed = false;
            this.just_pressed = false;
            return;
        }
        this.pressed = _local_blob.isKeyPressed(key_action1) || _local_blob.isKeyPressed(key_action2);
        this.just_pressed = _local_blob.isKeyJustPressed(key_action1) || _local_blob.isKeyJustPressed(key_action2);
    }
}

class HoverButton
{
    CBlob@ blob; CBlob@ local_blob;
    Vec2f offset; Vec2f dim; bool active;
    Vec2f grid; Vec2f gap; f32 hover_dist;
    bool draw_overlap; bool draw_hover;

    SimpleHoverButton@[] list;

    HoverButton(CBlob@ _blob)
    {
        @this.blob = @_blob;
        this.active = false; 
        this.grid = Vec2f(1,1);
        this.gap = Vec2f(4,4);
        this.hover_dist = 24.0f;
        this.draw_overlap = false;
        this.draw_hover = false;
    }

    void render()
    {
        if (getLocalPlayer() !is null) @this.local_blob = @getLocalPlayer().getBlob();
        if (this.draw_hover) this.EventHover();
        if (this.draw_overlap) this.EventOverlap();

        if (!this.active) return;
        for (int i = 0; i < list.length(); i++)
        {
            SimpleHoverButton@ button = list[i];
            if (button is null || !button.show) continue;

            u8 elements = this.grid.x * this.grid.y;
            u8 row = Maths::Floor(float(i)/this.grid.x);
            f32 row_width;
            for (u8 j = row*this.grid.x; j < row*this.grid.x + this.grid.x; j++)
            {
                if (j >= list.length) continue;
                SimpleHoverButton@ btn = list[j];
                if (btn is null) continue;

                row_width += btn.dim.x;
            }

            // todo: make grid
            Vec2f current_offset = this.offset + this.gap + Vec2f(button.dim.x*this.grid.x, 0) - Vec2f(button.dim.x*(this.grid.x%(i+1)),0);
            if (getGameTime()%15==0)printf("currentoffset "+current_offset.x+":"+current_offset.y);

            button.offset = current_offset;

            //button.offset = this.offset;
            @button.local_blob = @this.local_blob;
            button.render_button();
        } 
    }

    void AddButton(SimpleHoverButton@ button)
    {
        if (button is null) return;
        list.push_back(button);
    }

    void EventOverlap()
    {
        if (this.blob is null || this.local_blob is null) return;

        this.active = this.blob.isOverlapping(this.local_blob);
    }

    void EventHover()
    {
        if (this.blob is null || this.local_blob is null) return;

        CControls@ controls = this.local_blob.getControls();
        if (controls is null) return;
        Vec2f mpos = controls.getMouseWorldPos() + Vec2f(-2, -3);
        this.active = ((mpos - this.blob.getPosition()).Length() <= this.hover_dist);
    }
}