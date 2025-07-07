package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/tex"

WIDTH :: 640
HEIGHT :: 480
window: ^sdl.Window
renderer: ^sdl.Renderer
texture_fade_in, texture_fade_out: ^tex.Texture

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load_media")
        return
    }
    alpha: u8 = 255
    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            } else if e.type == sdl.EventType.KEY_DOWN {
                switch e.key.key {
                    case sdl.K_S: alpha = clamp(alpha + 32, alpha, 255)
                    case sdl.K_W : alpha = clamp(alpha - 32, 0, alpha)
                }
            }
        }
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
        sdl.RenderClear(renderer)
        tex.render_rect(renderer, texture_fade_out, 0, 0)
        tex.set_alpha(texture_fade_in, alpha)
        tex.render_rect(renderer, texture_fade_in, 0, 0)
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    tex.destroy(texture_fade_in)
    tex.destroy(texture_fade_out)
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> (ok: bool) {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return
    }
    if !sdl.SetHint(sdl.HINT_RENDER_VSYNC, "1") {
        fmt.eprintln("Warning: Linear texture filtering not enabled!")
    }
    if !sdl.CreateWindowAndRenderer(
        "Alpha Blending",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE},
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return
    }
    sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
    ok = true
    return
}

load_media :: proc() -> (ok: bool) {
    if !tex.from_img(renderer, texture_fade_in, "fadein.png") {
        fmt.eprintln("Failed to load fade in colors image.")
        return
    }
    tex.set_blend_mode(texture_fade_in, {sdl.BlendModeFlag.BLEND})

    if !tex.from_img(renderer, texture_fade_out, "fadeout.png") {
        fmt.eprintln("Failed to load fade out colors image.")
        return
    }
    ok = true
    return
}