-- tbd
-- Nothing to see
-- Instructions here
-- And code maybe
-- Down there

UI = require("ui")
Graph = require("graph")

function init()
  devices = {}
  device_names = {}
  m = {}
  m.devices = {}
  m.devices[1] = midi.connect(1)
  m.devices[2] = midi.connect(2)
  m.devices[3] = midi.connect(3)
  m.devices[4] = midi.connect(4)

  default_device_list = util.scandir('/home/we/dust/code/geppetto/lib/devices/')
  local_device_list = util.scandir('/home/we/dust/data/geppetto/devices/')
  
  for i, v in ipairs(default_device_list) do
    devices[i] = include('lib/devices/'..v:gsub('.lua', ''))
    device_names[i] = devices[i].model
  end
  
  midi_list = UI.ScrollingList.new(10, 6, 1, {1,2,3,4})
  channel_list = UI.ScrollingList.new(20, 6, 1, {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16})
  device_list = UI.ScrollingList.new(30, 6, 0, device_names)
  program_list = UI.ScrollingList.new(90, 6, 0, {})
  
  app = {
    ui = {
      view = 1,
      views = {
        [1] = {
          active_field = 1,
          fields = {
            [1] = midi_list,
            [2] = channel_list,
            [3] = device_list
          }
        },
        [2] = {
          active_field = 1,
          fields = {
            [1] = program_list
          }
        },
        -- [3] = {
        --   active_field = 1,
        --   fields = {
        --     [1] = {}
        --   }
        -- },
        -- [4] = {
        --   active_field = 1,
        --   fields = {
        --     [1] = {}
        --   }
        -- }
      }
    }
  }

  redraw()
end

function enc(e, d)
  local view = app.ui.view
  local views = app.ui.views

  if e == 1 then
    app.ui.view = util.clamp(view + d, 1, #views)
  elseif e == 2 then
    views[view].active_field = util.clamp(views[view].active_field + d, 1, #app.ui.views[view].fields)
  elseif e == 3 then
    local previous_value = app.ui.views[view].fields[views[view].active_field].index
    -- when we move to oo design let's have an edge case handler for 0 index device programs
    app.ui.views[view].fields[views[view].active_field]:set_index_delta(d, true)
    local new_value = app.ui.views[view].fields[views[view].active_field].index

    if view == 1 and views[view].active_field == 3 and previous_value ~= new_value then
      app.ui.views[2].fields[1] = UI.ScrollingList.new(screen.text_extents('Program -> ') + 6, 6, 1, devices[new_value].program)
    end

  end

  redraw()
end

function transmit_program_change()
  local state = app.ui.views
  local channel = state[1].fields[2].index
  local connection = state[1].fields[1].index
  local program = state[2].fields[1].index

  m.devices[connection]:program_change(program, channel)
end

function transmit_control_change()
  -- m.devices[1]:cc(14, 70, 2) 
end

function transmit_event()
  -- clock, start, stop, continue
end

function handle_confirm()
  local view = app.ui.view

  if view == 2 then
    transmit_program_change()
  end
end

function handle_cancel()

end

function key(k, z)
  if k == 1 and z == 1 then
    shift = true
  elseif k == 1 and z == 0 then
    shift = false
  end

  if k == 2 and z == 0 then
    handle_cancel()
  elseif k == 3 and z == 0 then
    handle_confirm()
  end
end

function paintDevicesScrollingList()
  local view = app.ui.view
  local active_field = app.ui.views[1].active_field

  for i, v in ipairs(app.ui.views[view].fields) do
    if active_field == i then
      screen.font_face(1)
    else
      screen.font_face(20)
    end

    v:redraw()
  end
end

function paintDeviceProperties()
  local label = 'Program -> '
  screen.font_face(1)
  screen.move(0, 22)
  screen.text(label)
  app.ui.views[2].fields[1]:redraw()
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
  
  if app.ui.view == 1 then
    paintDevicesScrollingList()
  elseif app.ui.view == 2 then
    paintDeviceProperties()
  elseif app.ui.view == 3 then
    paintDeviceModulation()
  elseif app.ui.view == 4 then
    paintPerformanceControls()
  end

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
