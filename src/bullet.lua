local Class = require("libs/class")
--local HC = require("libs/HC")

local Bullet = Class()

function Bullet:init(image, bulletImage, x, y, args)
	local defaultArgs = {
		initialAngle = -math.pi/2,
		bulletsPerArray = 2,
		individualArraySpread = math.pi/2,
		totalBulletArrays = 1,
		totalArraySpread = math.pi/2,
		currentSpinSpeed = 0,
		spinSpeedChangeRate = 0,
		spinReversal = false,
		maxSpinSpeed = 30,
		fireRate = 4,
		bulletSpeed = 4,
		acceleration = 0,
		xOffset = 0,
		yOffset = 0
	}

	if (not args) then
		args = defaultArgs
	end

	self.image = image
	self.bulletImage = bulletImage

	self.x = x or math.floor(love.graphics.getWidth()/2)
	self.y = y or math.floor(love.graphics.getHeight()/2)

	self.defaultX = x
	self.defaultY = y

	-- How many bullets will our enemy shoot per array
	self.bulletsPerArray = args.bulletsPerArray or defaultArgs.bulletsPerArray

	-- Spread between every bullet
	self.individualArraySpread = args.individualArraySpread or defaultArgs.individualArraySpread

	-- Amount of arrays
	self.totalBulletArrays = args.totalBulletArrays or defaultArgs.totalBulletArrays

	-- Spread between arrays
	self.totalArraySpread = args.totalArraySpread or defaultArgs.totalArraySpread

	-- 0 -> no spin, for any other value it will start spinning
	self.currentSpinSpeed = args.currentSpinSpeed or defaultArgs.currentSpinSpeed

	-- If spinSpeedChangeRate is ~= 0, currentSpinSpeed will increase or decrease depending on
	-- wheter change rate is positive or negative
	self.spinSpeedChangeRate = args.spinSpeedChangeRate or defaultArgs.spinSpeedChangeRate

	-- If spinReversal is set to true, currentSpinSpeed will be limitated by the maxSpinSpeed
	-- so if the change rate is positive, currentSpinSpeed will increase until it gets to the maxSpinSpeed,
	-- then the change rate is set to negative and currentSpinSpeed will decrease to negative maxSpinSpeed,
	-- and so on.
	-- If spinReversal is set to false, currentSpinSpeed will increase or decrease to the maxSpinSpeed
	-- and stay in that value.

	self.spinReversal = args.spinReversal or defaultArgs.spinReversal
	self.maxSpinSpeed = args.maxSpinSpeed or defaultArgs.maxSpinSpeed

	-- Shoot a bullet every 4 frames
	self.fireRate = args.fireRate or defaultArgs.fireRate

	-- How many pixels the bullets move every frame
	self.bulletSpeed = args.bulletSpeed or defaultArgs.bulletSpeed

	self.acceleration = args.acceleration or defaultArgs.acceleration

	-- Width and height of the enemy's rectangle.
	-- If it's zero, the bullets spawn at the same coordinates,
	-- otherwise they spawn on the corners
	self.width = 0
	self.height = 0

	self.xOffset = args.xOffset or defaultArgs.xOffset
	self.yOffset = args.yOffset or defaultArgs.yOffset

	self.arrays = {}
	local initialAngle = args.initialAngle or defaultArgs.initialAngle
	for currentArray=1, self.totalBulletArrays do
		self.arrays[currentArray] = {}
		for currentBullet=1, self.bulletsPerArray do
			self.arrays[currentArray][currentBullet] = self:new(self.x, self.y, initialAngle, currentArray)
			initialAngle = initialAngle + self.individualArraySpread
		end
	end

	self.frame = 0

	self.createdBullets = {}
	self.toRemove = {}

	self.data = {}

	self.followMouse = false
	--self.curved = false

	self.optionIndex = 1
end


-- Bullet creator: Every bullet must be an independent table
function Bullet:new(x, y, angle, arrayId)
	local w = self.bulletImage and self.bulletImage:getWidth() or 5
	local h = self.bulletImage and self.bulletImage:getHeight() or 5

	return {
		x = x + w + math.cos(angle) + self.xOffset,
		y = y + h + math.sin(angle) + self.yOffset,
		speed = self.bulletSpeed,
		angle = angle,
		arrayId = arrayId
	}
end


