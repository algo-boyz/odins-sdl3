package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdimage "vendor:sdl3/image"
import "../../sutil/tex"

WIDTH :: 640
HEIGHT :: 480
BTN_WIDTH :: 300
BTN_HEIGHT :: 200

Mouse_State :: enum {
    MOUSE_OUT = 0,
    MOUSE_OVER_MOTION = 1,
    MOUSE_DOWN = 2,
    MOUSE_UP = 3,
}
Btn :: struct {
    pos: sdl.FPoint,
    current_state: Mouse_State,
}
renderer: ^sdl.Renderer
window: ^sdl.Window
img: ^sdl.Texture

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load media!")
        exit()
        return
    } // Create 4 buttons in corners
    buttons: [4]Btn
    btn_set_pos(&buttons[0], 0, 0)
    btn_set_pos(&buttons[1], WIDTH - BTN_WIDTH, 0)
    btn_set_pos(&buttons[2], 0, HEIGHT - BTN_HEIGHT)
    btn_set_pos(&buttons[3], WIDTH - BTN_WIDTH, HEIGHT - BTN_HEIGHT)
    e: sdl.Event
    quit: bool    
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            } // Handle button events
            for &button in buttons {
                btn_handle_event(&button, &e)
            }
        } // Clear screen
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
        sdl.RenderClear(renderer)
        // Render buttons
        for &button in buttons {
            btn_render(&button)
        }
        sdl.RenderPresent(renderer)
    }
    exit()
}

exit :: proc() {
    sdl.DestroyTexture(img)
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "SDL3 Tutorial: Mouse Events",
        WIDTH, HEIGHT, {}, &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    return true
}

load_media :: proc() -> bool {
    img = tex.sdl_from_img(renderer, "button.png")
    if img == nil {
        fmt.eprintln("Failed to load button sprite texture!")
        return false
    }
    return true
}

btn_set_pos :: proc(button: ^Btn, x, y: f32) {
    button.pos.x = x
    button.pos.y = y
}

btn_handle_event :: proc(button: ^Btn, e: ^sdl.Event) {
    if e.type == sdl.EventType.MOUSE_MOTION || 
       e.type == sdl.EventType.MOUSE_BUTTON_DOWN || 
       e.type == sdl.EventType.MOUSE_BUTTON_UP {
        // Get mouse position
        mouse_x, mouse_y: f32
        _ = sdl.GetMouseState(&mouse_x, &mouse_y)
        // Check if mouse is inside button
        inside := mouse_x >= button.pos.x && 
                  mouse_x < button.pos.x + BTN_WIDTH &&
                  mouse_y >= button.pos.y && 
                  mouse_y < button.pos.y + BTN_HEIGHT
        if !inside {
            button.current_state = Mouse_State.MOUSE_OUT
        } else { // Mouse is inside button
            #partial switch e.type {
            case sdl.EventType.MOUSE_MOTION:
                button.current_state = Mouse_State.MOUSE_OVER_MOTION
            case sdl.EventType.MOUSE_BUTTON_DOWN:
                button.current_state = Mouse_State.MOUSE_DOWN
            case sdl.EventType.MOUSE_BUTTON_UP:
                button.current_state = Mouse_State.MOUSE_UP
            }
        }
    }
}

btn_render :: proc(button: ^Btn) {
    // Define sprite clips - each button state is stacked vertically
    sprite_clips := [4]sdl.FRect{
        {0, 0 * BTN_HEIGHT, BTN_WIDTH, BTN_HEIGHT}, // MOUSE_OUT
        {0, 1 * BTN_HEIGHT, BTN_WIDTH, BTN_HEIGHT}, // MOUSE_OVER_MOTION
        {0, 2 * BTN_HEIGHT, BTN_WIDTH, BTN_HEIGHT}, // MOUSE_DOWN
        {0, 3 * BTN_HEIGHT, BTN_WIDTH, BTN_HEIGHT}, // MOUSE_UP
    } // Set destination rectangle
    dst_rect := sdl.FRect{
        x = button.pos.x,
        y = button.pos.y,
        w = BTN_WIDTH,
        h = BTN_HEIGHT,
    } // Render the current sprite
    current_clip := &sprite_clips[int(button.current_state)]
    sdl.RenderTexture(renderer, img, current_clip, &dst_rect)
}