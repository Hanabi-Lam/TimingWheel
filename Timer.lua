----------------------
--Author:brent
--DateTime:2019/11/12
--Describe:
-----------------------
local m_utils = {}
function m_utils.ms2t(t)
    local ms = math.floor(t % 1000)
    local ts = math.floor(t / 1000)
    local h, m, s = m_utils.s2t(ts)
    return h, m, s, ms
end
function m_utils.t2ms(h, m, s, ms)
    return ms + s * 1000 + m * 60 * 1000 + h * 60 * 60 * 1000
end

function m_utils.s2t(t)
    local s = math.floor(t % 60)
    local m = math.floor(t / 60)
    local h = math.floor(m / 60)
    return h, m, s
end
local Timer = {
    slots = nil, --所有的槽
    cycle = nil,
    interval = nil, -- 一个滴答的时间
    wheelSize = nil, -- 毫秒级轮子的大小
    timeTask = nil,
    uniqueId = 0
}
--cc.exports.Timer = Timer
function Timer.Init(interval, cycle)
    if not Timer.slots then
        Timer.slots = {}
        Timer.slots[1] = {}  --时（24）
        Timer.slots[2] = {}     --分（60）
        Timer.slots[3] = {}     --秒（60）
        Timer.slots[4] = {}     --毫秒（100） 10

        for i = 1, 24 do
            table.insert(Timer.slots[1], {})
        end
        for i = 1, 60 do
            table.insert(Timer.slots[2], {})
        end
        for i = 1, 60 do
            table.insert(Timer.slots[3], {})
        end
        Timer.wheelSize = math.floor(1000 / interval)  --必须整数  建议100
        for i = 1, Timer.wheelSize do
            table.insert(Timer.slots[4], {})
        end
    end
    Timer.cycle = cycle
    Timer.interval = interval
    Timer.timeTask = {}
end

function Timer.Update(cycle)
    local h1, m1, s1, ms1 = m_utils.ms2t(Timer.cycle)
    Timer.cycle = cycle
    local h2, m2, s2, ms2 = m_utils.ms2t(Timer.cycle)
    ms1 = math.floor(ms1 / Timer.interval)
    ms2 = math.floor(ms2 / Timer.interval)
    Timer.UpdateT(24, 1, h1, h2, Timer.UpdateH)
    Timer.UpdateT(60, 2, m1, m2, Timer.UpdateM)
    Timer.UpdateT(60, 3, s1, s2, Timer.UpdateS)
    Timer.UpdateT(Timer.wheelSize, 4, ms1, ms2, Timer.UpdateMS)
end

function Timer.AddTimeTask(delay, func, loopTime, count)
    Timer.uniqueId = Timer.uniqueId + 1
    Timer.Insert(Timer.uniqueId, delay + 1, func, loopTime, count)
    return Timer.uniqueId
end
function Timer.RemoveTimeTask(id)
    local result, wheelId, wheelPos, taskPos = Timer.Seek(id)
    if result then
        Timer.timeTask[id] = nil
        table.remove(Timer.slots[wheelId][wheelPos], taskPos)
    else
        print('当前订单中不存在id:', id)
    end

end
function Timer.RemoveAllTimeTask()
    for id, _ in pairs(Timer.timeTask) do
        Timer.RemoveTimeTask(id)
    end
end

function Timer.ReplaceTimeTask(id, func)
    if Timer.timeTask[id] then
        Timer.timeTask[id].func = func
    else
        print('当前订单中不存在id:', id)
    end
end
--loopTime 是循环的时间
--count =nil  执行1次删除
--count >0  执行N次删除
--count <= 0  循环
function Timer.Insert(id, delay, func, loopTime, count)
    if 0 == delay or delay < Timer.interval then
        func()
        if count and count ~= 1 then
            if count > 0 then
                count = count - 1
            end
            Timer.Insert(id, loopTime, func, loopTime, count)
        end
    else
        local h1, m1, s1, ms1 = m_utils.ms2t(delay)
        local h2, m2, s2, ms2 = m_utils.ms2t(delay + Timer.cycle)
        local tick = { id = id,
                       func = func,
                       loopTime = loopTime,
                       count = count,
                       time = { h = h2, m = m2, s = s2, ms = ms2 } }
        Timer.timeTask[id] = tick
        if h1 ~= 0 then
            table.insert(Timer.slots[1][h2 == 0 and 24 or h2], tick)
        elseif m1 ~= 0 then
            table.insert(Timer.slots[2][m2 == 0 and 60 or m2], tick)
        elseif s1 ~= 0 then
            table.insert(Timer.slots[3][s2 == 0 and 60 or s2], tick)
        elseif ms1 ~= 0 then
            ms2 = math.floor(ms2 / Timer.interval)
            table.insert(Timer.slots[4][ms2 == 0 and Timer.wheelSize or ms2], tick)
        end
    end
end

function Timer.UpdateT(cycle, index, first, last, func)
    local slots = Timer.slots[index]
    while first ~= last do
        first = first + 1
        for i = 1, #slots[first] do
            Timer.timeTask[slots[first][i].id] = nil
            func(slots[first][i])
        end
        --超时置空
        slots[first] = {}
        first = first % cycle
    end
end

function Timer.UpdateH(v)
    Timer.Insert(v.id, m_utils.t2ms(0, v.time.m, v.time.s, v.time.ms), v.func, v.loopTime, v.count)
end
function Timer.UpdateM(v)
    Timer.Insert(v.id, m_utils.t2ms(0, 0, v.time.s, v.time.ms), v.func, v.loopTime, v.count)
end
function Timer.UpdateS(v)
    Timer.Insert(v.id, m_utils.t2ms(0, 0, 0, v.time.ms), v.func, v.loopTime, v.count)
end
function Timer.UpdateMS(v)
    Timer.Insert(v.id, m_utils.t2ms(0, 0, 0, 0), v.func, v.loopTime, v.count)
end
--查找某个id的计时任务的位子
--result
--wheelId  在哪个轮子
--wheelPos 对应轮子的哪个位置
--taskPos  任务的位置
function Timer.Seek(id)
    local result = false
    local wheelId, wheelPos, taskPos

    if Timer.timeTask[id] then
        local time = Timer.timeTask[id].time
        local h1, m1, s1, ms1 = m_utils.ms2t(Timer.cycle)

        if time.h ~= 0 and time.h ~= h1 then
            wheelId = 1
            wheelPos = time.h
            for i, v in ipairs(Timer.slots[1][time.h]) do
                if v.id == id then
                    taskPos = i
                    result = true
                    break ;
                end
            end
        elseif time.m ~= 0 and time.m ~= m1 then
            wheelId = 2
            wheelPos = time.m
            for i, v in ipairs(Timer.slots[2][time.m]) do
                if v.id == id then
                    taskPos = i
                    result = true
                    break ;
                end
            end
        elseif time.s ~= 0 and time.s ~= s1 then
            wheelId = 3
            wheelPos = time.s
            for i, v in ipairs(Timer.slots[3][time.s]) do
                if v.id == id then
                    taskPos = i
                    result = true
                    break ;
                end
            end
        elseif time.ms ~= 0 and time.ms ~= ms1 then
            wheelId = 4
            local tmp = math.floor(time.ms / Timer.interval)
            wheelPos = tmp == 0 and Timer.wheelSize or tmp
            for i, v in ipairs(Timer.slots[4][wheelPos]) do
                if v.id == id then
                    taskPos = i
                    result = true
                    break ;
                end
            end
        end
    end
    return result, wheelId, wheelPos, taskPos
end

return Timer