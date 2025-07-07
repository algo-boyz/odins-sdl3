package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import sdl "vendor:sdl3"
import img "vendor:sdl3/image"
import ttf "vendor:sdl3/ttf"

SDL_FLAGS :: sdl.INIT_VIDEO
WINDOW_FLAGS :: sdl.WINDOW_RESIZABLE
RENDER_FLAGS :: sdl.RENDERER_VSYNC_ADAPTIVE

WINDOW_TITLE :: "Moving Text"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

FONT_SIZE :: 80
FONT_TEXT :: "Odin"
FONT_COLOR :: sdl.Color{255, 255, 255, 255}
TEXT_VEL :: 3

Game :: struct {
	window:     ^sdl.Window,
	renderer:   ^sdl.Renderer,
	event:      sdl.Event,
	background: ^sdl.Texture,
	text_rect:  sdl.FRect,
	text_image: ^sdl.Texture,
	text_xvel:  f32,
	text_yvel:  f32,
}

game_cleanup :: proc(g: ^Game) {
	if g != nil {
		if g.text_image != nil {sdl.DestroyTexture(g.text_image)}
		if g.background != nil {sdl.DestroyTexture(g.background)}

		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}

		ttf.Quit()
		sdl.Quit()
	}
}

initialize :: proc(g: ^Game) -> bool {
	if !sdl.Init(SDL_FLAGS) {
		fmt.eprintfln("Error initializing SDL2: %s", sdl.GetError())
		return false
	}
	if !ttf.Init() {
		fmt.eprintfln("Error initializing SDL2_TTF: %s", sdl.GetError())
		return false
	}
	if !sdl.CreateWindowAndRenderer(
		WINDOW_TITLE,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		WINDOW_FLAGS,
		&g.window,
		&g.renderer,
	) {
		fmt.eprintfln("Error creating Window and Renderer: %s", sdl.GetError())
		return false
	}
	g.text_xvel = TEXT_VEL
	g.text_yvel = TEXT_VEL
	return true
}

load_media :: proc(g: ^Game) -> bool {
	g.background = img.LoadTexture(g.renderer, "../bg.png")
	if g.background == nil {
		fmt.eprintfln("Error loading Texture: %s", sdl.GetError())
		return false
	}
	font := ttf.OpenFont("../lazy.ttf", FONT_SIZE)
	if font == nil {
		fmt.eprintfln("Error opening Font: %s", sdl.GetError())
		return false
	}

	font_surf := ttf.RenderText_Blended(font, FONT_TEXT, 0, FONT_COLOR)
	ttf.CloseFont(font)
	if font_surf == nil {
		fmt.eprintfln("Error creating text Surface: %s", sdl.GetError())
		return false
	}

	g.text_rect.w = f32(font_surf.w)
	g.text_rect.h = f32(font_surf.h)

	g.text_image = sdl.CreateTextureFromSurface(g.renderer, font_surf)
	sdl.DestroySurface(font_surf)
	if g.text_image == nil {
		fmt.eprintfln("Error creating Texture from Surface: %s", sdl.GetError())
		return false
	}

	return true
}

rand_background :: proc(g: ^Game) {
	sdl.SetRenderDrawColor(
		g.renderer,
		u8(rand.int31_max(256)),
		u8(rand.int31_max(256)),
		u8(rand.int31_max(256)),
		255,
	)
}

text_update :: proc(g: ^Game) {
	g.text_rect.x += g.text_xvel
	if g.text_rect.x < 0 {
		g.text_xvel = TEXT_VEL
	}
	if g.text_rect.x + g.text_rect.w > SCREEN_WIDTH {
		g.text_xvel = -TEXT_VEL
	}
	g.text_rect.y += g.text_yvel
	if g.text_rect.y < 0 {
		g.text_yvel = TEXT_VEL
	}
	if g.text_rect.y + g.text_rect.h > SCREEN_HEIGHT {
		g.text_yvel = -TEXT_VEL
	}
}

game_run :: proc(g: ^Game) {
	for {
		for sdl.PollEvent(&g.event) {
			#partial switch g.event.type {
			case .QUIT:
				return // Exit the game loop
			case .KEY_DOWN:
				switch g.event.key.key {
				case sdl.K_ESCAPE:
					return // Exit the game loop
				case sdl.K_SPACE:
					rand_background(g)
				}
			}
		}
		text_update(g)

		sdl.RenderClear(g.renderer)

		sdl.RenderTexture(g.renderer, g.background, nil, nil)
		sdl.RenderTexture(g.renderer, g.text_image, nil, &g.text_rect)

		sdl.RenderPresent(g.renderer)

		sdl.Delay(16)
	}
}

main :: proc() {
	exit_status := 0
	game: Game

	defer os.exit(exit_status)
	defer game_cleanup(&game)

	if !initialize(&game) {
		exit_status = 1
		return
	}
	if !load_media(&game) {
		exit_status = 1
		return
	}
	game_run(&game)
}