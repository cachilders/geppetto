inputs = {
  Select = {
    x = 0,
    y = 0,
    w = 20,
    font_face = 1,
    options = {},
    selected = 0,
    active = false,
    action = function() end,
    disabled = false
  }
}

function inputs.Select:new(options)
  local instance = options or {}
  setmetatable(instance, self)
  self.__index = self
  return instance
end

function inputs.Select:set(k, v)
  self[k] = v
end

function inputs.Select:get(k)
  return self[k]
end

function inputs.Select:set_index_delta(d)
  self.selected = util.clamp(self.selected + d, 1, #self.options)
  self.action(self.selected)
end

function inputs.Select:redraw()
  local value = self.options[self.selected] or '<SELECT>'
  screen.font_face(self.font_face)
  screen.move(self.x, self.y)

  if self.active then
    local w = self.x + screen.text_extents(value)

    screen.level(5)
    screen.move(self.x, self.y + 3)
    screen.line(w, self.y + 3)
    screen.stroke()
    screen.level(15)
  else
    screen.level(5)
  end

  screen.move(self.x, self.y)
  screen.text(value)
end

return inputs