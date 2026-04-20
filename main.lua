WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200
MAX_BALL_SPEED = 400   
SPEED_MULTIPLIER = 1.05  

push = require "push"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    local success, font = pcall(love.graphics.newFont, "font.ttf", 32)
    largeFont = success and font or love.graphics.newFont(32)
    local success2, font2 = pcall(love.graphics.newFont, "font.ttf", 8)
    smallFont = success2 and font2 or love.graphics.newFont(8)
    
    player1Score = 0
    player2Score = 0

    math.randomseed(os.time())
    
    player1Y = 30
    player2Y = VIRTUAL_HEIGHT - 50
    
    ballSize = 4
    ballX = VIRTUAL_WIDTH / 2 - ballSize / 2
    ballY = VIRTUAL_HEIGHT / 2 - ballSize / 2
    ballDX = math.random(2) == 1 and 100 or -100
    ballDY = math.random(-50, 50)

    servingPlayer = math.random(2) == 1 and 1 or 2
    winningPlayer = 0

    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        resizable = false,
        vsync = true,
        fullscreen = false
    })
    push.setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, {upscale = "normal"})
    
    gameState = "start"
end 

function checkCollision(bX, bY, bW, bH, pX, pY, pW, pH)
    if bX > pX + pW or pX > bX + bW then return false end
    if bY > pY + pH or pY > bY + bH then return false end
    return true
end

function resetBall()
    ballX = VIRTUAL_WIDTH / 2 - ballSize / 2
    ballY = VIRTUAL_HEIGHT / 2 - ballSize / 2
    ballDY = math.random(-50, 50)
    
    if servingPlayer == 1 then
        ballDX = 100
    else
        ballDX = -100
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "enter" or key == "return" or key == "space" then
        if gameState == "start" then
            gameState = "serve"
        elseif gameState == "serve" then
            gameState = "play"
        elseif gameState == "done" then
            gameState = "serve"
            player1Score = 0
            player2Score = 0
            
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
            resetBall()
        end
    end
end

function love.update(dt)
    if love.keyboard.isDown("w") then
        player1Y = math.max(0, player1Y - (PADDLE_SPEED * dt))
    elseif love.keyboard.isDown("s") then
        player1Y = math.min(VIRTUAL_HEIGHT - 20, player1Y + (PADDLE_SPEED * dt))
    end

    if love.keyboard.isDown("up") then
        player2Y = math.max(0, player2Y - (PADDLE_SPEED * dt))
    elseif love.keyboard.isDown("down") then
        player2Y = math.min(VIRTUAL_HEIGHT - 20, player2Y + (PADDLE_SPEED * dt))
    end

    if gameState == "play" then
        ballX = ballX + ballDX * dt
        ballY = ballY + ballDY * dt

        if ballY <= 0 then
            ballY = 0
            ballDY = -ballDY
        elseif ballY >= VIRTUAL_HEIGHT - ballSize then
            ballY = VIRTUAL_HEIGHT - ballSize
            ballDY = -ballDY
        end

        if checkCollision(ballX, ballY, ballSize, ballSize, 10, player1Y, 5, 20) then
            ballDX = -ballDX * SPEED_MULTIPLIER 
            ballX = 15 
            
            if ballDX > MAX_BALL_SPEED then ballDX = MAX_BALL_SPEED end
            
            ballDY = ballDY < 0 and -math.random(10, 150) or math.random(10, 150)
        end

        if checkCollision(ballX, ballY, ballSize, ballSize, VIRTUAL_WIDTH - 15, player2Y, 5, 20) then
            ballDX = -ballDX * SPEED_MULTIPLIER
            ballX = VIRTUAL_WIDTH - 15 - ballSize
            
            if ballDX < -MAX_BALL_SPEED then ballDX = -MAX_BALL_SPEED end
            
            ballDY = ballDY < 0 and -math.random(10, 150) or math.random(10, 150)
        end

        if ballX < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            
            if player2Score == 10 then
                winningPlayer = 2
                gameState = "done"
            else
                gameState = "serve"
                resetBall()
            end
        end

        if ballX > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            
            if player1Score == 10 then
                winningPlayer = 1
                gameState = "done"
            else
                gameState = "serve"
                resetBall()
            end
        end
    end
end

function love.draw()
    push.start()
    love.graphics.clear(40/255, 45/255, 52/255, 1)
    
    love.graphics.setFont(largeFont)
    love.graphics.printf(tostring(player1Score), 0, VIRTUAL_HEIGHT / 2 - 80, VIRTUAL_WIDTH / 2 - 20, "right")
    love.graphics.printf(tostring(player2Score), VIRTUAL_WIDTH / 2 + 20, VIRTUAL_HEIGHT / 2 - 80, VIRTUAL_WIDTH / 2, "left")

    love.graphics.setFont(smallFont)
    if gameState == "start" then
        love.graphics.printf("PONG OYUNUNA HOSGELDINIZ!", 0, 10, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Baslamak icin ENTER veya SPACE'e basin", 0, 20, VIRTUAL_WIDTH, "center")
    elseif gameState == "serve" then
        love.graphics.printf("Oyuncu " .. tostring(servingPlayer) .. " servis atiyor!", 0, 10, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Servis atmak icin ENTER veya SPACE'e basin", 0, 20, VIRTUAL_WIDTH, "center")
    elseif gameState == "done" then
        love.graphics.setFont(largeFont)
        love.graphics.printf("OYUNCU " .. tostring(winningPlayer) .. " KAZANDI!", 0, 10, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(smallFont)
        love.graphics.printf("Tekrar oynamak icin ENTER veya SPACE'e basin", 0, 50, VIRTUAL_WIDTH, "center")
    end

    love.graphics.rectangle("fill", 10, player1Y, 5, 20)
    love.graphics.rectangle("fill", VIRTUAL_WIDTH - 15, player2Y, 5, 20)
    
    if gameState == "play" or gameState == "serve" then
        love.graphics.rectangle("fill", ballX, ballY, ballSize, ballSize)
    end

    push.finish()
end