local string_format = string.format
----------------------
-- lua 5.4 required --
---- StringConCat ----
--- StringIntConCat --
----------------------

function StringConCat(sParam0, sParam1, iParam2)
    iParam2 = iParam2
    return sParam0:strconcat(sParam1)
end

function StringIntConCat(sParam0, iParam1, iParam2)
    iParam2 = iParam2
    return sParam0:strconcat(iParam1)
end

function PLAY_PLAYER_SPEECH(pPed, sSpeechContext, sVoiceName, eSpeechParam, bIsCloned)
    --nop
end
