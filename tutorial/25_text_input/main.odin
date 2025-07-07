package main

import "core:fmt"
import "core:strings"
import "core:os"
import "core:c/libc"
import sdl "vendor:sdl3"
import "../../sutil/timer"
import "../../sutil/tex"
import "../../sutil/font"

WIDTH :: 640
HEIGHT :: 480
FPS :: 60
SDL_FLAGS :: sdl.INIT_VIDEO
WINDOW_FLAG :: sdl.WindowFlags.RESIZABLE
TITLE :: "SDL3 Tutorial: Text Input and Clipboard Handling"
FONT_SIZE :: 28
SOME_TEXT :: "Some Text"
TEXT_COLOR :: sdl.Color{0, 0, 0, 255}

State :: struct {
	window:              ^sdl.Window,
	renderer:            ^sdl.Renderer,
	event:               sdl.Event,
	font:                ^font.Font,
	input_text:          string,
	input_text_buffer:   [256]byte,
	input_text_len:      int,
	needs_text_update:   bool,
}

destroy :: proc(g: ^State) {
	if g != nil {
		if g.font != nil {
			font.destroy(g.font)
		}
		if g.renderer != nil {
			sdl.DestroyRenderer(g.renderer)
		}
		if g.window != nil {
			sdl.DestroyWindow(g.window)
		}
		sdl.Quit()
	}
}

init :: proc(g: ^State) -> bool {
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
	copy(g.input_text_buffer[:], SOME_TEXT) // Init text
	g.input_text_len = len(SOME_TEXT)
	g.input_text = string(g.input_text_buffer[:g.input_text_len])
	
	return true
}

load_media :: proc(g: ^State) -> bool {
	g.font = font.load(g.renderer, "../lazy.ttf", WIDTH, HEIGHT, FONT_SIZE)
	if g.font == nil {
		fmt.eprintfln("Could not load font")
		return false
	}
	return true
}

handle_backspace :: proc(g: ^State) {
	if g.input_text_len > 0 {
		g.input_text_len -= 1
		g.input_text = string(g.input_text_buffer[:g.input_text_len])
		g.needs_text_update = true
	}
}

handle_copy :: proc(g: ^State) {
	cstr := strings.clone_to_cstring(g.input_text)
	defer delete(cstr)
	sdl.SetClipboardText(cstr)
}

handle_paste :: proc(g: ^State) {
	clipboard_text := sdl.GetClipboardText()
	if clipboard_text != nil {
		defer sdl.free(clipboard_text)

		clipboard_len := libc.strlen(cast(cstring)clipboard_text)
		clipboard_slice := ([^]u8)(clipboard_text)[:clipboard_len]
		text_str := string(clipboard_slice)
		
		text_len := min(len(text_str), len(g.input_text_buffer) - 1)
		
		copy(g.input_text_buffer[:], text_str[:text_len])
		g.input_text_len = text_len
		g.input_text = string(g.input_text_buffer[:g.input_text_len])
		g.needs_text_update = true
	}
}

handle_text_input :: proc(g: ^State, text: cstring) {
	text_len := libc.strlen(text)
	text_slice := ([^]u8)(text)[:text_len]
	new_text := string(text_slice)
	
	remaining_space := len(g.input_text_buffer) - g.input_text_len - 1
	
	if len(new_text) <= remaining_space {
		copy(g.input_text_buffer[g.input_text_len:], new_text)
		g.input_text_len += len(new_text)
		g.input_text = string(g.input_text_buffer[:g.input_text_len])
		g.needs_text_update = true
	}
}

run :: proc(g: ^State) {
	cap_timer: timer.Timer
	if !sdl.StartTextInput(g.window) {
        fmt.eprintfln("Error starting text input: %s", sdl.GetError())
        return
    }
	defer {
        _ = sdl.StopTextInput(g.window)
    }
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
				case sdl.K_BACKSPACE:
					handle_backspace(g)
				case sdl.K_C:
        			if .LCTRL in sdl.GetModState() {
						handle_copy(g)
					}
				case sdl.K_V:
					if .LCTRL in sdl.GetModState() {
						handle_paste(g)
					}
				}
			case .TEXT_INPUT:
				text_len := libc.strlen(g.event.text.text)
				if text_len > 0 {
					text_slice := ([^]u8)(g.event.text.text)[:text_len]
					first_char := libc.toupper(i32(text_slice[0]))
					
					ctrl_pressed := .LCTRL in sdl.GetModState()
					is_copy_paste := ctrl_pressed && (first_char == 'C' || first_char == 'V')
					
					if !is_copy_paste {
						handle_text_input(g, g.event.text.text)
					}
				}
			}
		}
		// Clear screen with white background
		sdl.SetRenderDrawColor(g.renderer, 0xFF, 0xFF, 0xFF, 0xFF)
		sdl.RenderClear(g.renderer)
		
		// Render prompt text (centered horizontally, positioned in upper half)
		prompt_y :: (HEIGHT - FONT_SIZE * 2) / 2
		font.render(g.font, g.renderer, (WIDTH - g.font.w) / 2, prompt_y, "Enter Text:", TEXT_COLOR)
		
		// Render input text (centered horizontally, below prompt)
		input_y :: prompt_y + FONT_SIZE
		display_text := g.input_text if g.input_text_len > 0 else " "
		font.render(g.font, g.renderer, (WIDTH - g.font.w) / 2, input_y, display_text, TEXT_COLOR)
		
		sdl.RenderPresent(g.renderer)
        timer.cap(&cap_timer, FPS)
	}
}

main :: proc() {
	exit_code: int
	g: State
	defer os.exit(exit_code)
	defer destroy(&g)
	if !init(&g) {
		exit_code = 1
		return
	}
	if !load_media(&g) {
		exit_code = 2
		return
	}
	run(&g)
}