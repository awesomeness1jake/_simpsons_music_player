local coro_status = coroutine.status
local coro_close = coroutine.close
local coro_isyieldable = coroutine.isyieldable
local coro_running = coroutine.running
local coro_yield = coroutine.yield
local CreateThreadNow = Citizen.CreateThreadNow
local debug_getinfo = debug.getinfo
local tbl_unpack = table.unpack
local type = type

INVALID_THREAD_HANDLE = -1
thread_get_handle = coro_running
thread_yield = coro_yield

local function is_thread_valid(tHandle)
	return tHandle and tHandle ~= INVALID_THREAD_HANDLE and (type(tHandle) == "thread")
end

local function dbg_func_data(tfunc, tname)
    local di = debug_getinfo(tfunc)
    return tname or di.name, di.short_src, di.linedefined, di.lastlinedefined
end

local function t_init(tFunc, tName, ...)
    local tHandle
    local args = { ... }
    CreateThreadNow(function()
        tHandle = thread_get_handle()
        tFunc(tbl_unpack(args))

    end, ("THREAD %s %s [%i, %i]"):format(dbg_func_data(tFunc, tName)))
    return tHandle
end

function thread_check_done(tHandle)
    if (is_thread_valid(tHandle) and (coro_status(tHandle) == "dead")) then
        return true
    end
    return false
end

-- lazy 'thread' creator
function thread_new(_thread, ...)
    local t_name = ""
    local _type = type(_thread)
    local func
    if (_type == "function") then -- this shouldn't be used but is put in just in case.
        func = _thread
    elseif (_type == "string") then
		t_name = _thread
		func = _G[_thread]
        if (type(func) ~= "function") then
            func = nil
        end
    end
    if (func) then   
        return t_init(func, t_name, ...)
    end
    return INVALID_THREAD_HANDLE
end

function kill_thread(tThread)
    if not (is_thread_valid(tThread)) then
        return false
    end
    if (coro_status(tThread) == "suspended") then -- check if the thread is able to be killed.
        if (coro_close(tThread)) then
            return true
        end
    elseif (tThread == thread_get_handle()) then -- check if this thread is killing itself
    	thread_yield(Citizen.PointerValueInt())
    end
    return false
end
