---@class RhythmgameChart: Object
---@field track Song.track
---@field song Song
local RhythmgameChart, super = Class(Object)

local a_single_pixel_data = love.image.newImageData(1,1)
a_single_pixel_data:setPixel(0, 0, {1,1,1,1})
RhythmgameChart.pixel = love.graphics.newImage(a_single_pixel_data)

function RhythmgameChart:init(instrument, index, track, song)
    super.init(self, 170 + ((((instrument+1)/2) - 1) * 300), 290, 80, 250)
    self.track = track
    self.party = Game.party[index or 1]
    self.origin_x = 0.5
    self.origin_y = 1
    self.remtrackpos = {0,0,0,0,0}

    self.song_initialized = 0;
    self.loadsong = 1;
    self.missnotetimer = 0;
    self.missnotecon = 0;
    self.invc = 0;
    self.hurt_flash = 0;
    self.minnote = 1;
    self.trackpos = 0;
    self.buffer = {0,0,0};
    self.pressedtimer = {10, 10, 10};
    self.bpm = song and song.bpm or 230;
    self.song = song
    self.notespacing = 60 / self.bpm;
    self.meter = self.notespacing * 4;
    self.startoffset = 0;
    self.lineA = 0;
    self.lineB = 0;
    self.oneAtATime = true;
    self.hold_start = {0,0,0};
    self.hold_end = {0,0,0};
    self.heldnote = {0,0,0};
    self.hold_score = 0;
    self.total_score = 0;
    self.score_scale = 2;
    self.fame = 5000;
    self.max_score = 25000;
    self.auto_play = instrument ~= 2;
    self.combo = 0;
    self.great = 0;
    self.good = 0;
    self.okay = 0;
    self.miss = 0;
    self.loop = false;
    self.last_score = {0, 0, 0, 0, 0}
    self.chart_start = 0;
    self.chart_end = 0;
    self.goodScore = 0;
    self.maxScore = 0;
    self.track1 = -1;
    self.track2 = -1;
    self.track1_instance = -1;
    self.track2_instance = -1;
    self.instrument = Utils.clamp(instrument - 1, 1, 2);
    self.bottomy = 0 + 200;
    self.note_hit_timer = {0,0,0}
    self.masher = 0;
    self.con = -1;
    self.mash_hit = -1;
    self.mash_speed = 3;
    self.cooldown = 0;
    self.current_note = 1;
    self.last_note = 0;
    self.fade = 1;
    self.notex = 1;
    self.note_streak = 0;
    self.trackstart = 0;
    self.track_length = 135.652;
    self.paused = false;
    self.rhythmgame = -4;
    -- TODO: Make accurate
    self.brightness = instrument == 2 and 0.9 or 0.9;
    self.target_brightness = 1;
    self.camy = 0;
    self.camx = 0;

end

function RhythmgameChart:draw()
    self:drawBacking(self.song.notespeed * 4, 40, DEBUG_RENDER)
    self:drawChart(self.song.notespeed * 4, 40, DEBUG_RENDER)
    self:drawBorder(40, DEBUG_RENDER)
end


local function rectangle_points(mode,x,y,x2,y2)
    love.graphics.rectangle(mode, x, y, x2-x, y2-y)
end

local function fill_rectangle_points(x,y,x2,y2)
    return rectangle_points("fill", x, y, x2, y2)
end

