-- Run from a disposable copy of the game, with this file installed as main.lua.
assert(love.filesystem.load("game-under-test.lua"))()

local gameLoad, gameUpdate, gameDraw, gameKeypressed = love.load, love.update, love.draw, love.keypressed
local keyboardIsDown = love.keyboard.isDown
local stage = -1
local movementFrames = 0
local startX
local canvasChecked = false
local bodyScale, gunScale

local function assertVisibleCanvas()
	assert(shaders.outputcanvas == display.canvas, "shaders must render to the fullscreen canvas")
	local image = display.canvas:newImageData()
	local visiblePixels = 0
	for y = 0, image:getHeight() - 1, 40 do
		for x = 0, image:getWidth() - 1, 40 do
			local r, g, b = image:getPixel(x, y)
			if r + g + b > 0.1 then visiblePixels = visiblePixels + 1 end
		end
	end
	assert(visiblePixels > 10, "the fullscreen canvas must contain a visible rendered game")
end

local function fail(err)
	io.stderr:write(debug.traceback(tostring(err), 2) .. "\n")
	love.event.quit(1)
end

function love.load()
	local ok, err = xpcall(function()
		gameLoad()
		assert(not fullscreen, "game should start windowed with an empty configuration")
		menu_load()
		shaders:set(1, "CRT-Simple")
		shaders:set(2, "HDR-TV")
		love.event.push("keypressed", "f11", "f11", false)
	end, debug.traceback)
	if not ok then fail(err) end
end

function love.update()
	local ok, err = xpcall(function()
		gameUpdate(1/60)
		if stage == -1 then
			assert(fullscreen and display.canvas, "the F11 key event must enable fullscreen")
			assert(shaders.xres == gamewidth and shaders.yres == gameheight, "shaders must use game dimensions")
			stage = 0
		elseif stage == 0 and canvasChecked then
			local x, y, factor = display.viewport()
			local gameX, gameY = display.toGame(x + gamewidth * factor / 2, y + gameheight * factor / 2)
			assert(math.abs(gameX - gamewidth / 2) < 0.01 and math.abs(gameY - gameheight / 2) < 0.01, "mouse coordinates must match the scaled game")
			local oldMousePosition = love.mouse.getPosition
			love.mouse.getPosition = function() return x + gamewidth * factor / 2, y + gameheight * factor / 2 end
			local mouseX, mouseY = display.getMousePosition()
			assert(math.abs(mouseX - gameX) < 0.01 and math.abs(mouseY - gameY) < 0.01, "mouse polling must use game coordinates")
			love.mouse.getPosition = oldMousePosition

			local oldMenuMousepressed, oldGui = menu_mousepressed, guielements
			local clickX, clickY
			menu_mousepressed = function(px, py) clickX, clickY = px, py end
			guielements = {}
			love.mousepressed(x + gamewidth * factor / 2, y + gameheight * factor / 2, 1)
			assert(math.abs(clickX - gameX) < 0.01 and math.abs(clickY - gameY) < 0.01, "mouse clicks must use game coordinates")
			clickX, clickY = nil, nil
			love.mousepressed(x - 10, y - 10, 1)
			assert(clickX == nil and clickY == nil, "mouse clicks in fullscreen borders must be ignored")
			menu_mousepressed, guielements = oldMenuMousepressed, oldGui

			changescale(3)
			assert(fullscreen and display.canvas:getWidth() == gamewidth and shaders.xres == gamewidth, "scale changes must preserve fullscreen and resize shader targets")
			gameKeypressed("f11")
			assert(not fullscreen and not display.canvas, "F11 must restore windowed mode")
			assert(love.filesystem.read("options.txt"):find("fullscreen:false;", 1, true), "windowed preference must be saved")
			gameKeypressed("f11")
			assert(fullscreen and display.canvas, "F11 must re-enter fullscreen")
			assert(love.filesystem.read("options.txt"):find("fullscreen:true;", 1, true), "fullscreen preference must be saved")
			fullscreen = false
			loadconfig()
			assert(fullscreen, "the saved fullscreen preference must be restored")
			game_load()
			levelscreentimer = blacktime
			stage = 1
		elseif stage == 1 and gamestate == "game" then
			startX = objects.player[1].x
			love.mouse.getPosition = function() return 0, 0 end
			love.keyboard.isDown = function(key)
				return key == "right" or keyboardIsDown(key)
			end
			stage = 2
		elseif stage == 2 then
			movementFrames = movementFrames + 1
			if movementFrames == 30 then
				assert(objects.player[1].x > startX + 0.2, "right arrow must move Mario in the actual level")
				assert(objects.player[1].pointingangle > 0, "the mouse must still aim left")
				assert(bodyScale and bodyScale > 0, "Mario's rendered body must face right while moving right")
				assert(gunScale and gunScale < 0, "the rendered portal gun must still point left")
				local oldShootportal, shotDirection = shootportal, nil
				shootportal = function(_, _, _, _, direction) shotDirection = direction end
				game_mousepressed(0, 0, 1)
				shootportal = oldShootportal
				assert(shotDirection == objects.player[1].pointingangle, "portals must still be fired toward the mouse")
				assert(fullscreen and shaders.outputcanvas == display.canvas, "shader output must remain inside the fullscreen canvas")
				print("Game integration: fullscreen, shaders, mouse, movement and facing passed")
				love.event.quit(0)
			end
		end
	end, debug.traceback)
	if not ok then fail(err) end
end

function love.draw()
	local ok, err = xpcall(function()
		local draw = love.graphics.draw
		if stage == 2 then
			local player = objects.player[1]
			love.graphics.draw = function(image, ...)
				if image == player.graphic[1] then
					bodyScale = select(5, ...)
				elseif image == player.graphic[0] then
					gunScale = select(5, ...)
				end
				return draw(image, ...)
			end
		end
		gameDraw()
		love.graphics.draw = draw
		if stage == 0 and not canvasChecked then
			assertVisibleCanvas()
			shaders:set(2, nil)
			gameDraw()
			assertVisibleCanvas()
			shaders:set(1, nil)
			gameDraw()
			assertVisibleCanvas()
			shaders:set(1, "CRT-Simple")
			shaders:set(2, "HDR-TV")
			canvasChecked = true
		end
	end, debug.traceback)
	if not ok then fail(err) end
end
