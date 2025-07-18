---@class RhythmgameChart: Object
---@field track Song.track
local RhythmgameChart, super = Class(Object)

function RhythmgameChart:init(instrument, index, track)
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
    self.bpm = 230;
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
    self:drawBacking(160, 40, DEBUG_RENDER)
    self:scr_rhythmgame_draw_chart(160, 40, DEBUG_RENDER)
    self:drawBorder(40, DEBUG_RENDER)
end


local function rectangle_points(mode,x,y,x2,y2)
    love.graphics.rectangle(mode, x, y, x2-x, y2-y)
end

local function fill_rectangle_points(x,y,x2,y2)
    return rectangle_points("fill", x, y, x2, y2)
end

function RhythmgameChart:drawBacking(notespeed, centerx, debug, mysteryunusedargument)
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

    for i=0, 19 do
        local liney = linestart + (self.notespacing * notespeed * i);

        if (not debug and (liney < (self.bottomy - 200) or liney > (self.bottomy + 50))) then
            goto continue;
        end

        Draw.setColor(_gray);
        love.graphics.line(centerx - 40, liney, centerx + 40, liney);
        ::continue::
    end

    local nextBar = math.floor(self.trackpos / self.meter);

    for i=0, 4 do
        local liney = whitebarstart + (self.notespacing * 4 * notespeed * i);

        if (debug) then
            love.graphics.print(tostring((nextBar - i) + 4), centerx - 70, liney - 1 - 8);
            love.graphics.print(tostring((((nextBar - i) + 4) * self.meter) - 0.01), centerx + 70, liney - 1 - 8);
        end

        if (not debug and ((liney - 1) < (self.bottomy - 200) or (liney + 1) > (self.bottomy + 50))) then
            goto continue;
        end

        fill_rectangle_points(centerx - 40, liney - 1, centerx + 40, liney + 1);
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
    -- Two thin lines. Not one thick line for some reason. Maybe Gamemaker just doesn't have line thickness?
    rectangle_points("line", arg0 - 40, self.bottomy - 200, arg0 + 40, self.bottomy + 50);
    rectangle_points("line", arg0 - 41, self.bottomy - 201, arg0 + 41, self.bottomy + 51);
end

function RhythmgameChart:scr_rhythmgame_noteskip(arg0)
    if (Game.minmigame.solo_difficulty < 2) then
        local _skiplength = timestamp[3] - timestamp[Game.minmigame.solo_difficulty + 1];
        local _solodiff = timestamp[Game.minmigame.solo_difficulty + 1];
        
        if (trackpos <= _solodiff and arg0 >= timestamp[3]) then
            arg0 = arg0 - _skiplength;
        elseif (trackpos >= timestamp[3] and arg0 <= _solodiff) then
            arg0 = arg0 + _skiplength;
        end
    end
    
    if (Game.minmigame.solo_difficulty > 0) then
        local _skiplength = timestamp[Game.minmigame.solo_difficulty] - timestamp[0];
        local _solodiff = timestamp[Game.minmigame.solo_difficulty];
        
        if (trackpos <= timestamp[0] and arg0 >= _solodiff) then
            arg0 = arg0 - _skiplength;
        elseif (trackpos >= _solodiff and arg0 <= timestamp[0]) then
            arg0 = arg0 + _skiplength;
        end
    end
    
    return arg0;
end

