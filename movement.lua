local movement = {}

-- Arrow keys supplement player one's bindings unless a player explicitly assigned them elsewhere.
function movement.arrowAvailable(player, direction, controls, players)
	if player ~= 1 then
		return false
	end

	for i = 1, players do
		for action, binding in pairs(controls[i]) do
			if binding[1] == direction and (i ~= player or action ~= direction) then
				return false
			end
		end
	end
	return true
end

-- The body follows movement; the separately drawn tool still follows the aim.
function movement.facing(player)
	local aim = player.pointingangle > 0 and -1 or 1
	if player.controlsenabled and not player.vine
	and (not player.animation or player.animation == "invincible")
	and math.abs(player.rotation) < 0.001 and math.abs(player.speedx) > 0.05 then
		return player.speedx > 0 and 1 or -1, aim
	end
	return aim, aim
end

return movement
