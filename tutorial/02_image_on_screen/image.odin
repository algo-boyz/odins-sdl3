package main

import "core:fmt"
import sdl "vendor:sdl3"

WIDTH :: 640
HEIGHT :: 480
screen_surface : ^sdl.Surface
window : ^sdl.Window
img : ^sdl.Surface

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load media")
    }
    sdl.BlitSurface(img, nil, screen_surface, nil)
    sdl.UpdateWindowSurface(window)
    e: sdl.Event
    for {
        _ = sdl.PollEvent(&e)
        if e.type == sdl.EventType.QUIT {
            break
        }
    }
    exit()
}

exit :: proc() {
    sdl.DestroySurface(img)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    window = sdl.CreateWindow(
        "Image on Screen",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE},
    )
    if window == nil {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    screen_surface = sdl.GetWindowSurface(window)

    return true
}

load_media :: proc() -> bool {
    bmp : cstring = "./hello.bmp"
    img = sdl.LoadBMP(bmp)
    if img == nil {
        fmt.eprintfln("Unable to load image %s! SDL Error: %s", bmp, sdl.GetError())
        return false
    }
    return true
}