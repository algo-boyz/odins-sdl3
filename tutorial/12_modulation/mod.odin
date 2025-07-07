package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/tex"

WIDTH :: 640
HEIGHT :: 480
renderer: ^sdl.Renderer
texture: tex.Texture
window: ^sdl.Window

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load_media")
        return
    }
    r : u8 = 255
    g : u8 = 255
    b : u8 = 255
    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            } else if e.type == sdl.EventType.KEY_DOWN {
                switch e.key.key {
                    case sdl.K_Q : r = clamp(r + 32, r, 255)
                    case sdl.K_W : g = clamp(g + 32, g, 255)
                    case sdl.K_E : b = clamp(b + 32, b, 255)
                    case sdl.K_A : r = clamp(r - 32, 0, r)
                    case sdl.K_S : g = clamp(g - 32, 0, g)
                    case sdl.K_D : b = clamp(b - 32, 0, b)
                }
            }
        }
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
        sdl.RenderClear(renderer)
        tex.set_colour(texture, r, g, b)
        tex.render_rect(renderer, texture, 0, 0)
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    tex.destroy(&texture)
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    if !sdl.SetHint(sdl.HINT_RENDER_VSYNC, "1") {
        fmt.eprintln("Warning: Linear texture filtering not enabled!")
    }
    if !sdl.CreateWindowAndRenderer(
        "Colour Modulation",
        WIDTH, HEIGHT,
        {sdl.WindowFlag.RESIZABLE},
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)

    return true
}

load_media :: proc() -> bool {
    if !tex.from_img(renderer, &texture, "colors.png") {
        fmt.eprintln("Failed to load colors image.")
        return false
    }
    return true
}