function RhythmgameChart:drawBacking(notespeed, centerx, debug, mysteryunusedargument)
    love.graphics.setLineWidth(1)
    debug = debug or false
    mysteryunusedargument = mysteryunusedargument or 0

    local fade = 1
    self.brightness = self.brightness
    if (debug) then
        fade = 0;
    end

    if (fade == 1 and self.brightness == 1) then
        Draw.setColor(COLORS.gray);
    else
        Draw.setColor(Utils.lerp(COLORS.black, COLORS.gray, fade * self.brightness));
    end

    local _gray = Utils.lerp(COLORS.black, COLORS.gray, self.brightness);
    Draw.setColor(COLORS.black);
    local _flash = 0;

    if (self.invc > 0 and fade == 1) then
        _flash = Utils.clampMap(0, 6, 0, 1, self.hurt_flash);
    end

    Draw.setColor(COLORS.black, 0.75);
    -- fill_rectangle_points(10, 10, 20, 20)
    -- print(centerx - 40, self.bottomy - 200, centerx + 40, self.bottomy + 50)
    fill_rectangle_points(centerx - 40, self.bottomy - 200, centerx + 40, self.bottomy + 50);
    Draw.setColor(COLORS.black, 1);
    love.graphics.setBlendMode("alpha");
    local whitebar = -1;
    local linegap = notespeed * self.notespacing * 16;
    local linestart = (self.bottomy - linegap) + (((self.trackpos - self.startoffset) % self.notespacing) * notespeed);
    local whitebarstart = (self.bottomy - linegap) + (((self.trackpos - self.startoffset) % (self.notespacing * 4)) * notespeed);
    Draw.setColor(_gray);

    local startbeat = math.floor(self.song:secondsToBeat(Game.minigame:tell()))
    love.graphics.setFont(Assets.getFont("main", 16))

    for i=startbeat - 4, startbeat + 19 do
        local liney = linestart + (self.notespacing * notespeed * i);
        liney = ((self.song:secondsToYPos(self.trackpos) - self.song:secondsToYPos(self.song:beatToSeconds(i)))) + self.bottomy

        if (not debug and (liney < (self.bottomy - 200) or liney > (self.bottomy + 50))) then
            goto continue;
        end

        Draw.setColor(_gray);
        love.graphics.line(centerx - 40, liney, centerx + 40, liney);
        if debug or DEBUG_RENDER then
            love.graphics.print(tostring(i), 0, liney)
        end
        if i % 4 == 0 then
            fill_rectangle_points(centerx - 40, liney - 1, centerx + 40, liney + 1);
        end
        ::continue::
    end
    
    local nextBar = math.floor(self.trackpos / self.meter);
    
    for i=0, 4 do
        local liney = whitebarstart + (self.notespacing * 4 * notespeed * i);

        if (debug) then
            love.graphics.print(tostring((nextBar - i) + 4), centerx - 70, liney - 1 - 8);
            love.graphics.print(tostring((((nextBar - i) + 4) * self.meter) - 0.01), centerx + 70, liney - 1 - 8);
        end

        ::continue::
    end

    if (_flash > 0) then
        love.graphics.setBlendMode("add", "premultiplied");
        local _flashCol = Utils.lerp(COLORS.black, COLORS.red, _flash * fade * self.brightness);
        Draw.setColor(_flash)
        fill_rectangle_points(centerx - 40, self.bottomy - 200, centerx + 40, self.bottomy + 50);
        love.graphics.setBlendMode("alpha", "alphamultiply");
    end

    Draw.setColor(COLORS.white);
end

-- TODO: Define accurate border colors
function RhythmgameChart:getNoteColor(n)
    if self.party.note_colors then
        return self.party.note_colors[n]
    end
    if self.party.icon_color then
        return self.party.icon_color
    end
    local color = self.party.color; -- TODO: Define accurate border colors
    -- dark plac

    if self.party.id == "kris" then
        color = Utils.hexToRgb("#17EEFF")
        if n == 1 then
            color = Utils.hexToRgb("#01EA9E")
        elseif n == 2 then
            color = Utils.hexToRgb("#17EEFF")
        else
            color = Utils.hexToRgb("#FFA040")
        end
    elseif self.party.id == "ralsei" then
        if n == 1 then
            color = Utils.hexToRgb("#FFA040")
        else
            color = Utils.hexToRgb("#01EA9E")
        end
    elseif self.party.id == "susie" then
        if n == 1 then
            color = Utils.hexToRgb("#D1176A")
        else
            color = Utils.hexToRgb("#EA79C8")
        end
    end
    return {color[1]/1, color[2]/1, color[3]/1, 2}
end

