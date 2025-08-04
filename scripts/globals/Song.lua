---@class Song: Class
---@field tracks Song.track[]
local Song, super = Class()

function Song:init(data)
    self.data = data
    data = data or {}
    self.tracks = {}
    self.bpm = data.bpm
    self.events = data and data.events or {}
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
            replace = trackdata and trackdata.replace;
        }
        self.tracks[trackname] = track
        if self.tracks[trackname].source and trackname ~= "BASE_TRACK" then
            self.tracks[trackname].source:setVolume(0)
        end
    end
    self.notespeed = 40
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

function Song:getBPM()
    return self.bpm
end

function Song:secondsToYPos(seconds)
    return ((seconds * self.notespeed))*4
end

function Song:beatToSeconds(beat)
    local delta = 1/8
    local bpm = self:getBPM()
    local seconds = 0
    local next_time_event = 1
    local active_timeevent = nil
    -- BUG: This discrete approach won't work for negatives! They just get clamped to 0! At some point, rewrite this.
    for curbeat = 0, beat - delta, delta do
        seconds = seconds + (delta * (60/bpm))
        -- bpm = bpm + (delta/8)
        if not active_timeevent and self.events[next_time_event] and (self.events[next_time_event].starttime < curbeat) then
            active_timeevent = self.events[next_time_event]
            if active_timeevent.type == "tempo" then
                bpm = active_timeevent.starttempo
            end
            next_time_event = next_time_event + 1
        end

        if active_timeevent then
            local progress = Utils.clampMap(curbeat, active_timeevent.starttime, active_timeevent.endtime, 0, 1)
            if progress >= 1 then
                if active_timeevent.type == "tempo" then
                    bpm = active_timeevent.endtempo
                end
                active_timeevent = nil
            else
                if active_timeevent.type == "tempo" then
                    bpm = Utils.ease(active_timeevent.starttempo, active_timeevent.endtempo, progress, active_timeevent.ease or "linear")
                end
            end
        end
    end
    return seconds
end

function Song:secondsToBeat(seconds)
    return seconds*(self:getBPM()/60)
end

return Song