
// add this to sprite and script lists to work
// add an f32 property name to input as current value and max value as static number
// you may configurate colors as well

// todo: grid, reverse \ toleft-toright mode
void barInit(CBlob@ this)
{
    Bar@ bars;
    if (!this.get("Bar", @bars))
    {
        Bar setbars;
        setbars.gap = 20.0f;
        this.set("Bar", setbars);
    }
}

const SColor back = SColor(255, 75, 75, 0);
const SColor front = SColor(255, 255, 255, 255);

void barTick(CBlob@ this)
{
    Bar@ bars;
    if (!this.get("Bar", @bars))
    {
        return;
    }
    if (bars is null) return;
    if (bars.hasBars()) bars.update();
}

void onRender(CSprite@ sprite)
{
    if (g_videorecording) return;

	CBlob@ this = sprite.getBlob();
	if (this is null) return;

    // initialize all bars, add ProgressBar to the list, then begin rendering
    Bar@ bars;
    if (!this.get("Bar", @bars))
    {
        return;
    }

    Vec2f pos = this.getPosition();
    Vec2f oldpos = this.getOldPosition();
    this.set_Vec2f("renderbar_lastpos", getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())));

	GUI::SetFont("menu");
    
    if (bars is null || !bars.hasBars()) return;
    bars.render();
}

bool hasBar(Bar@ bar, string name)
{
    if (bar is null) return false;
    return bar.getBar(name) !is null;
}

// fills from left to right
class ProgressBar : Bar {
    bool reverse; bool toright;
    CBlob@ blob;
    u8 alpha;

    ProgressBar()
    {
        this.percent = 0;
        this.fadeout = false;
        this.fadeout_end = 0;
        this.alpha = 255;
        this.current = 0;
        this.target = 0;
        this.tick_since_created = getGameTime();
        this.max = 0;
        this.lerp = 1;
        this.fadeout_time = 0;

        this.write_blob = false;
        this.callback_command = "";
    }

    void Set(CBlob@ _blob, string _name, Vec2f _dim, bool _reoffset, Vec2f _offset, Vec2f _inherit,
    SColor _color_back, SColor _color_front, string _prop, f32 _max, f32 _lerp,
    f32 _fadeout_time, f32 _fadeout_delay, bool _write_blob, string _callback_command)
    {
        @this.blob = _blob;
        this.name = _name;
        this.dim = _dim;
        this.reoffset = _reoffset;
        this.offset = _offset;
        this.inherit = _inherit;
        this.color_back = _color_back;
        this.color_front = _color_front;
        this.prop = _prop;
        this.max = _max;
        this.lerp = _lerp;
        this.fadeout_time = _fadeout_time;
        this.fadeout_delay = _fadeout_delay;
        this.write_blob = _write_blob;
        this.callback_command = _callback_command;
    }
    
    void updatebar()
    {
        if (this.blob !is null)
        {
            if (this.current < this.target)
                this.current = Maths::Min(this.max, Maths::Lerp(this.current, this.target+1, this.lerp));
            else
            {
                this.target = this.blob.get_f32(this.prop);
            }
        }
        this.percent = Maths::Min(this.current/this.max, 1.0f);
        
        if (this.current == 0 && this.target == 0)
        {
            this.fadeout_start = 0;
        }
    }

    void renderbar()
    {
        Vec2f mod_dim = this.dim;
        Vec2f mod_offset = this.offset;

	    //mod_dim *= this.camera_factor;
        mod_offset *= this.camera_factor;

        this.drawpos = this.pos2d + mod_offset;
        GUI::DrawPane(this.drawpos - (mod_dim*0.5f) - (this.inherit*0.5f), this.drawpos + (mod_dim*0.5f) + (this.inherit*0.5f), this.color_back);
        if (this.blob !is null && this.blob.getTickSinceCreated() <= 5) return;

        if (this.percent != 0.0f)
            GUI::DrawPane(this.drawpos - (mod_dim*0.5f) + this.inherit, this.drawpos - Vec2f(mod_dim.x*0.33f, 0) + Vec2f(mod_dim.x*0.835f*this.percent,mod_dim.y*0.5f) - this.inherit, this.color_front);
    }
}

