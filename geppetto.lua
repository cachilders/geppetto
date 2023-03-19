-- Geppetto
-- A lil midi controller
--
-- E2 - Navigate  E3 - Select
-- K3 - Start LFO K2 - Stop LFO
--
-- K3 - Send program change
--      from program field

UI = require('ui')
Graph = require('graph')
LFO = require('lfo')

include('lib/inputs')

CC_LABEL = 'CC -> '
PROGRAM_LABEL = 'Program -> '

function init()
  init_midi()
  init_devices()
  init_lfo()

  screen.font_face(1)
  
  play_status = UI.PlaybackIcon.new(122, 0, 5, 4)

  midi_list = Inputs.Select:new({ x = 0, y = 14, selected = 1, options = {1,2,3,4}})
  channel_list = Inputs.Select:new({ x = 20, y = 14, selected = 1, options = m.channels})
  device_list = Inputs.Select:new({ x = 40, y = 14, options = device_names, action = update_device_control_options})
  min_list = Inputs.Select:new({ x = 0, y = 37, selected = 1, options = midi_range, action = function(v) mod_lfo:set('min', v) end})
  max_list = Inputs.Select:new({ x = 20, y = 37, selected = 128, options = midi_range, action = function(v) mod_lfo:set('max', v) end})
  depth_list = Inputs.Select:new({ x = 40, y = 37, selected = 100, options = depth_range, action = function(v) mod_lfo:set('depth', calculate_depth(v)) end})
  shape_list = Inputs.Select:new({ x = 60, y = 37, selected = 1, options = shape_options, action = function(v) mod_lfo:set('shape', shape_options[v]) end})
  baseline_list = Inputs.Select:new({ x = 95, y = 37, selected = 1, options = baseline_options, action = function(v) mod_lfo:set('baseline', baseline_options[v]) end})
  control_list = Inputs.Select:new({ x = screen.text_extents(CC_LABEL) + 6, y = 47})
  program_list = Inputs.Select:new({ x = screen.text_extents(PROGRAM_LABEL) + 6, y = 61})

  app = {
    ui = {
      playing = false,
      view = 1,
      views = {
        [1] = {
          active_field = 1,
          fields = {
            -- midi
            [1] = midi_list,
            [2] = channel_list,
            [3] = device_list,
            -- modulation
            [4] = min_list,
            [5] = max_list,
            [6] = depth_list,
            [7] = shape_list,
            [8] = baseline_list,
            [9] = control_list,
            -- program change
            [10] = program_list
          }
        },
      }
    }
  }

  redraw()
end

function init_midi()
  local IO = 4
  local CH = 16

  m = {
    channels = {},
    devices = {}
  }

  for i=1, IO do
    m.devices[i] = midi.connect(i)
  end

  for i=1, CH do
    m.channels[i] = i
  end
end

function init_devices()
  devices = {}
  device_names = {}

  local default_device_list = util.scandir('/home/we/dust/code/geppetto/lib/devices/')

  for i, v in ipairs(default_device_list) do
    devices[i] = include('lib/devices/'..v:gsub('.lua', ''))
    device_names[i] = devices[i].model
  end
end

function lfo_test(scaled, raw)
  mod_value = math.ceil(scaled - .5) - 1
  transmit_control_change(mod_value)
  redraw()
end

function calculate_depth(n)
  return 1 * n / 100
end

function init_lfo()
  depth_range = {}
  midi_range = {}
  period_options = {1, 2, 4, 8, 16, 32, 64}
  shape_options = {'sine', 'saw', 'square', 'random'}
  baseline_options = {'min', 'center', 'max'}

  local DEPTH = 100
  local MAX = 128

  for i=1, DEPTH do
    depth_range[i] = i
  end

  for i=1, MAX do
    midi_range[i] = i
  end

  mod_lfo = LFO:add{
    shape = 'sine',
    min = 1,
    max = 128,
    depth = 1,
    mode = 'clocked',
    period = 4,
    action = lfo_test,
    baseline = 'center',
    reset_target = 'floor',
    ppqn = 96
  }
end

