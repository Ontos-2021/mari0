local function equal(actual, expected, message)
	assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local function near(actual, expected, message)
	assert(math.abs(actual - expected) < 0.0001, string.format("%s: expected %s, got %s", message, expected, actual))
end

local function testMovement()
	movement = dofile("movement.lua")
	dofile("game.lua")

	local pressed = {}
	love.keyboard.isDown = function(key) return pressed[key] or false end
	love.joystick.getJoysticks = function() return {} end

	local function keyboardControls()
		return {
			left = {"a"}, right = {"d"}, up = {"w"}, down = {"s"},
			jump = {"space"}, run = {"lshift"}, reload = {"r"}, use = {"e"},
			portal1 = {""}, portal2 = {""},
		}
	end

	controls = {keyboardControls(), keyboardControls()}
	players = 1
	editormode = false
	pausemenuopen = false
	endpressbutton = false

	local leftEvents, rightEvents = 0, 0
	objects = {player = {{
		leftkey = function() leftEvents = leftEvents + 1 end,
		rightkey = function() rightEvents = rightEvents + 1 end,
	}}}

	pressed.right = true
	equal(rightkey(1), true, "right arrow moves player one")
	game_keypressed("right")
	equal(rightEvents, 1, "right arrow triggers direction press")
	pressed.right = false
	pressed.d = true
	equal(rightkey(1), true, "existing D binding still works")
	pressed.d = false

	pressed.left = true
	equal(leftkey(1), true, "left arrow moves player one")
	game_keypressed("left")
	equal(leftEvents, 1, "left arrow triggers direction press")
	pressed.left = false
	pressed.down = true
	equal(downkey(1), true, "down arrow ducks and enters pipes")
	pressed.down = false
	pressed.up = true
	equal(upkey(1), true, "up arrow climbs")
	pressed.up = false

	controls[1].jump = {"up"}
	pressed.up = true
	equal(upkey(1), false, "an explicitly assigned key is not stolen from another action")
	pressed.up = false
	controls[2].right = {"right"}
	players = 2
	pressed.right = true
	equal(rightkey(1), false, "an arrow assigned to another player is not stolen")
	equal(rightkey(2), true, "another player's configured arrow still works")
end

local function testViewport()
	local display = dofile("display.lua")
	local x, y, factor = display.calculateViewport(1280, 800, 400, 224)
	near(x, 0, "viewport horizontal offset")
	near(y, 41.6, "viewport vertical offset")
	near(factor, 3.2, "viewport scale")
	local gameX, gameY = display.transformPoint(640, 400, x, y, factor)
	near(gameX, 200, "mouse horizontal coordinate")
	near(gameY, 112, "mouse vertical coordinate")
end

local function testFacing()
	local player = {controlsenabled = true, vine = false, rotation = 0, speedx = 2, pointingangle = 1}
	local body, aim = movement.facing(player)
	equal(body, 1, "Mario faces right while moving right")
	equal(aim, -1, "the portal gun continues to aim left")
	player.speedx, player.pointingangle = -2, -1
	body, aim = movement.facing(player)
	equal(body, -1, "Mario faces left while moving left")
	equal(aim, 1, "the portal gun continues to aim right")
	player.animation = "invincible"
	body, aim = movement.facing(player)
	equal(body, -1, "Mario faces the direction of movement when invincible")
	player.animation = nil
	player.speedx = 0
	body, aim = movement.facing(player)
	equal(body, aim, "Mario follows the aim when stationary")
	player.speedx, player.rotation = 2, math.pi / 2
	body, aim = movement.facing(player)
	equal(body, aim, "portal rotation retains the original orientation")
	player.rotation, player.vine = 0, true
	body, aim = movement.facing(player)
	equal(body, aim, "climbing retains the original orientation")
	player.vine, player.controlsenabled = false, false
	body, aim = movement.facing(player)
	equal(body, aim, "scripted animations retain the original orientation")
end

function love.load()
	local ok, err = xpcall(function()
		testMovement()
		testFacing()
		testViewport()
	end, debug.traceback)
	if ok then
		print("Movement and fullscreen viewport tests passed")
		love.event.quit(0)
	else
		io.stderr:write(err .. "\n")
		love.event.quit(1)
	end
end
