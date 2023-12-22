// its better to use less than 255 buttons (u8 limit), you won't need more anyways

void hoverRender(CSprite@ this)
{
    if (!isClient()) return;

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
    string callback_command; bool write_blob; bool write_local; bool sent_command; bool skip_command_reset; bool send_if_held;
    string text; string font; SColor text_color;
    string icon; Vec2f icon_offset; f32 icon_scale; u32 icon_frame; Vec2f icon_dim;
    string sound; f32 sound_volume; f32 sound_pitch;
    bool inactive;

    SimpleHoverButton(u16 _blobid)
    {
        this.blobid = _blobid;
        this.offset = Vec2f(0,0);
        this.dim = Vec2f(0,0);
        this.show = true;
        this.just_pressed = false;
        this.pressed = false;
        this.text = "";
        this.font = "default";
        this.text_color = SColor(255,255,255,255);
        this.icon = "";
        this.icon_frame = 0;
        this.icon_dim = Vec2f(1,1);
        this.icon_offset = Vec2f(0,0);
        this.icon_scale = 1.0f;
        this.callback_command = "";
        this.write_local = false;
        this.write_blob = false;
        this.sound = "";
        this.sound_volume = 1.0f;
        this.sound_pitch = 1.0f;
        this.sent_command = false;
        this.skip_command_reset = false;
        this.send_if_held = false;
        this.inactive = false;

        this.t = false;
        this.r = false;
        this.b = false;
        this.l = false;
    }

    void AddIcon(string _icon, u32 _icon_frame, Vec2f _icon_dim, Vec2f _icon_offset, f32 _icon_scale)
    {
        this.icon = _icon;
        this.icon_frame = _icon_frame;
        this.icon_dim = _icon_dim;
        this.icon_offset = _icon_offset;
        this.icon_scale = _icon_scale;
    }

    void Align(bool top, bool right, bool bottom, bool left)
    {
        this.t = top;
        this.r = right;
        this.b = bottom;
        this.l = left;
    }

    void render_button()
    {
        if (this.sent_command && !this.skip_command_reset)
        {
            this.skip_command_reset = true;
        }
        else
        {
            this.sent_command = false;
            this.skip_command_reset = false;
        }

        CBlob@ local = getBlobByNetworkID(this.local_blob_id);
        
        this.EventHover(local);
        this.EventPress(local);

        CBlob@ blob = getBlobByNetworkID(this.blobid);
        if (blob is null) return;
        Vec2f drawpos = getDriver().getScreenPosFromWorldPos(this.offset + Vec2f_lerp(blob.getOldPosition(), blob.getPosition(), getInterpolationFactor()));
        //CCamera@ camera = getCamera();
        //if (camera is null) return;
        //f32 mod = 0.5f * camera.targetDistance;
        f32 mod = 0.5f;
        
        DrawSimpleButton(drawpos - (this.dim*mod), drawpos + (this.dim*mod),
            SColor(255, 125, 135, 115), SColor(255, 40, 50, 50), this.hover, this.pressed, this.inactive,
                2, 2);

        if (this.text != "")
        {
            GUI::SetFont(this.font);
            GUI::DrawTextCentered(this.text, drawpos, this.text_color);
        }
        if (this.icon != "")
        {
            GUI::DrawIcon(this.icon, this.icon_frame, this.icon_dim, drawpos - (this.icon_dim*this.icon_scale) + this.icon_offset, this.icon_scale);
        }
    }

    void EventHover(CBlob@ _local_blob)
    {
        if (_local_blob is null) return;
        CBlob@ blob = getBlobByNetworkID(this.blobid);

        CControls@ controls = _local_blob.getControls();
        if (controls is null) return;
        Vec2f mpos = controls.getMouseWorldPos() + Vec2f(-2.5f, -3);
        Vec2f blobpos = blob.getPosition();
        Vec2f ul = blobpos+this.offset-(dim*0.25f);
        Vec2f br = blobpos+this.offset+(dim*0.25f);

        //printf("mpos "+mpos.x+":"+mpos.y+" | ul "+ul.x+":"+ul.y+" | br "+br.x+":"+br.y);

        this.hover = (mpos.x >= ul.x && mpos.x <= br.x
            && mpos.y >= ul.y && mpos.y <= br.y);
    }

    void EventPress(CBlob@ _local_blob)
    {
        if (_local_blob is null || !isClient()) return;
        if (!this.hover)
        {
            this.pressed = false;
            this.just_pressed = false;
            return;
        }
            
        this.pressed = _local_blob.isKeyPressed(key_action1) || _local_blob.isKeyPressed(key_action2);
        this.just_pressed = _local_blob.isKeyJustPressed(key_action1) || _local_blob.isKeyJustPressed(key_action2);
        
        if (this.just_pressed && this.sound != "")
        {
            _local_blob.getSprite().PlaySound(this.sound, this.sound_volume, this.sound_pitch);
        }

        if (this.just_pressed  || (this.send_if_held && this.pressed))
        {
            if (this.callback_command != "" && !this.sent_command)
            {
                this.sent_command = true;
                CBlob@ blob = getBlobByNetworkID(this.blobid);
                if (blob !is null)
                {
                    CBitStream params;
                    if (this.write_blob) params.write_u16(blob.getNetworkID());
                    if (this.write_local) params.write_u16(_local_blob.getNetworkID());
                    blob.SendCommand(blob.getCommandID(this.callback_command), params);
                }
            }
        }
    }
}

