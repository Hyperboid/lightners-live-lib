---@class Minigame.rhythmgame : Minigame
---@field song Song
local minigame, super = Class(Minigame, "rhythmgame")

function minigame:init(song)
    super.init(self)
    if isClass(song) then
        self.song = song
    else
        self.song = LightnersLiveLib:createSong(song)
    end
    ---@type RhythmgameChart[]
    self.charts = {
        self:addChild(RhythmgameChart(2, 1, self.song.tracks.lead, self.song));
        self:addChild(RhythmgameChart(1, 2, self.song.tracks.drums, self.song));
        self:addChild(RhythmgameChart(3, 3, self.song.tracks.vocals, self.song));
    }
    self.fame = 9999999
    self.overrun = -(song.start_delay or 1)
end

function minigame:onAdd(parent)
    super.onAdd(self, parent)
end

function minigame:update()
    local timescale = (DT / BASE_DT)
    if self.overrun < 0 then
        self.overrun = Utils.approach(self.overrun, 0, DT)
        if self.overrun == 0 then
            self.song:start()
        end
    end
    for _, value in pairs(self.song.tracks) do
        if value.source then
            value.source:setPitch(timescale)
        end
    end
    for index, value in ipairs(self.charts) do
        value.trackpos = self:tell()
    end
    super.update(self)
end

function minigame:tell()
    if self.overrun < 0 then
        return self.overrun
    end
    for _, value in pairs(self.song.tracks) do
        if value.source then
            return value.source:tell()
        end
    end
    return 0
end

function minigame:seek(t)
    if self.overrun < 0 then
        self.song:start()
        self.overrun = 0
    end
    for _, value in pairs(self.song.tracks) do
        if value.source then
            value.source:seek(t)
        end
    end
end

function minigame:setTrackActive(trackid, active)
    local track = assert(self.song.tracks[trackid], "Unknown track: "..trackid)
    if track.replace then
        self:setTrackActive(track.replace, not active)
    end
    if not track.source then return end
    track.source:setVolume(active and 1 or 0)
end

return minigame