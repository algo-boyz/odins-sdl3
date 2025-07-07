package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/texture"

WIDTH :: 640
HEIGHT :: 480
renderer : ^sdl.Renderer
texture : ^sdl.Texture
window : ^sdl.Window

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "Texture Loading and Rendering",
        WIDTH, HEIGHT,
        sdl.WINDOW_RESIZABLE,
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)

    texture = texture.load(renderer, "texture.png")
    if texture == nil {
        fmt.eprintln("Failed to load_media!")
        return false
    }
    return true
}

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
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF );
        sdl.RenderClear(renderer)
        texture.render(renderer, texture)
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    texture.destroy(texture)
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}