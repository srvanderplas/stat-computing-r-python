function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "panel-tabset" then
    -- Add the role attribute
    el.attributes["role"] = "button"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "column-margin" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "example" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "setup" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "callout-caution" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "demo" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "example" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "learnmore" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function Div (el)
  -- Check for a specific class or other criteria
  if el.attributes["class"] == "advanced" then
    -- Add the role attribute
    el.attributes["role"] = "dialog"
  end
  return el
end

function A (el)
  -- Check for a specific class or other criteria
  if el.attributes["append-hash"] then
    -- Add the role attribute
    el.attributes["append-hash"] = nil
  end
  return el
end