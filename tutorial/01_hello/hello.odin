package main

import "core:fmt"

import sdl "vendor:sdl3"

WIDTH :: 640
HEIGHT :: 480

main :: proc() {
    if !sdl.Init(sdl.InitFlags{.VIDEO}) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return
    }
    defer sdl.Quit()

    window := sdl.CreateWindow(
        "Hello World",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE} // SDL3 uses flag sets
    )
    if window == nil {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return
    }
    defer sdl.DestroyWindow(window)

    screen_surface := sdl.GetWindowSurface(window)
    format_details := sdl.GetPixelFormatDetails(screen_surface.format)
    sdl.FillSurfaceRect(screen_surface, nil, sdl.MapRGB(format_details, nil, 0xFF, 0xFF, 0xFF)) // Fill with white
    sdl.UpdateWindowSurface(window)
    e: sdl.Event
    for {
        if sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                break
            }
        }
    }
}