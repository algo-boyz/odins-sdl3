package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import sdl "vendor:sdl3"
import "../../sutil/timer"

FRAME_RATE :: 60
TICKS_PER_FRAME :: 1000 / FRAME_RATE

Btn :: struct {
	half_transitions: u32,
	ended_down:       bool,
}

State :: struct {
	movement_up, movement_down, movement_left, movement_right,
	rotate_clockwise, rotate_counter_clockwise: Btn,
}
input_state: State

state_clear :: proc(state: ^State) {
	state.movement_up.half_transitions = 0
	state.movement_down.half_transitions = 0
	state.movement_left.half_transitions = 0
	state.movement_right.half_transitions = 0
	state.rotate_clockwise.half_transitions = 0
	state.rotate_counter_clockwise.half_transitions = 0
}

Player :: struct {
	x, y, rotation, speed: f32,
}
player: Player

init :: proc() {
	player = Player{
		x = 450,
		y = 360,
		rotation = 0,
		speed = 200,
	}
}

update :: proc(dt: f32) {
	move_x, move_y: f32
	if input_state.movement_up.ended_down {
		move_y -= 1
	}
	if input_state.movement_down.ended_down {
		move_y += 1
	}
	if input_state.movement_left.ended_down {
		move_x -= 1
	}
	if input_state.movement_right.ended_down {
		move_x += 1
	} // Normalize diagonal movement
	if move_x != 0 && move_y != 0 {
		move_x *= 0.707
		move_y *= 0.707
	}
	player.x += move_x * player.speed * dt
	player.y += move_y * player.speed * dt
	// Handle rotation
	if input_state.rotate_clockwise.ended_down {
		player.rotation += 180 * dt
	}
	if input_state.rotate_counter_clockwise.ended_down {
		player.rotation -= 180 * dt
	} // Keep player on screen
	player.x = clamp(player.x, 20, 880)
	player.y = clamp(player.y, 20, 700)
}

draw_player :: proc(renderer: ^sdl.Renderer) {
	// Simple triangle as player
	center_x := player.x
	center_y := player.y
	// Convert rotation to radians
	rad := math.to_radians(player.rotation)
	// Triangle points (pointing up)
	size: f32 = 15
	// Calculate rotated points
	p1_x := center_x + math.sin(rad) * size
	p1_y := center_y - math.cos(rad) * size

	p2_x := center_x + math.sin(rad + 2.094) * size // 2.094 ≈ 2π/3
	p2_y := center_y - math.cos(rad + 2.094) * size
	
	p3_x := center_x + math.sin(rad - 2.094) * size
	p3_y := center_y - math.cos(rad - 2.094) * size
	
	// Draw triangle using lines
	sdl.SetRenderDrawColor(renderer, 0xFF, 0x00, 0x00, 0xFF) // Red
	sdl.RenderLine(renderer, p1_x, p1_y, p2_x, p2_y)
	sdl.RenderLine(renderer, p2_x, p2_y, p3_x, p3_y)
	sdl.RenderLine(renderer, p3_x, p3_y, p1_x, p1_y)
}

main :: proc() {
	if !sdl.Init(sdl.INIT_VIDEO) {
		fmt.eprintfln("SDL could not initialize! SDL_Error: %v\n", sdl.GetError())
		return
	}
	defer sdl.Quit()
	g_window := new(sdl.Window)
	g_renderer := new(sdl.Renderer)
	if !sdl.CreateWindowAndRenderer(
		"SDL3 Demo - WASD to move, Q/E to rotate",
		900, 720,
        {sdl.WindowFlags.RESIZABLE},
        &g_window, &g_renderer
	) {
		fmt.printf("Window could not be created! SDL_Error: %s\n", sdl.GetError())
		return
	}
	defer sdl.DestroyWindow(g_window)
	defer sdl.DestroyRenderer(g_renderer)

	sdl.SetRenderDrawBlendMode(g_renderer, {sdl.BlendModeFlag.BLEND})
	sdl.SetHint(sdl.HINT_RENDER_VSYNC, "1")

	world_target := sdl.CreateTexture(
		g_renderer,
		sdl.PixelFormat.RGBA32,
		sdl.TextureAccess.TARGET,
		900,
		720,
	)
	defer sdl.DestroyTexture(world_target)
	n_frames: f32
	fps_timer := timer.create()
	cap_timer := timer.create()
	step_timer := timer.create()
	timer.start(&fps_timer)
	timer.start(&step_timer)
	init()
	quit: bool
	for !quit {
		state_clear(&input_state)
		for e: sdl.Event; sdl.PollEvent(&e); {
			#partial switch e.type {
			case .QUIT:
				quit = true
			case .KEY_DOWN, .KEY_UP:
				if e.key.repeat do continue
				switch e.key.key {
				case sdl.K_W:
					input_state.movement_up.half_transitions += 1
					input_state.movement_up.ended_down = e.key.type == .KEY_DOWN
				case sdl.K_D:
					input_state.movement_right.half_transitions += 1
					input_state.movement_right.ended_down = e.key.type == .KEY_DOWN
				case sdl.K_S:
					input_state.movement_down.half_transitions += 1
					input_state.movement_down.ended_down = e.key.type == .KEY_DOWN
				case sdl.K_A:
					input_state.movement_left.half_transitions += 1
					input_state.movement_left.ended_down = e.key.type == .KEY_DOWN
				case sdl.K_Q:
					input_state.rotate_clockwise.half_transitions += 1
					input_state.rotate_clockwise.ended_down = e.key.type == .KEY_DOWN
				case sdl.K_E:
					input_state.rotate_counter_clockwise.half_transitions += 1
					input_state.rotate_counter_clockwise.ended_down =
						e.key.type == .KEY_DOWN
				case sdl.K_ESCAPE:
					quit = true
				}
			}
		}
		timer.start(&cap_timer)
		avg_fps := n_frames / (f32(timer.tick(&fps_timer)) / 1000.0)
		if avg_fps > 2000000 {
			avg_fps = 0
		}
		delta_time := f32(timer.tick(&step_timer)) / 1000
		timer.start(&step_timer)

		// Update game logic
		update(delta_time)

		// Render to texture
		sdl.SetRenderTarget(g_renderer, world_target)
		sdl.SetRenderDrawColor(g_renderer, 0x20, 0x20, 0x40, 0xFF) // Dark blue background
		sdl.RenderClear(g_renderer)
		draw_player(g_renderer)
		// Draw FPS counter
		if avg_fps > 0 {
			fps_text := fmt.tprintf("FPS: %.1f", avg_fps)
			// Note: In a real application, you'd want to render text using SDL_ttf
			// For now, we'll just draw a simple indicator
			sdl.SetRenderDrawColor(g_renderer, 0xFF, 0xFF, 0xFF, 0xFF)
			sdl.RenderPoint(g_renderer, 10, 10) // Simple FPS indicator dot
		} // Present to screen
		sdl.SetRenderTarget(g_renderer, nil)
		sdl.RenderTexture(g_renderer, world_target, nil, nil)
		sdl.RenderPresent(g_renderer)
		n_frames += 1	
		// Cap framerate
		if frame_ticks := timer.tick(&cap_timer); frame_ticks < TICKS_PER_FRAME {
			sdl.Delay(sdl.Uint32(TICKS_PER_FRAME - frame_ticks))
		}
	}
}