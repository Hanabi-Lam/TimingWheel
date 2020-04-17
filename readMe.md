Lua_TimingWheel

- 初始化   在timer 做成单例 

```lua
timer.Init(100,math.floor(Time.realtimeSinceStartup*1000))
```

- 计时驱动

```lua
local t =0
function Update()    
    t = t+Time.deltaTime   
    if t >0.1 then  
        t = 0     
        timer.Update(math.floor(Time.realtimeSinceStartup*1000))  
    end
end
```

- 使用示例

  ```lua
     local tid1 = timer.AddTimeTask(5000,function ()
          print('5s后执行')
      end)
      timer.ReplaceTimeTask(tid1,function ()
          print('替换id为 tid1 的任务')
      end)
      local tid2 = timer.AddTimeTask(1000,function ()
          print('1s后执行,每2s循环，循环两次',Time.realtimeSinceStartup)
      end,2000,2)
  
      local tid4 = timer.AddTimeTask(0,function ()
          print('立即执行,每1s循环,次数10次',Time.realtimeSinceStartup)
      end,1000,10)
      local tid5 = timer.AddTimeTask(2000,function ()
          print('2s后执行,每1s循环，循环无数次',Time.realtimeSinceStartup)
      end,1000,0)
      timer.RemoveTimeTask(tid4) --删除tid4 的任务
      timer.RemoveAllTimeTask()--删除所有任务
  ```

