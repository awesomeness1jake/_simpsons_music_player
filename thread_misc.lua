local get_frame_time = GetFrameTime()
local tbl_unpack = table.unpack
local type = type
local coro_status = coroutine.status
local coro_close = coroutine.close
local coro_isyieldable = coroutine.isyieldable
local coro_running = coroutine.running

local CreateThreadNow = Citizen.CreateThreadNow
local debug_getinfo = debug.getinfo

INVALID_THREAD_HANDLE = -1
thread_get_handle = coro_running

local function is_thread_valid(tID)
	return tID and tID ~= INVALID_THREAD_HANDLE and (type(tID) == "thread")
end

-- Delay execution for a certain amount of time
--
-- duration:	duration of delay, in seconds (if time_seconds <= 0, execution will delay for exactly one frame)
--
function delay(duration)
	if duration == nil then
		duration = 0
	end

	local elapsed_time = 0.0

	repeat
		thread_yield()
		elapsed_time = elapsed_time + get_frame_time()
	until (elapsed_time >= duration)
end

function sizeof_table(_table)
	local iSize
	if (type(_table) == "table") then
		tSize = #_table
		
		iSize = 0
		
		for k, v in pairs(_table) do
			iSize += 1
		end
		if (tSize > iSize) then
			return tSize
		end
		return iSize
	end
	-- TODO: add warning or error that _table isn't a table
	return 0
end

local function dbg_get_func_data(tfunc)
    local di = debug_getinfo(tfunc)
    return di.name, di.short_src, di.linedefined, di.lastlinedefined
end


local function t_init(tFunc, ...)
    local tID
    local args = { ... }
    CreateThreadNow(function()
        local m_threadFuncRet
        tID = thread_get_handle()
        m_threadFuncRet = tFunc(tbl_unpack(args))
        if (m_threadFuncRet) then
            print(m_threadFuncRet)
        end
    end, ("THREAD %s %s [%i, %i]"):format(dbg_get_func_data(tFunc)))
    return tID
end

function thread_check_done(tID)
    if (tID and (type(tID) == "thread") and (coro_status(tID) == "dead")) then
        return 1
    end
    return false
end

-- lazy 'thread' creator
function thread_new(_thread, ...)
    local _type = type(_thread)
    local func
    if (_type == "function") then
		-- this shouldn't be used but is put in just in case.
        func = _thread
    elseif (_type == "string") then
		-- apparently it is "cheaper" to do this
        func = _G[_thread]
        if (type(func) ~= "function") then
            func = nil
        end
    end
    if (func) then
        
        if ... then
            return t_init(func, ...)
        else
            return t_init(func, ...)
            --l_tID += 1
            --CreateThread(func)
            --return l_tID
        end
    end
    return INVALID_THREAD_HANDLE
end

function kill_thread(tiThread)
    if not (is_thread_valid(tiThread)) then
        return false
    end
    if (coro_status(tiThread) == "suspended") then --coroutine.status(tThread) ~= "dead") then
        if (coro_close(tiThread)) then
        	-- killed
            return 1
        end
    elseif (tiThread == thread_get_handle()) then
    	local bWaitForRetVal = false
    	local bRetVal = false
    	CreateThreadNow(function()
    		if (coro_status(tiThread) ~= "suspended") then
    			bWaitForRetVal = 1
    			Wait(0)
    		end
    		if (coro_status(tiThread) == "suspended") then
    			
		        if (coro_close(tiThread)) then
		        	bRetVal = 1
		            return 1
		        end
		        return false
		    end
		    return false
    	end, ("ThreadDestructor"))
    	if bWaitForRetVal then
    		Wait(0)
    		-- killed
    	end
    	
    end
    return false
end
