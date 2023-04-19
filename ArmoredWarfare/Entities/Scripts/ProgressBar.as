
// add this to sprite and script lists to work
// todo: grid, reverse \ toleft-toright mode
void onInit(CBlob@ this)
{
    this.set_f32("renderbar_max", 7);
    this.set_f32("renderbar_current", 0);

    //default bar
    /*
    ProgressBar setbar;
    setbar.dim = Vec2f(64.0f, 16.0f);
    setbar.offset = Vec2f(0, 40);
    setbar.inherit = Vec2f(3,2);
    setbar.color_back = back;
    setbar.color_front = front;
    setbar.max = this.get_f32("renderbar_max")+4 - (this.get_f32("renderbar_max")-i);
    setbar.lerp = 0.15f;
    setbar.fadeout_time = 5;
    setbar.fadeout_delay = 10;
    @setbar.blob = @this;
    setbar.name = "bar";
    if (i > 0) setbar.name = setbar.name+i;
    string arr = "ProgressBar";
    if (i > 0) arr = arr+i;
    this.set(arr, setbar);
    */

    Bar@ bars;
    if (!this.get("Bar", @bars))
    {
        Bar setbars;
        setbars.gap = 20.0f;
        this.set("Bar", setbars);
    }

    //if (this.get("Bar", @bars))
    //{
        //string arr = "ProgressBar";
        //ProgressBar@ bar;
        //if (this.get(arr, @bar)) {}
        //bars.AddBar(this, bar, true);
    //}
}

const SColor back = SColor(255, 75, 75, 0);
const SColor front = SColor(255, 255, 255, 255);

void onTick(CBlob@ this)
{
    Bar@ bars;
    if (!this.get("Bar", @bars))
    {
        return;
    }
    if (bars is null) return;

    bars.update();
}

void onRender(CSprite@ sprite)
{
    if (g_videorecording) return;

	CBlob@ this = sprite.getBlob();
	if (this is null) return;

    Vec2f pos = this.getPosition();
    Vec2f oldpos = this.getOldPosition();
    this.set_Vec2f("renderbar_lastpos", getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())));

	GUI::SetFont("menu");
    
    // initialize all bars, add ProgressBar to the list, then begin rendering
    Bar@ bars;
    if (!this.get("Bar", @bars))
    {
        return;
    }
    if (bars is null) return;
    bars.render();
}

// fills from left to right
class ProgressBar : Bar {
    bool reverse; bool toright;
    CBlob@ blob;
    u8 alpha;
    f32 test;

    ProgressBar()
    {
        this.fadeout = false;
        this.fadeout_end = 0;
        this.alpha = 255;
        this.current = 0;
        this.target = 0;
    }

    void Set(CBlob@ _blob, string _name, Vec2f _dim, Vec2f _offset, Vec2f _inherit,
    SColor _color_back, SColor _color_front, f32 _max, f32 _lerp, f32 _fadeout_time, f32 _fadeout_delay)
    {
        this.dim = _dim;
        this.offset = _offset;
        this.inherit = _inherit;
        this.color_back = _color_back;
        this.color_front = _color_front;
        this.max = _max;
        this.lerp = _lerp;
        this.fadeout_time = _fadeout_time;
        this.fadeout_delay = _fadeout_delay;
        @this.blob = _blob;
        this.name = _name;
    }
    
    void updatebar()
    {
        if (this.blob !is null)
        {
            if (this.current < this.target)
                this.current = Maths::Min(this.max, Maths::Lerp(this.current, this.target+1, this.lerp));
            else
               this.target = this.blob.get_f32("renderbar_current");
        }
        this.percent = Maths::Min(this.current/this.max, 1.0f);
    }

    void renderbar()
    {
        Vec2f mod_dim = this.dim;
        Vec2f mod_offset = this.offset;

	    //mod_dim *= this.camera_factor;
        mod_offset *= this.camera_factor;

        this.drawpos = this.pos2d + mod_offset;
        GUI::DrawPane(this.drawpos - (mod_dim*0.5f), this.drawpos + (mod_dim*0.5f), this.color_back);
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
    bool remove_on_fill; bool removing; string name;
    f32 gap; f32 mod_gap; f32 camera_factor;

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
    
    void update()
    {
        for (int i = 0; i < this.active_bars.length; i++)
        {
            ProgressBar@ active = @this.active_bars[i];
            if (active is null) continue;

            BarHandler::Fadeout(active);

            if (active.remove_on_fill && active.percent == 1)
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
    
            active.target_offset = Vec2f(0, 40 + this.mod_gap*i);
            active.offset = Vec2f(Maths::Lerp(active.offset.x, active.target_offset.x, 0.33f), Maths::Lerp(active.offset.y, active.target_offset.y, 0.33f));
            active.camera_factor = this.camera_factor;
           
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
                }
                else if (!active.fadeout)
                {
                    BarHandler::onBarRemoved(active, active.fadeout_time);
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

    void Fadeout(ProgressBar@ active)
    {
        if (active.fadeout)
        {
            active.removing = true;
            if (active.fadeout_delay == 0 || active.fadeout_start <= getGameTime())
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