function RhythmgameChart:drawBorder(arg0, arg1)
    local _bordercolor = self:getNoteColor(2);
    
    if (self.invc > 0) then
        _bordercolor = Utils.lerp(self.note_color[1], COLORS.red, scr_rhythmgame_damage_flash());
    end
    
    Draw.setColor(Utils.lerp(COLORS.black, _bordercolor, self.brightness), 10);
    if (not arg1) then
        
        local texture = Assets.getTexture(self.party.name_sprite)
        
        Draw.draw(texture, arg0 - math.floor(texture:getWidth()/2), self.bottomy - 230)
    end
    love.graphics.setLineStyle("rough")
    local w = 1
    love.graphics.setLineWidth(w*2)
    rectangle_points("line", arg0 - 40 - w, self.bottomy - 200 - w, arg0 + 40 + w, self.bottomy + 50 + w);
end

function RhythmgameChart:scr_rhythmgame_noteskip(arg0)
    -- TODO: hahahaha
    do return arg0 end
    if (Game.minigame.solo_difficulty < 2) then
        local _skiplength = timestamp[3] - timestamp[Game.minigame.solo_difficulty + 1];
        local _solodiff = timestamp[Game.minigame.solo_difficulty + 1];
        
        if (trackpos <= _solodiff and arg0 >= timestamp[3]) then
            arg0 = arg0 - _skiplength;
        elseif (trackpos >= timestamp[3] and arg0 <= _solodiff) then
            arg0 = arg0 + _skiplength;
        end
    end
    
    if (Game.minigame.solo_difficulty > 0) then
        local _skiplength = timestamp[Game.minigame.solo_difficulty] - timestamp[0];
        local _solodiff = timestamp[Game.minigame.solo_difficulty];
        
        if (trackpos <= timestamp[0] and arg0 >= _solodiff) then
            arg0 = arg0 - _skiplength;
        elseif (trackpos >= _solodiff and arg0 <= timestamp[0]) then
            arg0 = arg0 + _skiplength;
        end
    end
    
    return arg0;
end

