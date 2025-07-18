---@class Song: Class
---@field tracks Song.track[]
local Song, super = Class()

function Song:init(data)
    super.init(self, data)
    data = data or {}
    self.tracks = {}
    local tracks_names = Utils.removeDuplicates(Utils.getKeys(Utils.mergeMultiple(data.tracks, data.notes)))
    for i = 1, #(tracks_names) do
        local trackname = tracks_names[i]
        local trackdata = data.tracks[trackname]
        -- Copy because we will be modifying this!
        local notedata = Utils.copy(data.notes[trackname] or {}, true)
        ---@class Song.track
        local track = {
            name = trackname,
            source = trackdata and trackdata.music and love.audio.newSource(Assets.getMusicPath(trackdata.music), "stream");
            notes = notedata;
        }
        self.tracks[trackname] = track
        if self.tracks[trackname].source and trackname ~= "BASE_TRACK" then
            self.tracks[trackname].source:setVolume(0)
        end
    end
end

function Song:start()
    for _, value in pairs(self.tracks) do
        if value.source then
            value.source:seek(0)
            value.source:play()
        end
    end
end

function Song:seek(t)
    for _, value in pairs(self.tracks) do
        if value.source then
            value.source:seek(t)
        end
    end
end

return Song