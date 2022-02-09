--1.订阅REC_STATE_ON和REC_STATE_0FF,标写_G.REC_STATE状态
--2。使用按键中断触发方式实现按键功能：
--屏亮亮时按下和抬起的时间超过2秒，翻转设备记录状态.时间超过15000进入和退出黑行模式。
--屏幕暗时按下按键唤醒设备亮屏。
module(..., package.seeall)
require "utils"
require "pm"
require "pins"

local rec_key = pio.P0_19 --记录键
local rec_key_down_start = 0--按键按下开始
local rec_key_down_end = 0 --按键按下结束
rec_key_down_flag = false--按键按下标志全局

-------------------------------------------------------------------------
function rec_key_while_recon()
    log.info("收到: REC_STATE_ON, 更改 _G.REC_STATE = true")
    _G.REC_STATE = true
end

function rec_key_while_recoff()
    log.info("收到: REC_STATE_OFF, 更改 _G.REC_STATE = false")
    _G.REC_STATE = false
end

sys.subscribe("REC_STATE_ON", rec_key_while_recon)
sys.subscribe("REC_STATE_OFF", rec_key_while_recoff)
--------------------------按键1 记录键-------------------------------------
function rec_keyIntFnc(msg)
    if _G.LCD_STATE then
        log.info("testGpioSingle.rec_keyIntFnc", msg, getrec_keyFnc())
        -- 上升沿中断
        if _G.SCREEN_STATE == 0 then--界面0下
            if msg == cpu.INT_GPIO_POSEDGE then--按键抬起
                rec_key_down_end = rtos.tick()
                log.warn("抬起", rec_key_down_end)
                rec_key_down_flag = false
                if rec_key_down_end - rec_key_down_start > 600 and rec_key_down_end - rec_key_down_start < 2000 then
                    _G.REC_STATE = not _G.REC_STATE--翻转记录状态
                    if _G.REC_STATE then
                        sys.publish("REC_STATE_ON")--发布记录状态
                        log.warn("...开启记录")
                    else
                        sys.publish("REC_STATE_OFF")--发布空闲转台
                        log.warn("...关闭记录")
                    end
                elseif rec_key_down_end - rec_key_down_start >= 1500 then--飞行模式
                    if not _G.FLY_STATE then
                        log.warn("********************************进入飞行模式")
                        _G.FLY_STATE = true
                        net.switchFly(true)
                        _G.SINGLE_QUERY = 0
                        _G.SCREEN_STATE = 0
                    else
                        log.warn("********************************退出飞行模式")
                        _G.FLY_STATE = false
                        net.switchFly(false)
                        _G.SINGLE_QUERY = 26
                        _G.SCREEN_STATE = 0
                    end
                end
                pm.sleep("REC_KEY")
            else --按键按下
                pm.wake("REC_KEY")
                rec_key_down_start = rtos.tick()
                log.warn("按下", rec_key_down_start)
                rec_key_down_flag = true
                task_auto_screenoff.oled_on_start = rtos.tick()
            end
        end
    else--屏幕关屏
        if msg == cpu.INT_GPIO_POSEDGE then
            pm.wake("REC_KEY")
            log.warn("点亮屏幕")
            _G.LCD_STATE = true
            sys.publish("LCD_STATE_ON")--发布点亮屏幕
            rec_key_down_flag = false
            pm.sleep("REC_KEY")
        end
    end
    pm.sleep("REC_KEY")
end

-- rec_key配置为中断，可通过getrec_keyFnc()获取输入电平，产生中断时，自动执行rec_keyIntFnc函数
getrec_keyFnc = pins.setup(rec_key, rec_keyIntFnc, pio.PULLUP)