function RhythmgameChart:drawChart(notespeed, centerx, arg2)
    local _hitspeed = (not arg2 and Game.minigame.pitch or 1) * DTMULT;

    if (not arg2 and Game.minigame.lose_con == 2) then
        _hitspeed = 0;
    end

    local _xstart = (self.instrument == 2) and 280 or 280;
    local _xwidth = (self.instrument == 2) and 30 or 40;
    local _beam = 0;
    local _notecol = {};
    local _flash = 0;
    local _altcolor = 0;

    if (self.invc > 0) then
        _flash = scr_rhythmgame_damage_flash();
    end
    -- _flash = Utils.wave(Kristal.getTime() * math.pi * 2, 0, 1)
    self.note_color = {self:getNoteColor(1), self:getNoteColor(2), self:getNoteColor(3)}
    _notecol[0] = Utils.lerp(self.note_color[1], COLORS.red, _flash);
    _notecol[0] = Utils.lerp(COLORS.black, _notecol[0], self.brightness);
    _notecol[1] = Utils.lerp(self.note_color[2], COLORS.red, _flash);
    _notecol[1] = Utils.lerp(COLORS.black, _notecol[1], self.brightness);
    _notecol[2] = Utils.lerp(self.note_color[3], COLORS.red, _flash);
    _notecol[2] = Utils.lerp(COLORS.black, _notecol[2], self.brightness);

    local _yellow = Utils.lerp(COLORS.black, Utils.lerp(COLORS.yellow, COLORS.red, _flash), self.brightness);
    local _gold = Utils.lerp(COLORS.black, Utils.hexToRgb("#FFED72"), self.brightness);
    local _orange = Utils.lerp(COLORS.black, Utils.lerp(COLORS.orange, COLORS.red, _flash), self.brightness);
    local _white = Utils.lerp(COLORS.black, Utils.lerp(COLORS.white, COLORS.red, _flash), self.brightness);
    local _gray = Utils.lerp(COLORS.black, Utils.lerp(COLORS.gray, COLORS.red, _flash), self.brightness);

    if (self.instrument == 1 and not arg2) then
        local texture = Assets.getFrames("spr_rhythmgame_button")[4+1]
        Draw.setColor(_notecol[0])
        Draw.draw(texture, centerx - 20, self.bottomy, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
        Draw.setColor(_notecol[1])
        Draw.draw(texture, centerx + 20, self.bottomy, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
    end

    if (self.instrument == 2) then
        Draw.setColor(COLORS.black);
        fill_rectangle_points(centerx - 40, self.bottomy - 2, centerx + 40, self.bottomy + 2);
        Draw.setColor(_orange);
        fill_rectangle_points(centerx - 40, self.bottomy - 1, centerx + 40, self.bottomy + 1);

        for i=0,2 do
            _beam = Ease.inQuad(self.note_hit_timer[i+1] / 5, 0, 1, 1);

            if (self.note_hit_timer[i+1] > 0) then
                local gradtextures = Assets.getFrames("spr_whitegradientdown_rhythm")
                Draw.setColor(_gold, 1)
                Draw.draw(gradtextures[1], (centerx - 30) + (30 * i), self.bottomy, _beam * 0.75, 1, 0);
                Draw.setColor(_white, 1)
                Draw.draw(gradtextures[2], (centerx - 30) + (30 * i), self.bottomy, _beam * 0.75, 1, 0);

                if (self.last_note ~= i and self.cooldown > 1) then
                    self.notex = Utils.clamp(self.last_note - i, 0, 1) * 6;
                elseif (self.cooldown <= 1) then
                    self.notex = 0;
                end

                self.last_note = i;
                self.cooldown = 2;
            end

            self.note_hit_timer[i+1] = self.note_hit_timer[i+1] + _hitspeed;
        end

        if (self.cooldown > 0) then
            local _arrow = (self.cooldown == 2) and _yellow or _white;
            -- draw_sprite_ext(spr_custommenu_arrow, 0, (centerx - 30) + (30 * last_note) + self.notex, self.bottomy + 10, 1, 2, 180, _arrow, Utils.clamp(self.cooldown, 0, 1));
            self.notex = Utils.approach(self.notex, 0, 4);
            self.cooldown = self.cooldown - (1/15);
        end
    else
        for i=0, 1 do
            if (self.note_hit_timer[i+1] > 0) then
                _beam = Ease.inQuad(self.note_hit_timer[i+1] / 5, 0, 1, 1);

                local buttonframes = Assets.getFrames"spr_rhythmgame_button"
                local hitframes = Assets.getFrames"spr_rhythmgame_note_hit"
                local gradframes = Assets.getFrames"spr_whitegradientdown_rhythm"
                local _ease = self.note_hit_timer[i+1] / 5;
                local _col = _white;
                local _cool = false;
                local _side = (i * 2) - 1;
                local _cenx = centerx + (20 * _side);
                local _score = 0;

                if (self.instrument == 1) and not self.auto_play then
                    -- _score = note_hit_score[i+1];
                    _score = 100 -- TEMP
                    _cool = _score >= 100;
                    _col = _cool and _gold or _white;
                end

                if (self.instrument == 1) then
                    if (self.auto_play) then
                        _score = 100;
                        _cool = true;
                        _col = _gold;
                    end
                    Draw.setColor(_white, self.note_hit_timer[i+1] / 5)
                    Draw.draw(buttonframes[4], _cenx, self.bottomy, 0, 1, 1, buttonframes[4]:getWidth()/2, buttonframes[4]:getHeight()/2);
                    -- draw_sprite_ext(spr_rhythmgame_button, 3, _cenx, self.bottomy, 1, 1, 0, _white, self.note_hit_timer[i] / 5);
                end

                if (not arg2 and (Game.minigame.fame or 0) >= 12000 and _score > 0) then
                    Draw.setColor(Utils.lerp(_white, _col, 1 - _ease), _ease)
                    Draw.draw(hitframes[math.floor((1 - _beam) * 2.9)], _cenx, self.bottomy, 0, 2 - _beam, 2 - _beam, hitframes[3]:getWidth()/2, hitframes[3]:getHeight()/2);
                    -- draw_sprite_ext(spr_rhythmgame_note_hit, (1 - _beam) * 2.9, _cenx + (_side * (1 - _ease) * 2), self.bottomy, 2 - _beam, 2 - _beam, 0, Utils.lerp(_white, _col, 1 - _ease), _ease);
                end

                if (_cool) then
                    Draw.setColor(_gold)
                    Draw.draw(gradframes[2], _cenx, self.bottomy, 0, _beam, 1, gradframes[2]:getWidth()/2, gradframes[2]:getHeight() - 4);
                    -- draw_sprite_ext(spr_whitegradientdown_rhythm, 1, _cenx, self.bottomy, _beam, 1, 0, _gold, 1);
                    Draw.setColor(_white)
                    Draw.draw(gradframes[3], _cenx, self.bottomy, 0, _beam, 1, gradframes[3]:getWidth()/2, gradframes[3]:getHeight() - 4);
                    -- draw_sprite_ext(spr_whitegradientdown_rhythm, 2, _cenx, self.bottomy, _beam, 1, 0, _white, 1);
                else
                    Draw.setColor(_white)
                    Draw.draw(gradframes[1], _cenx, self.bottomy, 0, _beam, 1, gradframes[1]:getWidth()/2, gradframes[1]:getHeight() - 4);
                    -- draw_sprite_ext(spr_whitegradientdown_rhythm, 0, _cenx, self.bottomy, _beam, 1, 0, _white, 1);
                end

                self.note_hit_timer[i+1] = self.note_hit_timer[i+1] - _hitspeed;
            end
        end
    end

    if (not arg2 and not self.paused) then
        love.graphics.stencil(function ()
            fill_rectangle_points(centerx - 40, self.bottomy + 50, centerx + 40, self.bottomy - 200);

        end)
        love.graphics.setStencilTest("greater", 0)
    end

    local _looper = not arg2 and ((Game.minigame.loop and (self.instrument ~= 0 or tutorial ~= 1)) or (self.chart_end > self.track_length and self.maxnote > 0 and self.track.notes[0].notetime < self.chart_start));
    local _loopcheck = false;
    local remtrackpos = {0,0,0, [0] = 0}
    local _averagetimeunit = ((self.trackpos - remtrackpos[0]) + (remtrackpos[0] - remtrackpos[1]) + (remtrackpos[1] - remtrackpos[2])) / 3;
    local _end_buffer = self.trackpos - (3.6 * _averagetimeunit);

    if (not arg2 and self.instrument == 0 and Game.minigame.hardmode) then
        _end_buffer = self.trackpos - (2.4 * _averagetimeunit);
    end

    local notei = math.max(self.minnote-2, 1)-1;

    while (notei < #(self.track and self.track.notes or {})) do
        notei = notei+1
        local note = self.track.notes[notei]
        local _notetime = self.song:beatToSeconds(note.notetime);
        local _notealive = note.notealive;
        local _notescore = note.notescore;
        local _noteend = self.song:beatToSeconds(note.noteend);
        if (not arg2 and self.instrument ~= 1 and self.song.id == "raiseupyourbat") then
            _notetime = self:scr_rhythmgame_noteskip(self.track.notes[notei].notetime);

            if (_noteend > 0) then
                _noteend = self:scr_rhythmgame_noteskip(_noteend);
            end
        elseif (_loopcheck) then
            _notetime = scr_rhythmgame_noteloop(self.track.notes[notei].notetime);

            if (_notetime > (self.track_length / 2)) then
                _notealive = 1;
                _notescore = 0;
            else
                _notealive = 0;
                
                if (notei >= (self.maxnote - 5)) then
                    _notescore = last_score[notei - (self.maxnote - 5)];
                end
                
                if (_noteend > 0) then
                    _noteend = scr_rhythmgame_noteloop(_noteend);
                end
            end
        else
        end

        local notey = (self.bottomy - (self.song:secondsToYPos(_notetime))) + (self.song:secondsToYPos(self.trackpos));
        local _topy = 0 - 20;

        if (notey < _topy) then
            if (_looper and not _loopcheck and self.trackpos < 4 and #self.track.notes > 9) then
                _loopcheck = true;
                notei = #self.track.notes - 9;
                goto continue;
            end

            break;
        end
        if (notey >= _topy and (notei >= self.minnote or _notescore <= 0 or (_loopcheck and _notealive))) then
            _end_buffer = self.trackpos - 0.12000000000000001;
            
            if (not arg2 and self.instrument == 0 and Game.minigame.hardmode) then
                _end_buffer = self.trackpos - 0.08666666666666667;
            end
            
            if (not _loopcheck and _notetime < _end_buffer) then
                if (self.track.notes[notei].notescore <= 0 and self.track.notes.notealive == 1 and fade == 1) then
                    self.missnotecon = 1;
                    
                    if (self.instrument == 0 and not arg2) then
                        self.miss = self.miss + 1;
                    end
                end
                
                self.track.notes[notei].notealive = 0;
                self.minnote = notei + 1;
            end
            
            if (_notealive == 1) then
                Draw.setColor(_notecol[note.notetype]);
            else
                Draw.setColor(_gray);
            end
            
            if (_notescore >= 100) then
                Draw.setColor(_yellow);
            elseif (_notescore >= 30) then
                Draw.setColor(_orange);
            end
            
            if (_notealive == 1 or _notescore <= 0) then
                if (_notescore < 0 and _noteend > 0 and _notealive == 0) then
                    _notetime = _notetime - self.track.notes[notei].notescore;
                    notey = (self.bottomy - (self.song:secondsToYPos(_notetime))) + (self.song:secondsToYPos(self.trackpos));
                    _notescore = 0;
                end
                
                if (note.noteanim > 0 and arg2) then
                    local _oldcolor = {love.graphics.getColor()};
                    Draw.setColor(_yellow);
                    love.graphics.circle("fill", (centerx - 20 - 15) + (note.notetype * 40), notey, 3)
                    love.graphics.circle("fill", (centerx - 20) + 15 + (note.notetype * 40), notey, 3)
                    Draw.setColor(_oldcolor);
                end
                self:drawNote(centerx, notey, note.notetype);
                
                if (arg2 and self.paused and self.do_refresh) then
                    local _xleft = centerx;
                    
                    if (self.instrument == 2) then
                        _xleft = _xleft - 15;
                    else
                        _xleft = _xleft + 5;
                    end
                    
                    local _node = instance_create((_xleft - _xwidth) + (note.notetype * _xwidth) + 15, notey, obj_rhythmgame_editor_note_node);
                    _node.depth = depth + 1;
                    _node.noteindex = notei;
                    
                    if (self.instrument == 2) then
                        _node.image_xscale = 1.375;
                    end
                end
                
                if (_noteend > 0) then
                    -- local notelength = (_noteend - _notetime) * notespeed;
                    local notelength = - ((self.song:secondsToYPos((_notetime))) - (self.song:secondsToYPos(_noteend)));
                    self:drawNoteLong(centerx, notey, note.notetype, notelength, false);
                end
            end
        end

        if (_looper and not _loopcheck and (notei + 1) == #self.track.notes and self.trackpos > (self.track_length - 4)) then
            notei = -1;
            _loopcheck = true;
        end
        ::continue::

        
    end
    local _note_count = (self.instrument == 1) and 2 or 3;
    for i=1, _note_count do
        if (self.hold_end[i] > 0) then
            -- local note_end = (self.hold_end[i] - self.trackpos) * notespeed;
            local note_end = - ((self.song:secondsToYPos(self.trackpos)) - (self.song:secondsToYPos(self.song:beatToSeconds(self.hold_end[i]))));
            Draw.setColor(_orange);
            self:drawNoteLong(centerx, self.bottomy, i-1, note_end, true);
            Draw.setColor(_yellow);
            self:drawNote(centerx, self.bottomy, i-1);
        end
    end
    
    if (not arg2 and not self.paused) then
    end
    love.graphics.setStencilTest();

    love.graphics.setStencilTest();
end

function RhythmgameChart:drawNote(centerx, ypos, notex, arg3)
    arg3 = arg3 or 0
    assert(centerx and ypos and notex)
    if (self.instrument == 2) then
        centerx = (centerx - 30) + (notex * 30);
        
        if (self.paused) then
            fill_rectangle_points(centerx - 10, ypos - 3, centerx + 10, ypos + 3);
        else
            local texture = Assets.getFrames"spr_rhythmgame_heldnote"[1]
            Draw.draw(texture, centerx, ypos, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
        end
    elseif (self.instrument == 1 and notex == 2) then
        fill_rectangle_points(centerx - 45, ypos - 1, centerx + 45, ypos + 1);
    else
        centerx = (centerx - 20) + (notex * 40);
        local texture = Assets.getFrames"spr_rhythmgame_note"[1]
        Draw.draw(texture, centerx, ypos, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
    end
end

function RhythmgameChart:drawNoteLong(centerx, bottomy, i, note_end, held)
    --centerx, bottomy, i, note_end, held
    if (self.instrument == 2) then
        centerx = (centerx - 30) + (i * 30);
        local texture = Assets.getFrames"spr_rhythmgame_heldnote"[1]
        Draw.draw(texture, centerx, bottomy - note_end, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
        Draw.draw(texture, centerx, bottomy, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
    else
        centerx = (centerx - 20) + (i * 40);
    end
    
    fill_rectangle_points(centerx - 3, bottomy - note_end, centerx + (self.instrument == 2 and 4 or 3), bottomy);
    
    if (held) then
        local _endColor = Utils.lerp(COLORS.yellow, COLORS.orange, Utils.clampMap(bottomy, bottomy - 40, bottomy - note_end, 0, 1));
        _endColor = Utils.lerp(COLORS.black, _endColor, self.brightness);
        local _startColor = Utils.lerp(COLORS.black, COLORS.yellow, self.brightness);
        
        if (self.instrument == 2) then
            Draw.setColor(_endColor);

            local texture = Assets.getFrames"spr_rhythmgame_heldnote"[1]
            Draw.draw(texture, centerx, bottomy - note_end, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
        end
        
        love.graphics.setShader(Kristal.Shaders["GradientV"])
        love.graphics.setColor(COLORS.white)
        Kristal.Shaders["GradientV"]:send("from", _endColor)
        Kristal.Shaders["GradientV"]:send("to", _startColor)
        love.graphics.draw(self.pixel, centerx - 3, bottomy - note_end, 0, 6, note_end)
        -- ossafe_fill_rectangle_color(centerx - 3, bottomy - note_end, centerx + 3, bottomy, _endColor, _endColor, _startColor, _startColor, false);
        love.graphics.setShader()
    end
end

function RhythmgameChart:update()
    super.update(self)
    if self.auto_play then
        self:handleAutoplay()
    else
        self:handleInput()
    end
    for i=1,3 do
        if self.trackpos > self.song:beatToSeconds(self.hold_end[i]) then
            self.hold_end[i] = 0
        end
        if self.hold_end[i] > 0 and self.note_hit_timer[i] <= 1 then
            self.note_hit_timer[i] = 3
        end
    end
end


function RhythmgameChart:handleAutoplay()
    if self:getNote(1) then
        self:tryHitNote(1)
    end
    if self:getNote(2) then
        self:tryHitNote(2)
    end
    if self:getNote(3) then
        self:tryHitNote(3)
    end
end

function RhythmgameChart:getNote(lane)
    for i = self.minnote, self.minnote + 1 do
        if not (self.track and self.track.notes[i]) then break end
        if self.track.notes[i].notetype == lane - 1
            and self.track.notes[i].notescore == 0
            and math.abs(self.song:beatToSeconds(self.track.notes[i].notetime) - (self.trackpos)) < 0.1 then
            return self.track.notes[i], i
        end
    end
end

function RhythmgameChart:tryHitNote(lane)
    local note, noteindex = self:getNote(lane)
    if not note then
        if self.track then
            Game.minigame:setTrackActive(self.track.name, false)
        end
        return
    end
    self.note_hit_timer[lane] = 4
    note.score = 10
    self.hold_end[lane] = note.noteend
    if note.noteend > 0 then
        self.hold_start[lane] = note.notestart
    end
    note.notescore = 100
    note.notealive = false
    if self.track then
        Game.minigame:setTrackActive(self.track.name, true)
    end
    return note
end

function RhythmgameChart:handleInput()
    if Input.pressed("confirm") then
        self:tryHitNote(1)
    end
    if Input.pressed("cancel") then
        self:tryHitNote(2)
    end
end

return RhythmgameChart