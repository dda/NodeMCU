--------------------------------------------------------------------------------
-- TM1637 I2C module for NODEMCU
-- Stimulus HK
-- LICENCE: http://opensource.org/licenses/MIT
-- dda <dda@stimulus.hk>
-- adapted from https://github.com/Seeed-Studio/Grove_4Digital_Display/blob/master/DigitalTube/TM1637.h
-- https://www.seeedstudio.com/Grove---4-Digit-Display-p-1198.html
--------------------------------------------------------------------------------

local moduleName = ...
local M = {}
_G[moduleName] = M

-- Default value for i2c communication
local id = 0

--device address
local ADDR_AUTO = 0x40
local ADDR_FIXED = 0x44
local STARTADDR = 0xc0 
local POINT_ON = 1
local POINT_OFF = 0
local BRIGHT_DARKEST = 0
local BRIGHT_TYPICAL = 2
local BRIGHTEST = 7

local TubeTab = {
  0x3f, 0x06, 0x5b, 0x4f, 
  0x66, 0x6d, 0x7d, 0x07, 
  0x7f, 0x6f, 0x77, 0x7c, 
  0x39, 0x5e, 0x79, 0x71
}
-- 0~9, A, b, C, d, E, F                  

Clkpin=1
Datapin=2
PointFlag=0

function M.init(Clk, Data)
  Clkpin = Clk
  Datapin = Data
  gpio.mode(Clkpin, gpio.OUTPUT)
  gpio.mode(Datapin, gpio.OUTPUT)
  clearDisplay()
end

function M.writeByte(wr_data)
  count1=0
  for i=1,8,1 do
    gpio.write(Clkpin, gpio.LOW)
    if bit.band(wr_data, 0x01)==1 then
      gpio.write(Datapin, gpio.HIGH)
    else
      gpio.write(Datapin, gpio.LOW)
    end
    wr_data = bit.brshift(wr_data, 1)
    gpio.write(Clkpin, gpio.HIGH)
  end
  gpio.write(Clkpin, gpio.LOW)
  gpio.write(Datapin, gpio.HIGH)
  gpio.write(Clkpin, gpio.HIGH)
  gpio.mode(Datapin, gpio.INPUT)
  while gpio.read(Datapin) do
    count1=count1+1
    if count1 == 200 then
     gpio.mode(Datapin, gpio.OUTPUT)
     gpio.write(Datapin, gpio.LOW)
     count1=0
    end
    gpio.mode(Datapin, gpio.INPUT)
  end
  gpio.mode(Datapin, gpio.OUTPUT)
end

function M.start()
  gpio.write(Clkpin, gpio.HIGH)
  gpio.write(Datapin, gpio.HIGH)
  gpio.write(Datapin, gpio.LOW)
  gpio.write(Clkpin, gpio.LOW)
end

function M.stop()
  gpio.write(Clkpin, gpio.LOW)
  gpio.write(Datapin, gpio.LOW)
  gpio.write(Clkpin, gpio.HIGH)
  gpio.write(Datapin, gpio.HIGH)
end

function M.display(DispData)
  for i=1,4,1 do
    SegData[i] = DispData[i]
  end
  coding(SegData)
  start()
  writeByte(ADDR_AUTO)
  stop()
  start()
  writeByte(Cmd_SetAddr)
  for i=1,4,1 do
    writeByte(SegData[i])
  end
  stop()
  start()
  writeByte(Cmd_DispCtrl)
  stop()
end

function M.display(BitAddr, DispData)
  SegData = coding(DispData)
  start()
  writeByte(ADDR_FIXED)
  stop()
  start()
  writeByte(bit.bor(BitAddr, 0xc0))
  writeByte(SegData)
  stop()
  start()
  writeByte(Cmd_DispCtrl)
  stop()
end

function M.clearDisplay()
  display(0x00, 0x7f)
  display(0x01, 0x7f)
  display(0x02, 0x7f)
  display(0x03, 0x7f)
end

function M.set(brightness, SetData, SetAddr)
  Cmd_SetData = SetData
  Cmd_SetAddr = SetAddr
  Cmd_DispCtrl = 0x88 + brightness
end


function M.point(pFlag)
  PointFlag = pFlag
end

function M.coding(DispData)
  if(PointFlag == POINT_ON) then
    PointData = 0x80
  else
    PointData = 0
  end
  for i=1,4,1 do
    if(DispData[i] == 0x7f) then
      DispData[i] = 0x00
    else
      DispData[i] = TubeTab[DispData[i]] + PointData
    end
  end
end

function M.coding(DispData)
  if (PointFlag == POINT_ON) then
    PointData = 0x80
  else
    PointData = 0
  end
  if(DispData == 0x7f) then
    DispData = 0x00 + PointData
  else
    DispData = TubeTab[DispData] + PointData
  end
  return DispData
end


return M
