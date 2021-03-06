local tlz = require("tlz")

local input = {}
input.players = {}
input.index = 1
input.capacity = 2
input.size = 0
input.freeIndexes = {}

function input.load(self,playerMax)
	self.capacity = playerMax
end

function input.joystickadded(self,joystick)
	if(joystick:isGamepad())then
		if(self.size ~= self.capacity)then			--A+
			local index = self.index
			while(self.players[index] ~= nil)do
				index = index + 1
			end
			
			self.players[index] = self._gamepad:newplayer(index,joystick)
			
			self.size = self.size + 1
			self.index = index + 1
		end
	end
end

function input.joystickremoved(self,joystick)
	local players = self.players
	local index = self._gamepad.mapToPlayers[joystick:getID()]
	
	if(players[index] ~= nil)then
		tlz.clearTable(players[index].args)
		tlz.clearTable(players[index])
		self._gamepad.mapToPlayers[joystick:getID()] = nil
		players[index] = nil
		
		if(index < self.index)then
			self.index = index
		end

		self.size = self.size - 1
	end
end

function input.isDown(self,player,button)
	local player = self.players[player]
	return player ~= nil and player.controller.isDown(player.args,button) or false
end

function input.getAxis(self,player,axis,flags)
	local player = self.players[player]
	return player ~= nil and player.controller.getAxis(player.args,axis,flags) or 0
end

function input.gamepadpressed(self,joystick,button)
	self.pressed(self._gamepad.mapToPlayers[joystick:getID()],button)
end
function input.gamepadreleased(self,joystick,button)
	self.released(self._gamepad.mapToPlayers[joystick:getID()],button)
end

input._gamepad = {
	mapToPlayers = {},
	name = "Gamepad",
	defaultConfig = {
		deadzones = {
			leftx = 0.2,
			lefty = 0.2,
			rightx = 0.2,
			righty = 0.2,
      triggerleft = 0,
      triggerright = 0
		}
	}
}

function input._gamepad.newplayer(self,index,joystick,config)
	local config = config or self.defaultConfig
	
	local player = {
		index = index,
		controller = self,
		args = {
			joystick = joystick,
			deadzones = config.deadzones or self.defaultConfig.deadzones
		}
	}
	
	self.mapToPlayers[joystick:getID()] = index
	
	return player
end

function input._gamepad.isDown(args,button)
	return args.joystick:isGamepadDown(button)
end
function input._gamepad.getAxis(args,axis,flags)
	local raw = false
	
	if(flags ~= nil)then
		raw = flags.raw or raw
	end
	
	if(raw)then
		return args.joystick:getGamepadAxis(axis)
	end
	
	local v = args.joystick:getGamepadAxis(axis)
		
	if(math.abs(v) > args.deadzones[axis])then
		return args.joystick:getGamepadAxis(axis)
	end
		
	return 0
end

function input.pressed(player,button)end
function input.released(player,button)end

function input.debugString(self)
	local s = "---input---"
		.. "\nsize: " .. self.size
		.. "\ncapacity: " .. self.capacity
		.. "\nindex: " .. self.index
		.. "\nfreeIndexes:"
	local i = 0
	for _, v in pairs(self.freeIndexes) do
		s = s .. " " .. v
		i = i + 1
	end
	if(i == 0)then
		s = s .. " nil"
	end

	for k, v in pairs(self.players) do
		s = s .. "\nPlayer#" .. k
			.. "\n controller: " .. v.controller.name
	end
	
	for k, v in pairs(self._gamepad.mapToPlayers) do
		local leftx = self:getAxis(v,"leftx")
		local leftx_raw = self:getAxis(v,"leftx",{raw = true})
		local lefty = self:getAxis(v,"lefty")
		local lefty_raw = self:getAxis(v,"lefty",{raw = true})
		
		local rightx = self:getAxis(v,"rightx")
		local rightx_raw = self:getAxis(v,"rightx",{raw = true})
		local righty = self:getAxis(v,"righty")
		local righty_raw = self:getAxis(v,"righty",{raw = true})
		
		s = s .. "\nGamepad#" .. k
			.. "\n player: " .. v
			.. "\n leftx: " .. leftx
			.. "\n  raw: " .. leftx_raw
			.. "\n lefty: " .. lefty
			.. "\n  raw: " .. lefty_raw
			.. "\n = left(dir): " .. math.deg(math.atan2(lefty,leftx))
			.. "\n =       raw: " .. math.deg(math.atan2(lefty_raw,leftx_raw))
			.. "\n rightx: " .. rightx
			.. "\n  raw: " .. rightx_raw
			.. "\n righty: " .. righty
			.. "\n  raw: " .. righty_raw
			.. "\n = right(dir): " .. math.deg(math.atan2(righty,rightx))
			.. "\n =         raw: " .. math.deg(math.atan2(righty_raw,rightx_raw))
			.. "\n leftshoulder: " .. (self:isDown(k,"leftshoulder") and "true" or "false")
			.. "\n rightshoulder: " .. (self:isDown(k,"rightshoulder") and "true" or "false")
			.. "\n start: " .. (self:isDown(k,"start") and "true" or "false")
	end
	
	s = s .. "\n#Of [All] Detected Controllers: " .. love.joystick.getJoystickCount()
	
	return s .. "\n"
end


return input

--[[
love.joystick
love.joystick.getJoystickCount
love.joystickpressed
love.joystickreleased
love.joystickaxis
love.joystickhat
love.gamepadpressed
love.gamepadreleased
love.gamepadaxis
]]--
