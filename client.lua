local DoesContextExistForThisPed = DoesContextExistForThisPed
local GetPedConfigFlag = GetPedConfigFlag
local PlayerPedId = PlayerPedId

g_SimpsonsMusicPlayer = MusicPlayer:new()

CPED_CONFIG_FLAG_InVehicle = 62

-- threads
t_vehicleExit = INVALID_THREAD_HANDLE
t_hit_and_run_music_thread = INVALID_THREAD_HANDLE

-- currently this "event" is currently handled by script, while the enter phase of the event is done through the game events.
function t_IE_vehicleExit_Watcher(sEvent)
    local pPed = PlayerPedId()
    if (pPed ~= 0) then
        while (true) do
            Wait(300)
            if (not GetPedConfigFlag(pPed, CPED_CONFIG_FLAG_InVehicle, 1)) then
                break
            end
        end
		-- make sure the player has this speech context
        if (DoesContextExistForThisPed(pPed, "GET_OUT_OF_CAR", 0)) then
            -- these should only play for simpsons characters!
            PLAY_PLAYER_SPEECH(pPed, "GET_OUT_OF_CAR", 0, 0, 1)
        end
        GETOUTVEHICLE_START(pPed)
    end
    
end

function GETOUTVEHICLE_START(pPed)
    -- dont allow when wanted, as "HIT_RUN" music is playing and we don't want to 'stop' it
    if (not HIT_RUN_MUSIC_ACTIVE()) then
        -- tell musicplayer that we are done
        g_SimpsonsMusicPlayer:Stop()
    end
    GETOUTVEHICLE_END(pPed)
end

function GETOUTVEHICLE_END(pPed)

end

function currentMissionIsSundayDrive()
    -- hit & run music has priority over other interactive music.
    -- checking for wanted level seems to occasionally soft lock the code
    return (GetPedConfigFlag(PlayerPedId(), CPED_CONFIG_FLAG_InVehicle, 1) and not HIT_RUN_MUSIC_ACTIVE()) or SUNDAY_DRIVE_MUSIC_ACTIVE()
end

function SIMPSONS_MUSIC_FINISHER(sMusic, sEvent, bPositive)
    local sMusicName = sMusic
    local startTime = GetGameTimer()
    -- why does this need to be done? makes no sense. the streams have their set duration, and shouldn't have to be manually stopped to load another.
    -- ie: playing a stream and waiting for it to end, the game will still somehow label that a stream is being played.
    StopStream()
    if (IsPlayerPlaying(GetPlayerIndex())) then
        sMusicName = StringConCat(sMusicName, StringConCat("_", sEvent))
        -- this was going to be done via the music events, but it doesn't seem to execute custom one shots properly... 
        while not LoadStream(sMusicName, 0) do
            Wait(0)
            if ((GetGameTimer() - startTime) > 8000) then
                return
            end
        end
        PlayStreamFrontend()
    end
end

function SUNDAY_DRIVE_END(playTime)
    if (g_SimpsonsMusicPlayer:IsActive()) then
        if (playTime ~= -1) then
            
            TriggerMusicEvent("sunday_drive_get_out_of_car")
            if (not GetPedConfigFlag(PlayerPedId(), CPED_CONFIG_FLAG_InVehicle, 1)) then
                --StopStream()
                local sMusicName = "simpsons2_sunday_drive_end"
                local sEventName = "sus3"
                if playTime < 21000 then
                    sEventName = "sus1"
                elseif playTime > 94000 then
                    sEventName = "sus2"
                end
                SIMPSONS_MUSIC_FINISHER(sMusicName, sEventName)
            end
        end
    end
end

function GETINTOVEHICLE_END()
    
end

function HIT_RUN_MUSIC_ACTIVE()
    -- lazy check :P
   return (g_SimpsonsMusicPlayer:CurrentSong() == "HIT_RUN")
end

function HIT_RUN_INTRO()
    -- quick fade out for current music
    TriggerMusicEvent("Hit_Run_Stop")
    -- stop any current stream
    StopStream()
    while (not LoadStream("hit_run_intro", 0)) do
        Wait(0)
    end
    PlayStreamFrontend()
    Wait(0)
    while (IsStreamPlaying()) do
        Wait(0)
        if (GetStreamPlayTime() > 1300) then
            break
        end
    end
    TriggerMusicEvent("Hit_Run_Start")

end

