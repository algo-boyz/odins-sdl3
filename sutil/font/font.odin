package font

import "core:fmt"
import "core:math/rand"
import "core:os"
import sdl "vendor:sdl3"
import img "vendor:sdl3/image"
import ttf "vendor:sdl3/ttf"

is_initialized: bool

Font :: struct {
	w, h:        f32,
	ttf:         ^ttf.Font,
	text_rect:   sdl.FRect,  // Store as value, not pointer
	text_image:  ^sdl.Texture,
}

load :: proc(renderer: ^sdl.Renderer, path: cstring, w, h, size: f32) -> (f: ^Font) {
	if !is_initialized && !ttf.Init() {
		fmt.eprintfln("Error init SDL3_TTF: %s", sdl.GetError())
		return nil
	}
	font := ttf.OpenFont(path, size)
	if font == nil {
		fmt.eprintfln("Could not load font! SDL_ttf Error: %s", sdl.GetError())
		return nil
	}
	f = new(Font)
	f.ttf = font
	f.w = w
	f.h = h
	f.text_rect = {0, 0, w, h}
	f.text_image = nil
	is_initialized = true
	
	return f
}

render :: proc(f: ^Font, renderer: ^sdl.Renderer, x, y: f32, text: string, color: sdl.Color) -> bool {
	// Clean up previous texture if it exists
	if f.text_image != nil {
		sdl.DestroyTexture(f.text_image)
		f.text_image = nil
	}
	
	// Create text surface
	font_surf := ttf.RenderText_Blended(f.ttf, fmt.ctprint(text), 0, color)
	if font_surf == nil {
		fmt.eprintfln("Error creating text Surface: %s", sdl.GetError())
		return false
	}
	defer sdl.DestroySurface(font_surf)
	
	// Create texture from surface
	f.text_image = sdl.CreateTextureFromSurface(renderer, font_surf)
	if f.text_image == nil {
		fmt.eprintfln("Error creating Texture from Surface: %s", sdl.GetError())
		return false
	}
	
	// Set text dimensions and position
	f.text_rect.w = f32(font_surf.w)
	f.text_rect.h = f32(font_surf.h)
	f.text_rect.x = x
	f.text_rect.y = y
	
	// Render the text
	sdl.RenderTexture(renderer, f.text_image, nil, &f.text_rect)
	return true
}

destroy :: proc(f: ^Font) {
	if f != nil {
		if f.text_image != nil { 
			sdl.DestroyTexture(f.text_image)
			f.text_image = nil
		}
		if f.ttf != nil {
			ttf.CloseFont(f.ttf)
			f.ttf = nil
		}
		free(f)
	}
	// Only quit TTF if we initialized it
	if is_initialized {
		ttf.Quit()
		is_initialized = false
	}
}