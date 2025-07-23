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
end

function minigame:onAdd(parent)
    super.onAdd(self, parent)
    self.song:start()
end

function minigame:update()
    local timescale = (DT / BASE_DT)
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
    for _, value in pairs(self.song.tracks) do
        if value.source then
            return value.source:tell()
        end
    end
    return 0
end

function minigame:seek(t)
    for _, value in pairs(self.song.tracks) do
        if value.source then
            value.source:seek(t)
        end
    end
end

function minigame:setTrackActive(trackid, active)
    local volume = active and 1 or 0
    
end

return minigame