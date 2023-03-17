-- tbd
-- Nothing to see
-- Instructions here
-- And code maybe
-- Down there

m = {}
test = include('devices/hologram_microcosm')
devices = {}
devices[1] = test


function init()
  -- global ui state
  view = 1
  -- end guis
  
  screen.font_face(1)

  math.randomseed(os.time())
  m.devices = {}
  m.devices[1] = midi.connect(1)
  m.devices[2] = midi.connect(2)
  m.devices[3] = midi.connect(3)
  m.devices[4] = midi.connect(4)

  redraw()
end

function enc(e, d)
  if e == 1 then
    view = util.clamp(view + d, 1, 4)
    print('sup')
  end

  redraw()
end

function redraw()
  -- m.devices[1]:program_change(2,1)
  m.devices[1]:cc(102, 70, 1) 
  -- m.devices[1]:program_change(2,2)
  -- m.devices[1]:cc(14, 70, 2) 
  screen.clear()
  screen.move(0,6)
  screen.text(devices[1].make..' -> '..devices[1].model)
  screen.move(0,12)
  screen.text('Screen '..view)
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
