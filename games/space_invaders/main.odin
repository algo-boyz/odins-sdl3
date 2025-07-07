package main

import "core:fmt"
import sdl "vendor:sdl3"
import sdlImage "vendor:sdl3/image"

// based on SDL2 version: https://github.com/renpenguin/Lasers

Textures :: struct {
	player, playerLaser, drone, droneLaser: ^sdl.Texture
}

Vector2 :: struct {
	x, y: f32,
}

DrawData :: struct {
	player, playerLasers, drones, droneLasers: sdl.FRect
}

main :: proc() {
	Player :: byte(0)
	PlayerLasers :: byte(1)
	Drones :: byte(2)
	DroneLasers :: byte(3)

	WindowWidth :: f32(1600)
	WindowHeight :: f32(900)

	TimeDelta :: f32(1000.0 / 60.0)
	PlayerAndDroneDeltaMovement := 400 * TimeDelta / 1000
	LaserDeltaMovement := 700 * TimeDelta / 1000

	DroneCooldownTicks :: f32(700)
	FireCooldownTicks :: f32(20)

	MaxLasers :: byte(10)
	MaxDroneLasers :: byte(20)
	MaxDrones :: byte(10)

	PlayerScaleFactor :: f32(10)
	LaserScaleFactor :: f32(3)
	DroneScaleFactor :: f32(10)
	DroneLaserScaleFactor :: f32(3)

	positions: [4]#soa[]Vector2
	drawData: DrawData
	textures: Textures

	// Init SDL 
	assert(sdl.Init({.VIDEO}), fmt.tprintf("Error: sdl.Init() failed: %v", string(sdl.GetError())))

	window := sdl.CreateWindow("Odin Space Shooter", i32(WindowWidth), i32(WindowHeight), nil)
	assert(
		window != nil,
		fmt.tprintf("Error: sdl.CreateWindow() failed: %v", string(sdl.GetError())),
	)
	renderer := sdl.CreateRenderer(window, nil)
	assert(
		renderer != nil,
		fmt.tprintf("Error: sdl.CreateRenderer() failed: %v", string(sdl.GetError())),
	)
	// Load Textures
	textures.player = sdlImage.LoadTexture(renderer, "./assets/player.png")
	assert(
		textures.player != nil,
		fmt.tprintf(
			"Error: sdlImage.LoadTexture() failed to load player texture: %v",
			string(sdl.GetError()),
		),
	)
	textures.playerLaser = sdlImage.LoadTexture(renderer, "./assets/bullet.png")
	assert(
		textures.playerLaser != nil,
		fmt.tprintf(
			"Error: sdlImage.LoadTexture() failed to load laser texture: %v",
			string(sdl.GetError()),
		),
	)
	textures.drone = sdlImage.LoadTexture(renderer, "./assets/enemy.png")
	assert(
		textures.drone != nil,
		fmt.tprintf(
			"Error: sdlImage.LoadTexture() failed to load drone texture: %v",
			string(sdl.GetError()),
		),
	)
	textures.droneLaser = sdlImage.LoadTexture(renderer, "./assets/bullet.png")
	assert(
		textures.droneLaser != nil,
		fmt.tprintf(
			"Error: sdlImage.LoadTexture() failed to load drone laser texture: %v",
			string(sdl.GetError()),
		),
	)
	// Player
	drawData.player.w = f32(textures.player.w) / PlayerScaleFactor
	drawData.player.h = f32(textures.player.h) / PlayerScaleFactor

	positions[Player] = make(#soa[]Vector2, 1)

	positions[Player][0] = Vector2 {
		x = 20,
		y = WindowHeight / 2,
	}
	// Player lasers
	drawData.playerLasers.w = f32(textures.playerLaser.w) / LaserScaleFactor
	drawData.playerLasers.h = f32(textures.playerLaser.h) / LaserScaleFactor

	positions[PlayerLasers] = make(#soa[]Vector2, MaxLasers)

	for i in 0 ..< MaxLasers {
		positions[PlayerLasers][i] = Vector2 {
			x = WindowWidth + 1,
			y = WindowHeight + 1,
		}
	}
	// Drones
	drawData.drones.w = f32(textures.drone.w) / DroneScaleFactor
	drawData.drones.h = f32(textures.drone.h) / DroneScaleFactor

	positions[Drones] = make(#soa[]Vector2, MaxDrones)

	for i in 0 ..< MaxDrones {
		positions[Drones][i] = Vector2 {
			x = WindowWidth + 1,
			y = WindowHeight + 1,
		}
	}
	// Drone lasers
	drawData.droneLasers.w = f32(textures.droneLaser.w) / DroneLaserScaleFactor
	drawData.droneLasers.h = f32(textures.droneLaser.h) / DroneLaserScaleFactor

	positions[DroneLasers] = make(#soa[]Vector2, MaxDroneLasers)

	for i in 0 ..< MaxDroneLasers {
		positions[DroneLasers][i] = Vector2 {
			x = WindowWidth + 1,
			y = WindowHeight + 1,
		}
	}
	playerXMax := WindowWidth - drawData.player.w
	playerYMax := WindowHeight - drawData.player.h
	drawData.player.x = positions[Player][0].x
	drawData.player.y = positions[Player][0].y

	activePtr: byte = 0

	ticksSinceFire: f32 = 0
	ticksSinceDrone: f32 = 0

	event: sdl.Event
	keysPressed: [^]bool

	start: f32
	end: f32
	perfFrequency := f32(sdl.GetPerformanceFrequency())

	for {
		start = f32(sdl.GetPerformanceCounter()) * 1000 / perfFrequency
		// Input
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case sdl.EventType.QUIT:
				return
			case sdl.EventType.KEY_DOWN:
				if event.key.scancode == .ESCAPE {
					return
				}
			}
		}
		keysPressed = sdl.GetKeyboardState(nil)
		if keysPressed[sdl.Scancode.A] {
			positions[Player][0].x = clamp(
				positions[Player][0].x - PlayerAndDroneDeltaMovement,
				0,
				playerXMax,
			)
			drawData.player.x = positions[Player][0].x
		}
		if keysPressed[sdl.Scancode.D] {
			positions[Player][0].x = clamp(
				positions[Player][0].x + PlayerAndDroneDeltaMovement,
				0,
				playerXMax,
			)
			drawData.player.x = positions[Player][0].x
		}
		if keysPressed[sdl.Scancode.W] {
			positions[Player][0].y = clamp(
				positions[Player][0].y - PlayerAndDroneDeltaMovement,
				0,
				playerYMax,
			)
			drawData.player.y = positions[Player][0].y
		}
		if keysPressed[sdl.Scancode.S] {
			positions[Player][0].y = clamp(
				positions[Player][0].y + PlayerAndDroneDeltaMovement,
				0,
				playerYMax,
			)
			drawData.player.y = positions[Player][0].y
		}
		ticksSinceFire -= 1

		if keysPressed[sdl.Scancode.SPACE] && ticksSinceFire <= 0 && activePtr < MaxLasers {
			positions[PlayerLasers][activePtr].x = positions[Player][0].x + 30
			positions[PlayerLasers][activePtr].y = positions[Player][0].y
			activePtr += 1
			ticksSinceFire = FireCooldownTicks
		}
		for i in 0 ..< activePtr {
			if positions[PlayerLasers][i].x > WindowWidth {
				activePtr -= 1
				positions[PlayerLasers][i] = positions[PlayerLasers][activePtr]
			}

			positions[PlayerLasers][i].x += LaserDeltaMovement
		}
		// Draw
		for i in 0 ..< activePtr {
			drawData.playerLasers.x = positions[PlayerLasers][i].x
			drawData.playerLasers.y = positions[PlayerLasers][i].y
			sdl.RenderTexture(renderer, textures.playerLaser, nil, &drawData.playerLasers)
		}
		sdl.RenderTexture(renderer, textures.player, nil, &drawData.player)
		sdl.RenderPresent(renderer)
		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 100)
		sdl.RenderClear(renderer)

		for end - start < TimeDelta {
			end = f32(sdl.GetPerformanceCounter()) * 1000 / perfFrequency
		}
	}
}