function enc(e, d)
  local view = app.ui.view
  local views = app.ui.views
  local active_field = views[view].active_field
  local fields = views[view].fields

  if e == 1 then
    -- time makes fools of us all
    app.ui.view = util.clamp(view + d, 1, #views)
    -- dream big but cut scope
  elseif e == 2 then
    views[view].active_field = util.clamp(active_field + d, 1, #fields)
  elseif e == 3 then
    fields[active_field]:set_index_delta(d, false)
  end

  redraw()
end

function update_device_control_options(v)
  local fields = app.ui.views[1].fields

  handle_cancel()
  create_device_cc_tables(devices[v].control)
  
  fields[9]:set('selected', 0)
  fields[9]:set('options', control_options)
  fields[10]:set('selected', 0)
  fields[10]:set('options', devices[v].program)
end

function create_device_cc_tables(controls)
  control_options = {}
  control_channels = {}

  local i = 1

  for ch, name in pairs(controls) do
    control_options[i] = ch..': '..name
    control_channels[i] = ch
    i = i + 1
  end
end

function transmit_program_change()
  local views = app.ui.views
  local fields = views[1].fields

  local device = devices[fields[3].selected]
  local channel = fields[2].selected
  local connection = fields[1].selected
  local program = fields[10].selected

  if device.program_zero_indexed then
    program = program - 1
  end

  m.devices[connection]:program_change(program, channel)
end

function transmit_control_change(v)
  local views = app.ui.views
  local fields = views[1].fields

  if control_channels then
    m.devices[fields[1].selected]:cc(control_channels[fields[9].selected], v, fields[2].selected) 
  end
end

function transmit_event()
  -- tk clock, start, stop, continue
end

function handle_confirm()
  local view = app.ui.view
  local views = app.ui.views
  local active_field = views[view].active_field

  if view == 1 and active_field == 10 then
    transmit_program_change()
  else
    mod_lfo:start()
    app.ui.playing = true
  end
end

function handle_cancel()
  mod_lfo:stop()
  app.ui.playing = false
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

  redraw()
end

function paint_play_status()
  if app.ui.playing then
    play_status.active = true
    play_status.status = 1
  else
    play_status.active = false
    play_status.status = 4
  end

  play_status:redraw()
end

function paint_mod_value()
  if app.ui.playing then
    screen.level(15)
    screen.move(120, 5)
    screen.text_right(mod_value or '')
  end
end

function paint_control_form()
  local view = app.ui.views[1]
  local fields = view.fields
  local active_field = view.active_field
  local labels = {'IO', 'CH', 'Device', 'MIN', 'MAX', '%', 'Shape', 'Base'}
  local x = 0
  local y = 6

  screen.level(15)

  for i=1, 3 do
    if active_field == i then
      screen.level(15)
      fields[i]:set('active', true)
    else
      screen.level(5)
      fields[i]:set('active', false)
    end

    screen.move(x, y)
    screen.text(labels[i])

    fields[i]:redraw()

    x = x + 20
  end

  screen.move(0, 20)
  screen.line(128, 20)

  x = 0
  y = 29

  for i=4, 8 do
    if active_field == i then
      screen.level(15)
      fields[i]:set('active', true)
    else
      screen.level(5)
      fields[i]:set('active', false)
    end

    screen.move(x, y)
    screen.text(labels[i])

    fields[i]:redraw()

    if i ~= 7 then
      x = x + 20
    else
      x = x + 35
    end
  end

  if active_field == 9 then
    screen.level(15)
    fields[9]:set('active', true)
  else
    screen.level(5)
    fields[9]:set('active', false)
  end

  screen.move(0, 47)
  screen.text(CC_LABEL)

  fields[9]:redraw()

  screen.level(5)
  screen.move(0, 53)
  screen.line(128, 53)

  if active_field == 10 then
    screen.level(15)
    fields[10]:set('active', true)
  else
    screen.level(5)
    fields[10]:set('active', false)
  end

  screen.move(0, 61)
  screen.text(PROGRAM_LABEL)

  fields[10]:redraw()

  screen.stroke()
end

function redraw()
  screen.clear()

  paint_control_form()
  paint_play_status()
  paint_mod_value()

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
