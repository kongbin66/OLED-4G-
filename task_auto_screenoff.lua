--订阅LCD_STATE_ON实现屏幕的自动关屏,关屏后发布LCD_STATE_OFF
module(..., package.seeall)
require "utils"
require "pm"

oled_on_start = 0--OLED亮屏开始时间全局
oled_on_last = 0--oled关屏时间全局

function autoscreenoff_while_lcdon()
    sys.taskInit(function()
        pm.wake("AUTO_OFF")
        log.info("AUTO_SCREENOFF 收到: LCD_STATE_ON ")
        oled_on_start = rtos.tick()
        oled_on_last = rtos.tick()
        while _G.LCD_STATE do
            oled_on_last = rtos.tick()
            if task_rec_key.rec_key_down_flag then--记录键再次按下延长亮屏时间
                oled_on_start = rtos.tick()
            end
            if oled_on_last - oled_on_start > 3000 then
                log.info("屏幕时间到, 自动息屏")
                sys.publish("LCD_STATE_OFF")--发布LCD_STATE_OFF
                break
            end
            sys.wait(1000)
        end
        pm.sleep("AUTO_OFF")
    end)
end

sys.subscribe("LCD_STATE_ON", autoscreenoff_while_lcdon)
