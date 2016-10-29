id  = 0
sda = 2
scl = 1

-- initialize i2c, set pin1 as sda, set pin0 as scl
i2c.setup(id,sda,scl,i2c.SLOW)

for i=80,88 do
  i2c.start(id)
  resCode = i2c.address(id, i, i2c.TRANSMITTER)
  i2c.stop(id)
  if resCode == true then print("We have a device on address 0x" .. string.format("%02x", i) .. " (" .. i ..")") end
end

function i2c_eeprom_write_byte(dev_addr, eeaddress, data)
  rdata = 0xFF
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, bit.arshift(eeaddress, 8)) -- MSB
  i2c.write(id, bit.band(eeaddress, 255)) -- LSB
  i2c.write(id, bit.band(data, 255)) -- data
  i2c.stop(id)
end

function i2c_eeprom_read_byte(dev_addr, eeaddress)
  rdata = 0xFF
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, bit.arshift(eeaddress, 8)) -- MSB
  i2c.write(id, bit.band(eeaddress, 255)) -- LSB
  i2c.stop(id)
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.RECEIVER)
  c = i2c.read(id, 1)
  i2c.stop(id)
  return c
end

function testChip(ix)
  print("Testing EEPROM chip 0x" .. string.format("%02x", ix))
  x=0
  for i=0,7 do
    x=i*8192
    s="testing location 0x" .. string.format("%04x", x)
    i2c_eeprom_write_byte(ix, x, 128)
    tmr.delay(2000)
    n=i2c_eeprom_read_byte(ix, x)
    if (string.byte(n)==128) then
      print(s.." check")
    else
      print(s.." fail; n = 0x" .. string.format("%02x", string.byte(n)))
      i=8
    end
  end
  print("Capacity="..x+8192)
  print(node.heap())
end