-- The bullet is offscreen if any of these is true:
-- x - floor(bullet_width/2)  > window_width
-- y - floor(bullet_height/2) > window_height
-- x + floor(bullet_width/2)  < 0
-- y + floor(bullet_height/2) < 0
function Bullet:isOffscreen(x, y)
	local w, h = love.graphics.getDimensions()
	local bulletW, bulletH
	if (self.bulletImage) then
		bulletW, bulletH = math.floor(self.bulletImage:getWidth()/2), math.floor(self.bulletImage:getHeight()/2)
	else
		bulletW, bulletH = 2, 2
	end
	return x-bulletW > w or y-bulletH > h or x+bulletW < 0 or y+bulletH < 0
end

function Bullet:modifyValue(key)
	local changes = {
		function(s) self.bulletsPerArray = self.bulletsPerArray+s end,
		function(s) self.individualArraySpread = self.individualArraySpread+math.rad(s) end,
		function(s) self.totalBulletArrays = self.totalBulletArrays+s end,
		function(s) self.totalArraySpread = self.totalArraySpread+math.rad(s) end,
		function(s) self.currentSpinSpeed = self.currentSpinSpeed+s end,
		function(s) self.spinSpeedChangeRate = self.spinSpeedChangeRate+s end,
		function(s) self.spinReversal = s end,
		function(s) self.maxSpinSpeed = self.maxSpinSpeed + s end,
		function(s) self.fireRate = self.fireRate + s end,
		function(s) self.bulletSpeed = self.bulletSpeed + s end,
		function(s) self.acceleration = self.acceleration + s end,
		function(s) self.width = self.width + s end,
		function(s) self.heigh = self.height + s end,
		function(s) self.xOffset = self.xOffset + s end,
		function(s) self.yOffset = self.yOffset + s end
	}

	local steps = {
		1,
		1,
		1,
		2,
		0.1,
		0.1,
		not self.spinReversal,
		0.5,
		1,
		0.1,
		0.01,
		1,
		0.1,
		0.1,
		0.1
	}

	if (type(self.data[self.optionIndex]) == "number") then
		local s = key == "left" and -steps[self.optionIndex] or steps[self.optionIndex]
		changes[self.optionIndex](s)
		--self.data[self.optionIndex] = self.data[self.optionIndex] + s
	elseif (type(steps[self.optionIndex]) == "boolean") then
		changes[self.optionIndex](steps[self.optionIndex])
		--self.data[self.optionIndex] = s
	end

	self:applyChanges(self.optionIndex, key)
end

function Bullet:applyChanges(opt, key, currentArr, firstAngle)
	currentArr = currentArr or 1
	if (opt == 1 or opt == 2) then
		for currentArray=currentArr, self.totalBulletArrays do
			local angle
			-- The array will be split into equal zones, so if we have 3 bulletsPerArray
			-- (2 at the limits and 1 in the middle) there will be 2 zones
			local arrayZones = self.bulletsPerArray - 1
			local firstAng = firstAngle or self.arrays[currentArray][1].angle
			local step = math.abs(self.individualArraySpread/arrayZones)

			-- Clear the current array
			for i=1, #self.arrays[currentArray]+1 do
				self.arrays[currentArray][i] = nil
			end
			-- and set the new angles
			angle = firstAng
			for _=1, self.bulletsPerArray do
				table.insert(self.arrays[currentArray], self:new(self.x, self.y, angle))
				angle = angle + step
			end
		end
	elseif (opt == 3) then
		if (key == "right") then
			self.arrays[self.totalBulletArrays] = {}
			local firstAngPrevious = self.arrays[self.totalBulletArrays-1][1].angle
			local firstAngNew = firstAngPrevious + self.totalArraySpread
			local lastAngNew  = firstAngNew + self.individualArraySpread
			table.insert(self.arrays[self.totalBulletArrays], self:new(self.x, self.y, firstAngNew, true))
			table.insert(self.arrays[self.totalBulletArrays], self:new(self.x, self.y, lastAngNew))
			self:applyChanges(1, nil, self.totalBulletArrays)
		else
			self.arrays[self.totalBulletArrays+1] = nil
		end
	elseif (opt == 4) then
		if (self.totalBulletArrays > 1) then
			self:applyChanges(3, "right")
		end
	elseif (opt == 14 or opt == 15) then
		self:applyChanges(1)
	end
end

