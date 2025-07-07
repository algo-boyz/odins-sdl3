package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"

WIDTH :: 640
HEIGHT :: 480
renderer : ^sdl.Renderer
texture : ^sdl.Texture
window : ^sdl.Window

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            }
        }
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
        sdl.RenderClear(renderer)
        // Red filled quad
        sdl.SetRenderDrawColor(renderer, 0xFF, 0x00, 0x00, 0xFF)
        fill_rect : sdl.FRect = {
            x = WIDTH / 4,
            y = HEIGHT / 4,
            w = WIDTH / 2,
            h = HEIGHT / 2
        }
        sdl.RenderFillRect(renderer, &fill_rect)
        // Green outlined quad
        sdl.SetRenderDrawColor(renderer, 0x00, 0xFF, 0x00, 0xFF)
        outline_rect : sdl.FRect = {
            x = WIDTH / 6,
            y = HEIGHT / 6,
            w = WIDTH * 2 / 3,
            h = HEIGHT * 2 / 3
        }
        sdl.RenderRect(renderer, &outline_rect)
        // Blue horizontal line
        sdl.SetRenderDrawColor(renderer, 0x00, 0x00, 0xFF, 0xFF)
        sdl.RenderLine(renderer, 0, HEIGHT / 2, WIDTH, HEIGHT / 2)
        // Vertical line of yellow dots
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0x00, 0xFF)
        for y : f32 = 0; y < HEIGHT; y += 4 {
            sdl.RenderPoint(renderer, WIDTH / 2, y)
        }
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.InitFlags{.VIDEO}) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    if !sdl.SetHint(sdl.HINT_RENDER_VSYNC, "1") {
        fmt.eprintln("Warning: VSync hint not set!")
    }
    window = sdl.CreateWindow(
        "Geometry Rendering",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE}
    )
    if window == nil {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    renderer = sdl.CreateRenderer(window, nil)
    if renderer == nil {
        fmt.eprintfln("Could not create renderer. SDL_Error: %s", sdl.GetError())
        return false
    }
    return true
}