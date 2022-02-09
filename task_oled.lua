--- 模块功能：LCD适配
-- @author openLuat
-- @module ui.lcd
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27
-- 根据自己的lcd类型以及使用的spi引脚，打开下面的其中一个文件进行测试
-- mono表示黑白屏，color表示彩屏
-- std_spi表示使用标准的SPI引脚，lcd_spi表示使用LCD专用的SPI引脚
-- i2c表示使用i2c引脚
require "sys"
require "mono_lcd_spi_ssd1306"
require "utils"
require "common"
require "pm"
require "misc"

module(..., package.seeall)

function showInit()

end
function showWelcome()
    disp.clear()
    disp.putimage("/lua/welcome.bmp", 0, 0)
    disp.update()
end
function show_temp(temp)
    local th, tl = math.modf(math.abs(temp))
    local th_s, th_g = math.modf(math.abs(th) / 10)
    local temp_zs = th_s
    local temp_zg = math.floor(th_g * 10 + 0.5)
    local tl_1, tl_2 = math.modf(math.abs(tl) * 10)
    local temp_x1 = tl_1
    local temp_x2 = math.floor(tl_2 * 10 + 0.5)
    if temp < 0 then
        if temp_zs ~= 0 then
            disp.putimage("/lua/32x16_-.bmp", 15, 15)
        else
            disp.putimage("/lua/32x16_-.bmp", 31, 15)
        end
    end
    if temp_zs ~= 0 then
        disp.putimage(string.format("/lua/32x16_%d.bmp", temp_zs), 25, 15)
    end
    disp.putimage(string.format("/lua/32x16_%d.bmp", temp_zg), 41, 15)
    disp.putimage("/lua/32x16_dot.bmp", 57, 15)
    disp.putimage(string.format("/lua/32x16_%d.bmp", temp_x1), 65, 15)
    disp.putimage(string.format("/lua/32x16_%d.bmp", temp_x2), 81, 15)
end
function ui_draw_singnal()
    if _G.SINGLE_QUERY > 25 then
        disp.drawrect(14, 2, 16, 12, 0x0000)
    end
    if _G.SINGLE_QUERY > 20 then
        disp.drawrect(11, 4, 13, 12, 0x0000)
    end
    if _G.SINGLE_QUERY > 15 then
        disp.drawrect(8, 6, 10, 12, 0x0000)
    end
    if _G.SINGLE_QUERY > 10 then
        disp.drawrect(5, 8, 7, 12, 0x0000)
    end
    if _G.SINGLE_QUERY > 0 then
        disp.drawrect(2, 10, 4, 12, 0x0000)
    end
    if _G.SINGLE_QUERY <= 0 then
        disp.drawrect(2, 5, 14, 7, 0x0000)
    end
end
function ui_draw_clock()
    -- 显示时间
    local tm = misc.getClock()
    local tm_h_str = string.format("%2d", tm.hour)
    local tm_h_str_h = string.sub(tm_h_str, 1, 1)
    if tm_h_str_h == " " then
        tm_h_str_h = "0"
    end
    local tm_h_str_l = string.sub(tm_h_str, 2, 2)
    local tm_m_str = string.format("%2d", tm.min)
    local tm_m_str_h = string.sub(tm_m_str, 1, 1)
    if tm_m_str_h == " " then
        tm_m_str_h = "0"
    end
    local tm_m_str_l = string.sub(tm_m_str, 2, 2)
    local tm_s_str = string.format("%2d", tm.sec)
    local tm_s_str_h = string.sub(tm_s_str, 1, 1)
    if tm_s_str_h == " " then
        tm_s_str_h = "0"
    end
    local tm_s_str_l = string.sub(tm_s_str, 2, 2)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_h_str_h), 68, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_h_str_l), 74, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", "mao"), 80, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_m_str_h), 84, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_m_str_l), 90, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", "mao"), 96, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_s_str_h), 99, 1)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_s_str_l), 105, 1)
    -- 显示日期
    local tm_y_str = string.format("%4d", tm.year)
    local tm_y_str_h = string.sub(tm_y_str, 3, 3)
    local tm_y_str_l = string.sub(tm_y_str, 4, 4)
    local tm_mo_str = string.format("%2d", tm.month)
    local tm_mo_str_h = string.sub(tm_mo_str, 1, 1)
    if tm_mo_str_h == " " then
        tm_mo_str_h = "0"
    end
    local tm_mo_str_l = string.sub(tm_mo_str, 2, 2)
    local tm_d_str = string.format("%2d", tm.day)
    local tm_d_str_h = string.sub(tm_d_str, 1, 1)
    if tm_d_str_h == " " then
        tm_d_str_h = "0"
    end
    local tm_d_str_l = string.sub(tm_d_str, 2, 2)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_y_str_h), 74, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_y_str_l), 80, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", "xie"), 86, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_mo_str_h), 92, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_mo_str_l), 98, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", "xie"), 104, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_d_str_h), 110, 52)
    disp.putimage(string.format("/lua/font12x6_%s.bmp", tm_d_str_l), 116, 52)
