MusicPlayer = {}
MusicPlayer.__index = MusicPlayer
setmetatable(MusicPlayer, MusicPlayer)

function MusicPlayer:Start(song)
    self.m_CurrentSong = song
    self.m_State = 1
end

function MusicPlayer:Stop(song)
    if (self:IsActive()) then
        local playTime = GetMusicPlaytime()
        if (currentMissionIsSundayDrive()) then
            -- handle sunday_drive ending
            SUNDAY_DRIVE_END(playTime)
        end
        self.m_State = 0
        self.m_PrevSong = self.m_CurrentSong
        self.m_CurrentSong = ""
    end
end

function MusicPlayer:IsActive()
    return (self.m_State == 1)
end

function MusicPlayer:CurrentSong()
    return self.m_CurrentSong
end

function MusicPlayer:Event(event)
    if (event == "SUNDAY_DRIVE_START") then
        -- handle sunday_drive start
        SUNDAY_DRIVE_START()
    elseif (event == "HIT_AND_RUN_START") then
        HIT_RUN_START()
    elseif (event == "HIT_AND_RUN_CAUGHT") then
        HIT_RUN_END(true)
    elseif (event == "HIT_AND_RUN_EVADED") then
        HIT_RUN_END(false)
    end
end

function MusicPlayer:new()
    return setmetatable({
        m_CurrentSong = "", 
        m_PrevSong = "", 
        m_State = -1
    }, self)

end