function Bullet:update(dt)
	self.data = {
		self.bulletsPerArray,
		math.deg(self.individualArraySpread),
		self.totalBulletArrays,
		math.deg(self.totalArraySpread),
		self.currentSpinSpeed,
		self.spinSpeedChangeRate,
		tostring(self.spinReversal),
		self.maxSpinSpeed,
		self.fireRate,
		self.bulletSpeed,
		self.acceleration,
		self.width,
		self.height,
		self.xOffset,
		self.yOffset,
		love.timer.getFPS(),
		#self.createdBullets
	}

	if (self.followMouse) then
		self.x, self.y = love.mouse.getPosition()
		self:applyChanges(1)
	end

	self.frame = self.frame + 1
	if (self.frame >= self.fireRate) then
		self.frame = 0
		for i, array in ipairs(self.arrays) do
			for _, bullet in ipairs(array) do
				local newBullet = self:new(bullet.x, bullet.y, bullet.angle, i)
				table.insert(self.createdBullets, newBullet)
			end
		end

		if (self.currentSpinSpeed ~= 0) then
			for i=1, #self.arrays do
				for j=1, #self.arrays[i] do
					self.arrays[i][j].angle = self.arrays[i][j].angle + math.rad(self.currentSpinSpeed)
				end
			end
		end

		if (self.spinSpeedChangeRate ~= 0) then
			local curr = self.currentSpinSpeed
			local chrate = self.spinSpeedChangeRate
			local max = self.maxSpinSpeed
			curr = curr + chrate
			if (chrate > 0 and max < 0 or chrate < 0 and max > 0) then
				max = -max
			end
			if (max > 0 and curr >= max or max < 0 and curr <= max) then
				chrate = self.spinReversal and -chrate or 0
				max = self.spinReversal and -max or max
			end
			self.currentSpinSpeed = curr
			self.spinSpeedChangeRate = chrate
			self.maxSpinSpeed = max
		end
	end

	for i, bullet in ipairs(self.createdBullets) do
		-- Constant speed
		--bullet.x = bullet.x + self.bulletSpeed * math.cos(bullet.angle)
		--bullet.y = bullet.y + self.bulletSpeed * math.sin(bullet.angle)

		bullet.speed = bullet.speed + self.acceleration
		bullet.x = bullet.x + bullet.speed * math.cos(bullet.angle)
		bullet.y = bullet.y + bullet.speed * math.sin(bullet.angle)

		--if (self.curved) then
			--bullet.angle = bullet.angle + math.rad(1)
		--end

		if (self:isOffscreen(bullet.x, bullet.y)) then
			table.insert(self.toRemove, i)
		end
	end

	for i = #self.toRemove, 1, -1 do
		table.remove(self.createdBullets, self.toRemove[i])
		table.remove(self.toRemove, i)
	end

end

local function drawText(self, colored)
	local text = {
		"Bullets per array:",
		"Individual array spread:",
		"Total bullet arrays:",
		"Total array spread:",
		"Current spin speed:",
		"Spin speed change rate:",
		"Spin reversal:",
		"Max spin speed:",
		"Fire rate:",
		"Bullet Speed:",
		"Bullet acceleration:",
		"Width:",
		"Height:",
		"x offset:",
		"y offset:",
		"FPS:",
		"Bullets in screen:"
	}
	local settings = "\nQ: Follow mouse.\nW: Set coordinates to default values."
	local t = {}
	for i, value in ipairs(self.data) do
		if (i == colored) then
			table.insert(t, {1, 0, 0})
			table.insert(t, text[i] .. " " .. tostring(value) .. "\n\n")
		else
			table.insert(t, {1, 1, 1})
			table.insert(t, text[i] .. " " .. tostring(value) .. "\n\n")
		end
	end
	table.insert(t, {1, 1, 1})
	table.insert(t, settings)
	love.graphics.printf(t, 0, 0, math.floor(love.graphics.getWidth()/2), "left")
end

function Bullet:draw()
	for _, bullet in ipairs(self.createdBullets) do
		if (self.bulletImage) then
			love.graphics.draw(self.bulletImage, bullet.x, bullet.y, bullet.angle)
		else
			love.graphics.rectangle("fill", bullet.x, bullet.y, 5, 5)
		end
	end

	if (self.image) then
		love.graphics.draw(self.image, self.x, self.y)
	end

	drawText(self, self.optionIndex)
end

function Bullet:keypressed(key)
	if (key == "up" and self.optionIndex > 1) then
		self.optionIndex = self.optionIndex - 1
	elseif (key == "down" and self.optionIndex < 15) then
		self.optionIndex = self.optionIndex + 1
	elseif (key == "left" or key == "right") then
		self:modifyValue(key)
	elseif (key == "q") then
		self.followMouse = not self.followMouse
	elseif (key == "w") then
		self.followMouse = false
		self.x = self.defaultX
		self.y = self.defaultY
		self:applyChanges(1)
	--elseif (key == "e") then
		--self.curved = not self.curved
	end
end


return Bullet