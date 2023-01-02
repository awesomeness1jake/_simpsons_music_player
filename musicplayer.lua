local MUSIC_PLAYER_STATE_INACTIVE = 0
local MUSIC_PLAYER_STATE_ACTIVE = 1
local MUSIC_PLAYER_STATE_INVALID = -1
MusicPlayer = {}
MusicPlayer.EventHandler = {}
MusicPlayer.__index = MusicPlayer
setmetatable(MusicPlayer, MusicPlayer)

function MusicPlayer:AddEventHandler(sEventName, eventHandler)
    if (not MusicPlayer.EventHandler[sEventName]) then
        MusicPlayer.EventHandler[sEventName] = eventHandler
    end
end

function MusicPlayer:Start(song)
    self.m_CurrentSong = song
    self.m_State = MUSIC_PLAYER_STATE_ACTIVE
end

function MusicPlayer:Stop(song)
    if (self:IsActive()) then
        local playTime = GetMusicPlaytime()
        if (currentMissionIsSundayDrive()) then
            -- handle sunday_drive ending
            SUNDAY_DRIVE_END(playTime)
        end
        self.m_State = MUSIC_PLAYER_STATE_INACTIVE
        self.m_PrevSong = self.m_CurrentSong
        self.m_CurrentSong = ""
    end
end

function MusicPlayer:IsActive()
    return (self.m_State == MUSIC_PLAYER_STATE_ACTIVE)
end

function MusicPlayer:CurrentSong()
    return self.m_CurrentSong
end

function MusicPlayer:Event(sEventName)
    if (MusicPlayer.EventHandler[sEventName]) then
        MusicPlayer.EventHandler[sEventName]()
    end
end

function MusicPlayer:new()
    return setmetatable({
        m_CurrentSong = "", 
        m_PrevSong = "", 
        m_State = MUSIC_PLAYER_STATE_INVALID
    }, self)

end