end
function ui_draw_rec()
    if _G.REC_STATE then
        local rec_w = string.format("%5d", _G.REC_count)
        local rec_w5 = string.sub(rec_w, 1, 1)
        local rec_w4 = string.sub(rec_w, 2, 2)
        local rec_w3 = string.sub(rec_w, 3, 3)
        local rec_w2 = string.sub(rec_w, 4, 4)
        local rec_w1 = string.sub(rec_w, 5, 5)
        if _G.REC_count >= 10000 then
            disp.putimage(string.format("/lua/font12x6_%s.bmp", rec_w5), 13, 52)
        end
        if _G.REC_count >= 1000 then
            if rec_w4 == " " then
                disp.putimage(string.format("/lua/font12x6_%s.bmp", 0), 19, 52)
            else
                disp.putimage(string.format("/lua/font12x6_%s.bmp", rec_w4), 19, 52)
            end
        end
        if _G.REC_count >= 100 then
            if rec_w3 == " " then
                disp.putimage(string.format("/lua/font12x6_%s.bmp", 0), 25, 52)
            else
                disp.putimage(string.format("/lua/font12x6_%s.bmp", rec_w3), 25, 52)
            end
        end
        if _G.REC_count >= 10 then
            if rec_w2 == " " then
                disp.putimage(string.format("/lua/font12x6_%s.bmp", 0), 31, 52)
            else
                disp.putimage(string.format("/lua/font12x6_%s.bmp", rec_w2), 31, 52)
            end
        end
        disp.putimage(string.format("/lua/font12x6_%s.bmp", rec_w1), 37, 52)
    end
end
function ui_draw_battery()
    _G.BATT_CHARGING = misc.getVbus()
    if _G.BATT_CHARGING then
        _G.BATT_LEV = _G.BATT_LEV + 4
        if _G.BATT_LEV > 120 then
            _G.BATT_LEV = 21
        end
    else
        _G.BATT_VAL = misc.getVbatt()
        -- log.info()
        if _G.BATT_VAL > 4008 then
            _G.BATT_LEV = 100
        elseif _G.BATT_VAL > 3842 then
            _G.BATT_LEV = 80
        elseif _G.BATT_VAL > 3678 then
            _G.BATT_LEV = 60
        elseif _G.BATT_VAL > 3514 then
            _G.BATT_LEV = 40
        elseif _G.BATT_VAL > 3350 then
            _G.BATT_LEV = 10
        else
            _G.BATT_LEV = 0
        end
    end
    if _G.BATT_LEV >= 100 then
        disp.putimage("/lua/batt_100.bmp", 113, 3)
    elseif _G.BATT_LEV >= 80 then
        disp.putimage("/lua/batt_80.bmp", 113, 3)
    elseif _G.BATT_LEV >= 60 then
        disp.putimage("/lua/batt_60.bmp", 113, 3)
    elseif _G.BATT_LEV >= 40 then
        disp.putimage("/lua/batt_40.bmp", 113, 3)
    elseif _G.BATT_LEV >= 10 then
        disp.putimage("/lua/batt_10.bmp", 113, 3)
    else
        disp.putimage("/lua/batt_00.bmp", 113, 3)
    end
end
function show_ui(rec_state)
    if rec_state then
        disp.putimage("/lua/sc_main.bmp", 0, 0)
    else
        disp.putimage("/lua/sc_main_off.bmp", 0, 0)
    end
    ui_draw_singnal()
    ui_draw_clock()
    ui_draw_rec()
    ui_draw_battery()
end
function showLoop()
    disp.clear()
    show_ui(_G.REC_STATE)
    show_temp(_G.temp)
    disp.update()
end
function lcd_while_lcdon()
    log.info("收到: LCD_STATE_ON")
    pm.wake("LCD")
    disp.sleep(0)
    sys.taskInit(function()
        while _G.LCD_STATE do
            if _G.SCREEN_STATE == 0 then
                showLoop()
            end
            sys.wait(200)
        end
    end)
end

function lcd_while_lcdoff()
    log.info("收到: LCD_STATE_OFF 熄灭屏幕!")
    _G.LCD_STATE = false
    _G.SCREEN_STATE = 0
    disp.sleep(1)
    pm.sleep("SCREEN_KEY")
    pm.sleep("LCD")
end

sys.subscribe("LCD_STATE_ON", lcd_while_lcdon)
sys.subscribe("LCD_STATE_OFF", lcd_while_lcdoff)

sys.taskInit(function()
    showInit()
    showWelcome()
    sys.wait(3000)
    sys.publish("LCD_WELCOME_DONE")
    log.info("sys.publish(LCD_WELCOME_DONE)")
end)
