-- tbd
-- Nothing to see
-- Instructions here
-- And code maybe
-- Down there
-- m.devices[1]:program_change(2,1)
-- m.devices[1]:cc(102, 70, 1) 
-- m.devices[1]:program_change(2,2)
-- m.devices[1]:cc(14, 70, 2) 

UI = require("ui")
Graph = require("graph")

devices = {}
device_names = {}
midi = {}



midi_list = UI.ScrollingList.new(10, 6, 1, {1,2,3,4})
channel_list = UI.ScrollingList.new(20, 6, 1, {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16})
device_list = UI.ScrollingList.new(30, 6, 1, device_names)

default_device_list = util.scandir('/home/we/dust/code/geppetto/devices/')
local_device_list = util.scandir('/home/we/dust/data/geppetto/devices/')

for i, v in ipairs(default_device_list) do
  devices[i] = include('devices/'..v:gsub('.lua', ''))
  device_names[i] = devices[i].model
end

function init()
  view = 1
  
  math.randomseed(os.time())
  m.devices = {}
  -- midi.devices[1] = midi.connect(1)
  -- midi.devices[2] = midi.connect(2)
  -- midi.devices[3] = midi.connect(3)
  -- midi.devices[4] = midi.connect(4)
  print(#devices)
  redraw()
end

function enc(e, d)
  if e == 1 then
    view = util.clamp(view + d, 1, 4)
  end

  redraw()
end

function paintDevicesList()
  screen.font_face(1)
  
  midi_list:redraw()
  channel_list:redraw()
  device_list:redraw()
  -- screen.move(0,6)
  -- screen.text('io: '..1)
  -- screen.move(screen.text_extents('io: '..1) + 10, 6)
  -- screen.text('ch: '..1)
  -- screen.move(screen.text_extents('io: '..1) + 10 + screen.text_extents('ch: '..1) + 10, 6)
  -- screen.text(device_name)
  
end

function paintDeviceProperties()
  screen.move(0,6)
  screen.text('Device properties view')
end

function paintDeviceModulation()
  screen.move(0,6)
  screen.text('Device modulation view')

end

function paintPerformanceControls()
  screen.move(0,6)
  screen.text('Performance controls view')
end

function redraw()
  screen.clear()
  
  if view == 1 then
    paintDevicesList()
  elseif view == 2 then
    paintDeviceProperties()
  elseif view == 3 then
    paintDeviceModulation()
  elseif view == 4 then
    paintPerformanceControls()
  end

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
