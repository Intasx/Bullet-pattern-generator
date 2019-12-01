local Bullet = require("bullet")

function love.load()
	love.keyboard.setKeyRepeat(true)

	local w, h = love.graphics.getDimensions()

	local image = love.graphics.newImage("graphics/boss.png")
	local bulletImage = love.graphics.newImage("graphics/bullet.png")

	bullet = Bullet(image, bulletImage, math.floor(w/2)-image:getWidth(), math.floor(h/2)-image:getHeight())
	-- To use default values and no images, comment the previous line and uncomment the following one
	--bullet = Bullet()
end

function love.update(dt)
	bullet:update(dt)
end

function love.draw()
	bullet:draw()
end

function love.keypressed(key)
	if (key == "escape") then
		love.event.quit("restart")
	end
	bullet:keypressed(key)
end