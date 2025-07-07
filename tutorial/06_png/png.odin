package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/tex"

WIDTH :: 640
HEIGHT :: 480
current_surface : ^sdl.Surface
screen_surface : ^sdl.Surface
stretched_surface : ^sdl.Surface
window : ^sdl.Window

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    stretched_surface = tex.img_to_surface("loaded.png", screen_surface.format)

    if stretched_surface == nil {
        fmt.eprintln("Failed to load surface!")
        return
    }
    stretch_rect := sdl.Rect {
        x = 0,
        y = 0,
        w = WIDTH,
        h = HEIGHT
    }
    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            }
        }
        sdl.BlitSurfaceScaled(stretched_surface, nil, screen_surface, &stretch_rect, sdl.ScaleMode.LINEAR)
        sdl.UpdateWindowSurface(window)
    }    
    exit()
}

exit :: proc() {
    sdl.DestroyWindow(window)
    sdl.DestroySurface(stretched_surface)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    window = sdl.CreateWindow(
        "Loading PNGs with SDL_image",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE}
    )
    if window == nil {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    screen_surface = sdl.GetWindowSurface(window)

    return true
}