-- [====[
function RhythmgameChart:scr_rhythmgame_draw_chart(notespeed, centerx, arg2)
    local _hitspeed = not arg2 and Game.minigame.pitch or 1;

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
        -- The + 19 was + 20 in the OG code but it looked wrong
        Draw.draw(texture, centerx + 19, self.bottomy, 0, 1, 1, texture:getWidth()/2, texture:getHeight()/2);
    end

    if (self.instrument == 2) then
        Draw.setColor(COLORS.black);
        fill_rectangle_points(centerx - 40, self.bottomy - 2, centerx + 40, self.bottomy + 2);
        Draw.setColor(_orange);
        fill_rectangle_points(centerx - 40, self.bottomy - 1, centerx + 40, self.bottomy + 1);

        for i=0,2 do
            _beam = Ease.inExpo(self.note_hit_timer[i+1] / 5, 0, 1, 1);

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
                _beam = Ease.inExpo(self.note_hit_timer[i] / 5, 0, 1, 1);
                local _ease = self.note_hit_timer[i] / 5;
                local _col = _white;
                local _cool = false;
                local _side = (i * 2) - 1;
                local _cenx = centerx + (20 * _side);
                local _score = 0;

                if (self.instrument == 0) then
                    _score = note_hit_score[i];
                    _cool = _score >= 100;
                    _col = _cool and _gold or _white;
                end

                if (self.instrument == 1) then
                    if (self.auto_play) then
                        _score = 100;
                        _cool = true;
                        _col = _gold;
                    end

                    draw_sprite_ext(spr_rhythmgame_button, 3, _cenx, self.bottomy, 1, 1, 0, _white, self.note_hit_timer[i] / 5);
                end

                if (not arg2 and obj_rhythmgame.fame >= 12000 and _score > 0) then
                    draw_sprite_ext(spr_rhythmgame_note_hit, (1 - _beam) * 2.9, _cenx + (_side * (1 - _ease) * 2), self.bottomy, 2 - _beam, 2 - _beam, 0, Utils.lerp(_white, _col, 1 - _ease), _ease);
                end

                if (_cool) then
                    draw_sprite_ext(spr_whitegradientdown_rhythm, 1, _cenx, self.bottomy, _beam, 1, 0, _gold, 1);
                    draw_sprite_ext(spr_whitegradientdown_rhythm, 2, _cenx, self.bottomy, _beam, 1, 0, _white, 1);
                else
                    draw_sprite_ext(spr_whitegradientdown_rhythm, 0, _cenx, self.bottomy, _beam, 1, 0, _white, 1);
                end

                self.note_hit_timer[i] = self.note_hit_timer[i] - _hitspeed;
            end
        end
    end

    if (not arg2 and not self.paused) then
        love.graphics.stencil(function ()
            fill_rectangle_points(centerx - 40, self.bottomy + 50, centerx + 40, self.bottomy - 200);

        end)
        love.graphics.setStencilTest("greater", 0)
    end

    local _looper = not arg2 and ((loop and (self.instrument ~= 0 or tutorial ~= 1)) or (self.chart_end > self.track_length and self.maxnote > 0 and self.track.notes[0].notetime < self.chart_start));
    local _loopcheck = false;
    local remtrackpos = {0,0,0, [0] = 0}
    local _averagetimeunit = ((self.trackpos - remtrackpos[0]) + (remtrackpos[0] - remtrackpos[1]) + (remtrackpos[1] - remtrackpos[2])) / 3;
    local _end_buffer = self.trackpos - (3.6 * _averagetimeunit);

    if (not arg2 and self.instrument == 0 and hardmode) then
        _end_buffer = self.trackpos - (2.4 * _averagetimeunit);
    end

    local notei = math.max(self.minnote, 0);

    while (notei < #(self.track and self.track.notes or {})) do
        notei = notei+1
        local _notetime = self.track.notes[notei].notetime;
        local _notealive = self.track.notes[notei].notealive;
        local _notescore = self.track.notes[notei].notescore;
        local _noteend = self.track.notes[notei].noteend;
        if (not arg2 and self.instrument ~= 1 and obj_rhythmgame.song_id == 0) then
            _notetime = scr_rhythmgame_noteskip(self.track.notes[notei].notetime);

            if (_noteend > 0) then
                _noteend = scr_rhythmgame_noteskip(_noteend);
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

            local notey = (self.bottomy - (_notetime * notespeed)) + (self.trackpos * notespeed);
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
                
                if (not arg2 and self.instrument == 0 and hardmode) then
                    _end_buffer = self.trackpos - 0.08666666666666667;
                end
                
                if (_loopcheck == 0 and _notetime < _end_buffer) then
                    if (notescore[notei] <= 0 and notealive[notei] == 1 and fade == 1) then
                        missnotecon = 1;
                        
                        if (self.instrument == 0 and not arg2) then
                            miss = miss + 1;
                        end
                    end
                    
                    notealive[notei] = 0;
                    self.minnote = notei + 1;
                end
                
                if (_notealive == 1) then
                    Draw.setColor(_notecol[notetype[notei]]);
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
                        _notetime = _notetime - notescore[notei];
                        notey = (self.bottomy - (_notetime * notespeed)) + (self.trackpos * notespeed);
                        _notescore = 0;
                    end
                    
                    if (noteanim[notei] > 0 and arg2) then
                        local _oldcolor = draw_get_color();
                        Draw.setColor(_yellow);
                        draw_circle((centerx - 20 - 15) + (notetype[notei] * 40), notey, 3, false);
                        draw_circle((centerx - 20) + 15 + (notetype[notei] * 40), notey, 3, false);
                        Draw.setColor(_oldcolor);
                    end
                    
                    self:scr_rhythmgame_draw_note(centerx, notey, notetype[notei]);
                    
                    if (arg2 and self.paused and do_refresh) then
                        local _xleft = centerx;
                        
                        if (self.instrument == 2) then
                            _xleft = _xleft - 15;
                        else
                            _xleft = _xleft + 5;
                        end
                        
                        local _node = instance_create((_xleft - _xwidth) + (notetype[notei] * _xwidth) + 15, notey, obj_rhythmgame_editor_note_node);
                        _node.depth = depth + 1;
                        _node.noteindex = notei;
                        
                        if (self.instrument == 2) then
                            _node.image_xscale = 1.375;
                        end
                    end
                    
                    if (_noteend > 0) then
                        local notelength = (_noteend - _notetime) * notespeed;
                        self:scr_rhythmgame_draw_note_long(centerx, notey, notetype[notei], notelength, false);
                    end
                end
            end

            if (_looper and not _loopcheck and (notei + 1) == #self.track.notes and self.trackpos > (self.track_length - 4)) then
                notei = -1;
                _loopcheck = true;
            end
            ::continue::
        else
        end

        local _note_count = (self.instrument == 0) and 1 or 2;

        for i=1, _note_count do
            if (self.hold_end[i] > 0) then
                local note_end = (self.hold_end[i] - self.trackpos) * notespeed;
                Draw.setColor(_orange);
                self:scr_rhythmgame_draw_note_long(centerx, self.bottomy, i, note_end, true);
                Draw.setColor(_yellow);
                self:scr_rhythmgame_draw_note(centerx, self.bottomy, i);
            end
        end
        
        if (not arg2 and not self.paused) then
        end
    end
    love.graphics.setStencilTest();
end
--]====]

function RhythmgameChart:update()
    super.update(self)
end

return RhythmgameChart