Device = {
  control_channels = {},
  control_options = {},
  lfo_modulation_value = 0,
  make = '',
  midi_port = 1,
  midi_channel = 1,
  model = '',
  modulated_control = 0,
  modulated_controls = {},
  programs = {},
  selected_program = 0
}

function _configure(configuration)
  configuration.control_options = {}
  configuration.control_channels = {}
  configuration.programs = {}
  
  local i = 1

  for ch, name in pairs(configuration.control) do
    configuration.control_options[i] = ch..': '..name
    configuration.control_channels[i] = ch
    i = i + 1
  end

  return {
    control_channels = configuration.control_channels,
    control_options = configuration.control_options,
    make = configuration.make,
    model = configuration.model,
    modulated_control = 0,
    modulated_controls = {},
    program = configuration.program,
    program_zero_indexed = configuration.program_zero_indexed,
    selected_program = 0
  }
end

function _initiate_lfo(instance)
  instance.lfo = LFO:add{
    action = function(v) instance:_lfo_action(v) end,
    baseline = 'center',
    depth = 1,
    max = 128,
    min = 1,
    mode = 'clocked',
    offset = 0,
    period = 4,
    ppqn = 48,
    reset_target = 'floor',
    shape = 'sine'
  }
end

function Device:_lfo_action(scaled)
  self.lfo_modulation_value = math.ceil(scaled - .5) - 1

  for k, v in pairs(self.modulated_controls) do
    -- TODO: calculate per cc value with spatial offsets for plotted position on LFO
    m.ports[self.midi_port]:cc(self.control_channels[v], mod_value, self.midi_channel) 
  end

  -- temp till multiple controls is implemented
  local cc = self.control_channels[self.modulated_control]
  m.ports[self.midi_port]:cc(cc, self.lfo_modulation_value, self.midi_channel) 

  redraw()
end

function Device:new(configuration)
  local instance = _configure(configuration) or {}
  setmetatable(instance, self)
  self.__index = self
  _initiate_lfo(instance)

  return instance
end

function Device:update(t)
  for k, v in pairs(t) do
    self[k] = v
  end
end

function Device:rebase(configuration)
  self:stop()
  self:update(_configure(configuration))
end

function Device:set(k, v)
  self[k] = v
end

function Device:get(k)
  -- something is off with this getter
  return self[k]
end

function Device:retire()
  self:stop()
  self = nil
end

function Device:transmit_program_change()
  local program = self.selected_program
  
  if self.program_zero_indexed then
    program = program - 1
  end

  m.ports[self.midi_port]:program_change(program, self.midi_channel) 
end

function Device:start()
  self.lfo:start()
  m.ports[self.midi_port]:start()
end

function Device:stop()
  self.lfo:stop()
  m.ports[self.midi_port]:stop()
end

return Device