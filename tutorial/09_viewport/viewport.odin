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
        // Top left corner viewport
        top_left_viewport := sdl.Rect {
            x = 0,
            y = 0,
            w = WIDTH / 2,
            h = HEIGHT / 2
        }
        sdl.SetRenderViewport(renderer, &top_left_viewport)
        sdl.RenderTexture(renderer, texture, nil, nil)
        // Top right viewport
        top_right_viewport := sdl.Rect {
            x = WIDTH / 2,
            y = 0,
            w = WIDTH / 2,
            h = HEIGHT / 2
        }
        sdl.SetRenderViewport(renderer, &top_right_viewport)
        sdl.RenderTexture(renderer, texture, nil, nil)
        // Bottom viewport
        bottom_viewport := sdl.Rect {
            x = 0,
            y = HEIGHT / 2,
            w = WIDTH,
            h = HEIGHT / 2
        }
        sdl.SetRenderViewport(renderer, &bottom_viewport)
        sdl.RenderTexture(renderer, texture, nil, nil)
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    sdl.DestroyRenderer(renderer)
    sdl.DestroyTexture(texture)
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
    if !sdl.CreateWindowAndRenderer(
        "Viewport",
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
    texture = load_texture("viewport.png")
    if texture == nil {
        fmt.eprintln("Failed to load texture image.")
        return false
    }
    return true
}

load_texture :: proc(texture : string) -> ^sdl.Texture {
    img := sdl_image.Load(strings.clone_to_cstring(texture))
    if img == nil {
        fmt.eprintfln("Unable to load images %s! sdl_image error: %s", texture, sdl.GetError())
        return nil
    }
    surf := sdl.CreateTextureFromSurface(renderer, img)
    if surf == nil {
        fmt.eprintfln("Unable to create texture from %s! sdl error: %s", surf, sdl.GetError())
    }
    sdl.DestroySurface(img)
    return surf
}