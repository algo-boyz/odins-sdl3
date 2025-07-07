package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"
import "../../sutil/timer"

SDL_FLAGS :: sdl.INIT_VIDEO
WINDOW_FLAG :: sdl.WindowFlags.RESIZABLE
WINDOW_TITLE :: "SDL3 Tutorial: Frame Rate and VSync"
WIDTH :: 640
HEIGHT :: 480
SCREEN_FPS :: 60
FONT_SIZE :: 28
FONT_COLOR :: sdl.Color{0, 0, 0, 255}  // Black text

Game :: struct {
	window:         ^sdl.Window,
	renderer:       ^sdl.Renderer,
	event:          sdl.Event,
	font:           ^ttf.Font,
	fps_texture:    ^sdl.Texture,
	fps_rect:       sdl.FRect,
	vsync_enabled:  bool,
	fps_cap_enabled: bool,
}

destroy :: proc(g: ^Game) {
	if g != nil {
		if g.fps_texture != nil {sdl.DestroyTexture(g.fps_texture)}
		if g.font != nil {ttf.CloseFont(g.font)}
		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}
		ttf.Quit()
		sdl.Quit()
	}
}

init :: proc(g: ^Game) -> bool {
	if !sdl.Init(SDL_FLAGS) {
		fmt.eprintfln("SDL could not initialize! SDL error: %s", sdl.GetError())
		return false
	}
	
	if !sdl.CreateWindowAndRenderer(
		WINDOW_TITLE,
		WIDTH,
		HEIGHT,
		{WINDOW_FLAG},
		&g.window,
		&g.renderer,
	) {
		fmt.eprintfln("Window could not be created! SDL error: %s", sdl.GetError())
		return false
	}
	
	if !sdl.SetRenderVSync(g.renderer, 1) {
		fmt.eprintfln("Could not enable VSync! SDL error: %s", sdl.GetError())
		return false
	}
	
	if !ttf.Init() {
		fmt.eprintfln("SDL_ttf could not initialize! SDL_ttf error: %s", sdl.GetError())
		return false
	}
	
	g.vsync_enabled = true
	g.fps_cap_enabled = false
	
	return true
}

load_media :: proc(g: ^Game) -> bool {
	font_path :: "../lazy.ttf"
	g.font = ttf.OpenFont(font_path, FONT_SIZE)
	if g.font == nil {
		fmt.eprintfln("Could not load %s! SDL_ttf Error: %s", font_path, sdl.GetError())
		return false
	}
	
	// Load initial text
	initial_text := "Enter to start/stop or space to pause/unpause"
	if !load_text_texture(g, initial_text) {
		fmt.eprintfln("Could not load text texture! SDL_ttf Error: %s", sdl.GetError())
		return false
	}
	
	return true
}

load_text_texture :: proc(g: ^Game, text: string) -> bool {
	// Destroy previous texture if it exists
	if g.fps_texture != nil {
		sdl.DestroyTexture(g.fps_texture)
		g.fps_texture = nil
	}
	
	// Create text surface
	text_cstr := strings.clone_to_cstring(text)
	defer delete(text_cstr)
	
	font_surf := ttf.RenderText_Blended(g.font, text_cstr, 0, FONT_COLOR)
	if font_surf == nil {
		fmt.eprintfln("Error creating text Surface: %s", sdl.GetError())
		return false
	}
	defer sdl.DestroySurface(font_surf)
	
	// Set text dimensions and center position
	g.fps_rect.w = f32(font_surf.w)
	g.fps_rect.h = f32(font_surf.h)
	g.fps_rect.x = f32(WIDTH - font_surf.w) / 2.0
	g.fps_rect.y = f32(HEIGHT - font_surf.h) / 2.0
	
	g.fps_texture = sdl.CreateTextureFromSurface(g.renderer, font_surf)
	if g.fps_texture == nil {
		fmt.eprintfln("Error creating Texture from Surface: %s", sdl.GetError())
		return false
	}
	
	return true
}

run :: proc(g: ^Game) {
	cap_timer := timer.create()
	render_ns: u64 = 0
	for {
		timer.start(&cap_timer)
		
		for sdl.PollEvent(&g.event) {
			#partial switch g.event.type {
			case .QUIT:
				return
			case .KEY_DOWN:
				switch g.event.key.key {
				case sdl.K_ESCAPE:
					return
				case sdl.K_RETURN:
					// Toggle VSync
					g.vsync_enabled = !g.vsync_enabled
					vsync_value:i32 = 1 if g.vsync_enabled else 0
					sdl.SetRenderVSync(g.renderer, vsync_value)
				case sdl.K_SPACE:
					// Toggle FPS cap
					g.fps_cap_enabled = !g.fps_cap_enabled
				}
			}
		}
		// Update FPS text
		if render_ns != 0 {
			frames_per_second := 1_000_000_000.0 / f64(render_ns)
			
			// Build status string similar to C++ example
			status_text := strings.builder_make()
			defer strings.builder_destroy(&status_text)
			
			strings.write_string(&status_text, "Frames per second ")
			if g.vsync_enabled {
				strings.write_string(&status_text, "(VSync) ")
			}
			if g.fps_cap_enabled {
				strings.write_string(&status_text, "(Cap) ")
			}
			
			fps_str := fmt.tprintf("%.1f", frames_per_second)
			strings.write_string(&status_text, fps_str)
			
			final_text := strings.to_string(status_text)
			load_text_texture(g, final_text)
		}
		// Fill the background (white like C++ example)
		sdl.SetRenderDrawColor(g.renderer, 0xFF, 0xFF, 0xFF, 0xFF)
		sdl.RenderClear(g.renderer)
		
		// Draw text
		if g.fps_texture != nil {
			sdl.RenderTexture(g.renderer, g.fps_texture, nil, &g.fps_rect)
		}
		// Update screen
		sdl.RenderPresent(g.renderer)
		
		// Time to render frame
		render_ns = timer.tick(&cap_timer)
		
		// Time remaining in frame
		NS_PER_FRAME :: 1_000_000_000 / SCREEN_FPS
		if g.fps_cap_enabled && render_ns < NS_PER_FRAME {
			// Sleep remaining frame time
			sleep_time := NS_PER_FRAME - render_ns
			sdl.DelayNS(sleep_time)
			// Get frame time including sleep time
			render_ns = timer.tick(&cap_timer)
		}
	}
}

main :: proc() {
	exit_code := 0
	game: Game

	defer os.exit(exit_code)
	defer destroy(&game)

	if !init(&game) {
		fmt.eprintfln("Unable to initialize program!")
		exit_code = 1
		return
	}
	if !load_media(&game) {
		fmt.eprintfln("Unable to load media!")
		exit_code = 2
		return
	}
	run(&game)
}