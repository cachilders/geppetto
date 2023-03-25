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
include('lib/device')

CC_LABEL = 'CC -> '
PROGRAM_LABEL = 'Program -> '

function init()
  init_midi()
  init_device_configurations()
  init_lfo_controls()
  init_inputs()
  init_state()

  screen.font_face(1)

  redraw()
end

function init_state()
  -- Streamline and make persistent (optionally)

  active_device = nil
  play_status = UI.PlaybackIcon.new(122, 0, 5, 4)
  app = {
    ui = {
      playing = false,
      view = 1,
      views = {
        [1] = {
          active_field = 3,
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
end

function init_inputs()
    -- These inputs were originally the scrolling select and will need more positioning flexibility on subsequent refactor
    midi_list = inputs.Select:new({ x = 0, y = 14, selected = 1, options = {1,2,3,4}, action = function(v) safe_set_device_prop('midi_port', v) end})
    channel_list = inputs.Select:new({ x = 20, y = 14, selected = 1, options = m.channels,  action = function(v) safe_set_device_prop('midi_channel', v) end})
    device_list = inputs.Select:new({ x = 40, y = 14, options = device_names, action = update_device})
    min_list = inputs.Select:new({ x = 0, y = 37, selected = 1, options = midi_range, action = function(v) safe_set_device_lfo_prop('min', v) end})
    max_list = inputs.Select:new({ x = 20, y = 37, selected = 128, options = midi_range, action = function(v) safe_set_device_lfo_prop('max', v) end})
    depth_list = inputs.Select:new({ x = 40, y = 37, selected = 100, options = depth_range, action = function(v) safe_set_device_lfo_prop('depth', calculate_depth(v)) end})
    shape_list = inputs.Select:new({ x = 60, y = 37, selected = 1, options = shape_options, action = function(v) safe_set_device_lfo_prop('shape', shape_options[v]) end})
    baseline_list = inputs.Select:new({ x = 95, y = 37, selected = 1, options = baseline_options, action = function(v) safe_set_device_lfo_prop('baseline', baseline_options[v]) end})
    control_list = inputs.Select:new({ x = screen.text_extents(CC_LABEL) + 6, y = 47, action = function(v) safe_set_device_prop('modulated_control', v) end})
    program_list = inputs.Select:new({ x = screen.text_extents(PROGRAM_LABEL) + 6, y = 61, action = function(v) safe_set_device_prop('selected_program', v) end})
end

function init_midi()
  local IO = 4
  local CH = 16

  m = {
    channels = {},
    ports = {}
  }

  for i=1, IO do
    m.ports[i] = midi.connect(i)
    m.ports[i].event = function(d)
      local msg = midi.to_msg(d)
      handle_midi_event(msg.type, i)
    end
  end

  for i=1, CH do
    m.channels[i] = i
  end
end

function init_device_configurations()
  device_configurations = {}
  device_names = {}

  local default_device_list = util.scandir('/home/we/dust/code/geppetto/lib/devices/')

  for i, v in ipairs(default_device_list) do
    device_configurations[i] = include('lib/devices/'..v:gsub('.lua', ''))
    device_names[i] = device_configurations[i].model
  end
end

function init_lfo_controls()
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
end


function calculate_depth(n)
  return n / 100
end

function safe_set_device_prop(k, v)
  -- this whole control scheme will have to change as app grows,
  -- but doing this for initial class migration
  if active_device then
    active_device[k] = v
  end
end

function safe_set_device_lfo_prop(k, v)
  -- see note in safe set device prop
  if active_device then
    active_device.lfo:set(k, v)
  end
end

function enc(e, d)
  local view = app.ui.view
  local views = app.ui.views
  local active_field = views[view].active_field
  local fields = views[view].fields

  if e == 1 then
    -- future home of view nav
    app.ui.view = util.clamp(view + d, 1, #views)
  elseif e == 2 then
    -- Suspending navigation around inputs until device has been chosen
    -- rather than resolve some bugs that will be irrelevant when app
    -- allows multiple devices
    if active_device then
      views[view].active_field = util.clamp(active_field + d, 1, #fields)
    end
  elseif e == 3 then
      fields[active_field]:set_index_delta(d, false)
  end

  redraw()
end

function update_device(v)
  local fields = app.ui.views[1].fields
  local last_device = active_device and active_device.make..active_device.model or ''
  local next_device = device_configurations[v].make..device_configurations[v].model

  if next_device ~= last_device then
    if active_device then
      active_device:rebase(device_configurations[v])
    else
      active_device = Device:new(device_configurations[v])
    end

    fields[9]:set('selected', 0)
    fields[9]:set('options', active_device.control_options)
    fields[10]:set('selected', 0)
    fields[10]:set('options', active_device.program)
  end
end

function handle_confirm()
  local view = app.ui.view
  local views = app.ui.views
  local active_field = views[view].active_field

  if view == 1 and active_field == 10 and active_device then
    active_device:transmit_program_change()
  elseif active_device then
    play()
  end
end

function handle_cancel()
  if active_device then
    stop()
  end
end

function handle_midi_event(event, port)
  if active_device and active_device.midi_port == port then
    if event == 'start' then
      play()
    elseif event == 'stop' then
      stop()
    end
  end
end

function play()
  active_device:start()
  app.ui.playing = true
end

function stop()
  active_device:stop()
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
    screen.text_right(active_device.lfo_modulation_value or '')
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
