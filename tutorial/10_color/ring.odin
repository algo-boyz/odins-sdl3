package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/tex"

WIDTH :: 640
HEIGHT :: 480
background_texture, foo_texture : ^tex.Texture
renderer : ^sdl.Renderer
window : ^sdl.Window

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load_media")
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
        tex.render_rect(renderer, background_texture, 0, 0)
        tex.render_rect(renderer, foo_texture, 240, 190)
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    tex.destroy(background_texture)
    tex.destroy(foo_texture)
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
        "Accelerated Viewport",
        WIDTH, HEIGHT, {sdl.WindowFlags.RESIZABLE},
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
    return true
}

load_media :: proc() -> bool {
    if !tex.from_img(renderer, background_texture, "background.png") {
        fmt.eprintln("Failed to load background texture image.")
        return false
    }
    if !tex.from_img(renderer, foo_texture, "foo.png") {
        fmt.eprintln("Failed to load foo texture image.")
        return false
    }
    return true
}
