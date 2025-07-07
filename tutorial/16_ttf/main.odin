package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import sdl "vendor:sdl3"
import img "vendor:sdl3/image"
import font "../../sutil/font"

WIDTH :: 640
HEIGHT :: 480
SDL_FLAGS :: sdl.INIT_VIDEO
WINDOW_FLAG :: sdl.WindowFlags.RESIZABLE
TITLE :: "SDL3 Tutorial: True Type Fonts"
FONT_SIZE :: 28
TEXT :: "The quick brown fox jumps over the lazy dog"
COLOR :: sdl.Color{0, 0, 0, 255}

Game :: struct {
	window:     ^sdl.Window,
	renderer:   ^sdl.Renderer,
	event:       sdl.Event,
	font:	    ^font.Font,
}

destroy :: proc(g: ^Game) {
	if g != nil {
		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}
		sdl.Quit()
	}
}

init :: proc(g: ^Game) -> bool {
	if !sdl.Init(SDL_FLAGS) {
		fmt.eprintfln("Error init SDL3: %s", sdl.GetError())
		return false
	}
	if !sdl.CreateWindowAndRenderer(
		TITLE,
		WIDTH,
		HEIGHT,
		{WINDOW_FLAG},
        &g.window,
        &g.renderer,
	) {
		fmt.eprintfln("Error creating Window: %s", sdl.GetError())
		return false
	}
	return true
}

run :: proc(g: ^Game) {
	for {
		for sdl.PollEvent(&g.event) {
			#partial switch g.event.type {
			case .QUIT:
				return
			case .KEY_DOWN:
                switch g.event.key.key {
                case sdl.K_ESCAPE:
					return
				}
			}
		}
		// White background
		sdl.SetRenderDrawColor(g.renderer, 0xFF, 0xFF, 0xFF, 0xFF)
		sdl.RenderClear(g.renderer)
		// Render centered text
		font.render(g.font, g.renderer, TEXT, COLOR)
		sdl.RenderPresent(g.renderer)
		sdl.Delay(16)
	}
}

main :: proc() {
	exit_code: int
	g: Game
	defer os.exit(exit_code)
	defer destroy(&g)
	if !init(&g) {
		exit_code = 1
		return
	}
	g.font = font.load(g.renderer, "../lazy.ttf", WIDTH, HEIGHT, FONT_SIZE) 
	if g.font == nil {
		exit_code = 1
		return
	}
	run(&g)
}