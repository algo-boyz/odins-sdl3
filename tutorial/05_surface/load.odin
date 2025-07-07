package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"

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
    stretched_surface = load_surface("stretch.bmp")

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
    if !sdl.Init(sdl.InitFlags{.VIDEO}) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    window = sdl.CreateWindow(
        "Optimised Surface Loading and Soft Stretching",
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

load_surface :: proc(path : string) -> ^sdl.Surface {
    bmp := sdl.LoadBMP(strings.clone_to_cstring(path))
    if bmp == nil {
        fmt.eprintfln("Unable to load image %s! SDL error: %s", bmp, sdl.GetError())
        return bmp
    }
    surf := sdl.ConvertSurface(bmp, screen_surface.format)
    if surf == nil {
        fmt.eprintfln("Unable to optimise image %s! SDL error: %s", surf, sdl.GetError())
        return surf
    }
    sdl.DestroySurface(bmp)

    return surf
}