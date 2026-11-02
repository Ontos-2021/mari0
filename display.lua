local display = {}

-- Keep the game's original coordinate system and fit it to the desktop without stretching.
function display.calculateViewport(windowWidth, windowHeight, gameWidth, gameHeight)
	local factor = math.min(windowWidth / gameWidth, windowHeight / gameHeight)
	return (windowWidth - gameWidth * factor) / 2, (windowHeight - gameHeight * factor) / 2, factor
end

function display.transformPoint(x, y, offsetX, offsetY, factor)
	return (x - offsetX) / factor, (y - offsetY) / factor
end

function display.setMode(gameWidth, gameHeight, fullscreen, vsync)
	local windowWidth = fullscreen and 0 or gameWidth
	local windowHeight = fullscreen and 0 or gameHeight
	local ok = love.window.setMode(windowWidth, windowHeight, {
		fullscreen = fullscreen,
		fullscreentype = "desktop",
		vsync = vsync,
	})
	if not ok then
		return false
	end

	display.gameWidth, display.gameHeight = gameWidth, gameHeight
	if fullscreen then
		display.canvas = love.graphics.newCanvas(gameWidth, gameHeight)
		display.canvas:setFilter("nearest", "nearest")
	else
		display.canvas = nil
	end
	return true
end

function display.viewport()
	if not display.canvas then
		return 0, 0, 1
	end
	local windowWidth, windowHeight = love.window.getMode()
	return display.calculateViewport(windowWidth, windowHeight, display.gameWidth, display.gameHeight)
end

function display.toGame(x, y)
	local offsetX, offsetY, factor = display.viewport()
	return display.transformPoint(x, y, offsetX, offsetY, factor)
end

function display.contains(x, y)
	return x >= 0 and y >= 0 and x < display.gameWidth and y < display.gameHeight
end

function display.getMousePosition()
	return display.toGame(love.mouse.getPosition())
end

function display.getMouseX()
	local x = display.getMousePosition()
	return x
end

function display.getMouseY()
	local _, y = display.getMousePosition()
	return y
end

function display.beginDraw()
	if display.canvas then
		love.graphics.setCanvas(display.canvas)
		love.graphics.clear(love.graphics.getBackgroundColor())
	end
end

function display.endDraw()
	if not display.canvas then
		return
	end

	love.graphics.setCanvas()
	love.graphics.push("all")
	love.graphics.origin()
	love.graphics.setScissor()
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBlendMode("alpha", "premultiplied")
	local x, y, factor = display.viewport()
	love.graphics.draw(display.canvas, x, y, 0, factor, factor)
	love.graphics.pop()
end

return display