class Bar : BarHandler{
    Vec2f dim; Vec2f pos2d; Vec2f offset; Vec2f target_offset; Vec2f drawpos; Vec2f inherit; // positions, offsets
    SColor color_back; SColor color_front; // colors
    f32 current; f32 max; f32 percent; f32 lerp; f32 target; // logic
    bool fadeout; u32 fadeout_start; u32 fadeout_end; u32 fadeout_time; u32 fadeout_delay; // fadeout
    // other
    bool remove_on_fill; bool removing; string name; string callback_command; bool write_blob;
    f32 gap; f32 mod_gap; f32 camera_factor;
    string prop; u32 tick_since_created;
    bool reoffset;

    ProgressBar@ getBar(string name)
    {
        for (int i = 0; i < this.active_bars.length; i++)
        {
            ProgressBar@ active = @this.active_bars[i];
            if (active is null) continue;

            if (active.name == name) return @active;
        }
        return null;
    }

    void AddBar(CBlob@ _blob, ProgressBar@ bar, bool remove) override
    {
        BarHandler::AddBar(_blob, bar, remove);
        @this.tempblob = @_blob;
    }

    bool hasBars()
    {
        return this.active_bars.size() > 0;
    }
    
    void update()
    {
        for (int i = 0; i < this.active_bars.length; i++)
        {
            ProgressBar@ active = @this.active_bars[i];
            if (active is null) continue;

            BarHandler::Fadeout(active);
            if (active.remove_on_fill && active.percent == 1.0f)
            {
                BarHandler::RemoveBar(active.name, false);
            }

            active.updatebar();
        }
    }

    void render()
    {
        CCamera@ camera = getCamera();
        if (camera !is null)
        {
            this.camera_factor = Maths::Max(0.75f, camera.targetDistance);
            this.mod_gap = gap / this.camera_factor;
        }
        
        for (int i = 0; i < this.active_bars.length; i++)
        {
            ProgressBar@ active = @this.active_bars[i];
            if (this.tempblob !is null) active.pos2d = this.tempblob.get_Vec2f("renderbar_lastpos");
    
            active.camera_factor = this.camera_factor;
            active.target_offset = Vec2f(0, 40 / active.camera_factor + this.mod_gap*i);
            active.offset = Vec2f(Maths::Lerp(active.offset.x, active.target_offset.x, 0.33f), Maths::Lerp(active.offset.y, active.target_offset.y, 0.33f));

            active.renderbar();
        }
    }
}

class BarHandler {
    ProgressBar@[] active_bars;
    CBlob@ tempblob;

    void AddBar(CBlob@ _blob, ProgressBar@ bar, bool remove)
    {
        bar.remove_on_fill = remove;

        if (_blob !is null && bar !is null)
        {
            @this.tempblob = @_blob;
            this.active_bars.push_back(bar);
        }
    }

    void RemoveBar(string _name, bool force_removal)
    {
        for (int i = 0; i < this.active_bars.length; i++)
        {
            ProgressBar@ active = @this.active_bars[i];
            if (active is null) continue;
            if (active.name == _name)
            {
                if (force_removal)
                {
                    this.active_bars.erase(i);
                    @active = null;
                    this.SendCommand(active);
                }
                else if (!active.fadeout)
                {
                    this.onBarRemoved(active, active.fadeout_time);
                    this.SendCommand(active);
                }
            }
        }
    }

    void onBarRemoved(ProgressBar@ active, u32 _fadeout_time)
    {
        active.fadeout = true;
        active.fadeout_start = getGameTime() + active.fadeout_delay;
        active.fadeout_end = getGameTime() + _fadeout_time + active.fadeout_delay;
    }

    void SendCommand(ProgressBar@ active)
    {
        if (active is null) return;
        if (active.callback_command == "") return;
    
        CBitStream params;
        if (active.write_blob)
            params.write_u16(active.blob.getNetworkID());
        active.blob.SendCommand(active.blob.getCommandID(active.callback_command), params);
    }

    void Fadeout(ProgressBar@ active)
    {
        if (active.fadeout)
        {
            active.removing = true;
            if (active.fadeout_delay == 0 || (active.fadeout_start != 0 && active.fadeout_start <= getGameTime()))
            {
                active.alpha = 255*(float(active.fadeout_end - getGameTime()) / float(active.fadeout_time));
                if (active.alpha == 0)
                {
                    this.RemoveBar(active.name, true);
                    return;
                }
                active.color_back.setAlpha(active.alpha);
                active.color_front.setAlpha(active.alpha);
            }
        }
    }
}