function HIT_RUN_START()
    if (not HIT_RUN_MUSIC_ACTIVE()) then
       --SetAudioFlag("WantedMusicDisabled", false)
        -- stop any active song
        g_SimpsonsMusicPlayer:Stop()
        if not (thread_check_done(t_vehicleExit)) then
            -- kill existing thread
            kill_thread(t_vehicleExit)
        end
        if not (thread_check_done(t_hit_and_run_music_thread)) then
            -- kill existing thread
            kill_thread(t_hit_and_run_music_thread)
        end
        t_hit_and_run_music_thread = thread_new("HIT_RUN_INTRO")
        -- tell the musicplayer what song we are playing
        g_SimpsonsMusicPlayer:Start("HIT_RUN")
        --Wait(5000)
         -- disable the ingame wanted music as this would conflict (ex: halt and play the ingame music) with the hit & run music.
        --SetAudioFlag("WantedMusicDisabled", true) okay setting this audio flag seems to make the game straight up ignores all music events
    end
end

function HIT_RUN_END()
    if (HIT_RUN_MUSIC_ACTIVE()) then
        if not (thread_check_done(t_hit_and_run_music_thread)) then
            -- kill music thread
            kill_thread(t_hit_and_run_music_thread)
        end
        
        if (IsPlayerBeingArrested(GetPlayerIndex(), 1)) then
            TriggerMusicEvent("HIT_AND_RUN_CAUGHT")
            -- when you are busted, might be better to have an arrested check instead.
            SIMPSONS_MUSIC_FINISHER("hit_run_end", "neg")
        else
            TriggerMusicEvent("HIT_AND_RUN_EVADED")
        end
        -- signal the music as finished
        g_SimpsonsMusicPlayer:Stop()
        if (GetPedConfigFlag(PlayerPedId(), CPED_CONFIG_FLAG_InVehicle, 1)) then
            if (currentMissionIsSundayDrive()) then
                g_SimpsonsMusicPlayer:Event("SUNDAY_DRIVE_START")
            end
        
            SIMPSONS_EXIT_VEHICLE_WATCHER()
        end
        -- re-enable the default ingame wanted music
        --SetAudioFlag("WantedMusicDisabled", false)
    end
end

function SUNDAY_DRIVE_START()
    if (not SUNDAY_DRIVE_MUSIC_ACTIVE()) then
        TriggerMusicEvent("SUNDAY_DRIVE_START")
        g_SimpsonsMusicPlayer:Start("SUNDAY_DRIVE")
    end
end

function SUNDAY_DRIVE_MUSIC_ACTIVE()
    -- lazy check :P
    return (g_SimpsonsMusicPlayer:CurrentSong() == "SUNDAY_DRIVE")
end

function GETINTOVEHICLE_START(pPed)
    if (pPed) then
        if (not g_SimpsonsMusicPlayer:IsActive()) then
            if (DoesContextExistForThisPed(pPed, "GOT_IN_CAR", 0)) then
                -- these should only play for simpsons characters!
                PLAY_PLAYER_SPEECH(pPed, "GOT_IN_CAR", 0, 0, 1)
                if (currentMissionIsSundayDrive()) then
                    g_SimpsonsMusicPlayer:Event("SUNDAY_DRIVE_START")
                end
                SIMPSONS_EXIT_VEHICLE_WATCHER()
                
            end
        end
    end
    GETINTOVEHICLE_END()
end

function SIMPSONS_EXIT_VEHICLE_WATCHER()
    if not (thread_check_done(t_vehicleExit)) then
        -- kill existing thread
        kill_thread(t_vehicleExit)
    end
    -- create a new thread for the "exit vehicle event" to begin the exit sound que
    t_vehicleExit = thread_new("t_IE_vehicleExit_Watcher", "EVENT_GETINTOVEHICLE_END")
end

function SIMPSONS_MUSICPLAYER_EVENT(event)
    g_SimpsonsMusicPlayer:Event(event)
end

function SIMPSONS_MUSICPLAYER_STOP(event)
    g_SimpsonsMusicPlayer:Event(Stop)
end

--
-- MusicPlayer Events
--
AddEventHandler("EVENT_GETINTOVEHICLE_START", GETINTOVEHICLE_START)
AddEventHandler("SIMPSONS_MUSICPLAYER_EVENT", SIMPSONS_MUSICPLAYER_EVENT)
AddEventHandler("SIMPSONS_MUSICPLAYER_STOP", SIMPSONS_MUSICPLAYER_STOP)

--
-- Music Events
--
g_SimpsonsMusicPlayer:AddEventHandler("SUNDAY_DRIVE_START", SUNDAY_DRIVE_START)
g_SimpsonsMusicPlayer:AddEventHandler("HIT_AND_RUN_START", HIT_RUN_START)
g_SimpsonsMusicPlayer:AddEventHandler("HIT_AND_RUN_CAUGHT", HIT_RUN_END)
g_SimpsonsMusicPlayer:AddEventHandler("HIT_AND_RUN_EVADED", HIT_RUN_END)
