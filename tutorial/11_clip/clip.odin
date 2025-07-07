package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/tex"

WIDTH :: 640
HEIGHT :: 480
renderer: ^sdl.Renderer
sprite_clips: [4]sdl.Rect
sprite_texture: tex.Texture
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
        tex.render_clipped(renderer, sprite_texture, 0, 0, &sprite_clips[0]) // Top left
        tex.render_clipped(renderer, sprite_texture, WIDTH - sprite_clips[1].w, 0, &sprite_clips[1]) // Top right
        tex.render_clipped(renderer, sprite_texture, 0, HEIGHT - sprite_clips[2].h, &sprite_clips[2]) // Bottom left
        tex.render_clipped(renderer, sprite_texture, WIDTH - sprite_clips[3].w, HEIGHT - sprite_clips[3].h, &sprite_clips[3]) // Bottom right
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    tex.destroy(&sprite_texture)
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
        "Clip Rendering and Sprite Sheets",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE},
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
    return true
}

load_media :: proc() -> bool {
    if !tex.from_img(renderer, &sprite_texture, "dots.png") {
        fmt.eprintln("Failed to load dots texture image.")
        return false
    }
    sprite_clips[0].x = 0
    sprite_clips[0].y = 0
    sprite_clips[0].w = 100
    sprite_clips[0].h = 100

    sprite_clips[1].x = 100
    sprite_clips[1].y = 0
    sprite_clips[1].w = 100
    sprite_clips[1].h = 100

    sprite_clips[2].x = 0
    sprite_clips[2].y = 100
    sprite_clips[2].w = 100
    sprite_clips[2].h = 100

    sprite_clips[3].x = 100
    sprite_clips[3].y = 100
    sprite_clips[3].w = 100
    sprite_clips[3].h = 100
    return true
}