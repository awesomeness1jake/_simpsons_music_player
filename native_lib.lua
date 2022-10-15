DoesContextExistForThisPed = CanPedSpeak

-- get thread id from script name
function scrThreadID(scrName)
	ScriptThreadIteratorReset()
	local tID = 1
	while (tID ~= 0) do
	    tID = ScriptThreadIteratorGetNextThreadId()
	    if tID == 0 then
	        break
	    end
	    local sVar0 = GetThreadName(tID)
	    if (sVar0 == scrName) then
	    	return tID
	    end
	end
	return INVALID_THREAD_HANDLE
end

-- terminates an ingame script, using the script name / resource name
function TerminateThisThread()
	local tID;
	tID = scrThreadID(GetThisScriptName());
	if (tID ~= INVALID_THREAD_HANDLE) then
		if (IsThreadActive(tID)) then
			TerminateThread(tID)
			return IsThreadActive(tID)
		end
	end
	return false
end

--------------
-- Misc Def --
--------------

function IsBitSet(uParam0, iParam1)
    return (uParam0 & (1 << iParam1)) ~= 0
end

function ClearBit(uParam0, iParam1)
    return (uParam0 - (uParam0 & (1 << iParam1)))
end

function SetBit(uParam0, iParam1)
    return (uParam0 | (1 << iParam1))
end