class HoverButton
{
    u16 blobid; u16 local_blob_id;
    Vec2f offset; Vec2f dim; Vec2f cell; bool active;
    Vec2f grid; Vec2f gap; f32 hover_dist;
    bool draw_overlap; bool draw_hover; bool draw_attached;
    // aligns
    bool t; bool r; bool b; bool l;

    SimpleHoverButton@[] list;

    HoverButton(u16 _blobid)
    {
        this.blobid = _blobid;
        this.active = false; 
        this.grid = Vec2f(1,1);
        this.gap = Vec2f(0,0);
        this.hover_dist = 24.0f;
        this.draw_overlap = false;
        this.draw_hover = false;
        this.cell = Vec2f(0,0);
        this.draw_attached = true;
    }

    void render()
    {
        if (getLocalPlayerBlob() !is null) this.local_blob_id = getLocalPlayerBlob().getNetworkID();
        CBlob@ local = getBlobByNetworkID(this.local_blob_id);

        if (local is null) return;
        if (this.draw_hover) this.EventHover();
        if (this.draw_overlap) this.EventOverlap();

        if (!this.active || (!this.draw_attached && local.isAttached())) return;
        for (int i = 0; i < list.length(); i++)
        {
            SimpleHoverButton@ button = list[i];
            if (button is null || !button.show) continue;

            for (u8 j = 0; j < list.length; j++)    
            {
                // set max size of a cell for centralizing buttons
                SimpleHoverButton@ btn = list[j];
                if (btn is null) continue;
                this.cell = Vec2f(btn.dim.x > this.cell.x ? btn.dim.x : this.cell.x, btn.dim.y > this.cell.y ? btn.dim.y : this.cell.y);
            }

            u8 elements = this.grid.x * this.grid.y;

            // define the "position" in grid
            u8 row = Maths::Floor(float(i)/this.grid.x);
            f32 row_width = 0;
            f32 col_height = 0;

            Vec2f bdim = button.dim;
            f32 factor = 2; // 1.0f is 1 pixel of a tile, but GUI uses smaller pixels, so divide them by this value
            this.cell /= factor;
            Vec2f grid_size = Vec2f(this.cell.x*this.grid.x, this.cell.y*this.grid.y) / factor;
            Vec2f grid_gap = this.gap / factor;

            Vec2f place = Vec2f(i%this.grid.x, row%this.grid.y);
            Vec2f avg = Vec2f(this.cell.x/2 * this.grid.x, this.cell.y/2 * this.grid.y);
            Vec2f current_offset = this.offset - avg + cell/2 + Vec2f(this.cell.x*place.x, this.cell.y*place.y) + Vec2f(grid_gap.x*place.x, grid_gap.y*place.y);

            Vec2f diff = (this.cell-bdim*0.5f)/factor-Vec2f(2.0f,2.0f);

            if (button.t) current_offset -= Vec2f(0, diff.y);//Vec2f(0, cell.y/2 + bdim.y/2);
            if (button.r) current_offset += Vec2f(diff.x,0);//Vec2f(cell.x/2 - bdim.x/2, 0); 
            if (button.b) current_offset += Vec2f(0,diff.y);//Vec2f(0, cell.y/2 - bdim.y/2);
            if (button.l) current_offset -= Vec2f(diff.x,0);//Vec2f(cell.x/2 + bdim.x/2, 0);

            button.offset = current_offset;
            //button.offset = this.offset;
            button.local_blob_id = this.local_blob_id;
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
        CBlob@ local = getBlobByNetworkID(this.local_blob_id);
        CBlob@ blob = getBlobByNetworkID(this.blobid);
        if (blob is null || local is null) return;

        this.active = blob.isOverlapping(local);
    }

    void EventHover()
    {
        CBlob@ local = getBlobByNetworkID(this.local_blob_id);
        CBlob@ blob = getBlobByNetworkID(this.blobid);
        if (blob is null || local is null) return;

        CControls@ controls = local.getControls();
        if (controls is null) return;
        Vec2f mpos = controls.getMouseWorldPos() + Vec2f(-2, -3);
        this.active = ((mpos - blob.getPosition()).Length() <= this.hover_dist);
    }
}

void DrawSimpleButton(Vec2f tl, Vec2f br, SColor color, SColor bordercolor, bool hover, bool pressed, bool inactive, f32 outer, f32 inner)
{
    if (!isClient()) return;
    
    if (pressed)
    {
        tl += Vec2f(0,1);
        br += Vec2f(0,1);
    }
    Vec2f combined = Vec2f(inner,inner);

    if (inactive)
    {
        color = 0xff000000;
        bordercolor = 0xff992525;
    }

    u8 hv = hover && !pressed ? 50 : 25;
    GUI::DrawRectangle(tl-Vec2f(outer,outer), br+Vec2f(outer,outer), bordercolor); // draw a bit bigger rectangle for border effect
    GUI::DrawRectangle(tl, br, SColor(color.getAlpha(), color.getRed()+hv, color.getGreen()+hv, color.getBlue()+hv)); // draw inner rectangle border
    
    if (pressed || inactive)
    {
        GUI::DrawRectangle(tl+Vec2f(inner,inner), br-Vec2f(inner,inner), bordercolor);
        combined = Vec2f(outer+inner,outer+inner);
    }

    hv = hover ? 25 : 0;
    GUI::DrawPane(tl+combined, br-combined, pressed ? SColor(color.getAlpha(), color.getRed()-25, color.getGreen()-25, color.getBlue()-25)
        : hover ? SColor(color.getAlpha(), color.getRed()+hv, color.getGreen()+hv, color.getBlue()+hv) : color);
}