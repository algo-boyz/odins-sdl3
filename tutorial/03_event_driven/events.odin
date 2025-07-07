package main

import "core:fmt"
import sdl "vendor:sdl3"

WIDTH :: 640
HEIGHT :: 480
screen_surface : ^sdl.Surface
window : ^sdl.Window
lobal_img : ^sdl.Surface

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load media")
    }
    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            }
        }
        sdl.BlitSurface(lobal_img, nil, screen_surface, nil)
        sdl.UpdateWindowSurface(window)
    }    
    exit()
}

exit :: proc() {
    sdl.DestroySurface(lobal_img)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.InitFlags{.VIDEO}) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    window = sdl.CreateWindow(
        "Getting an Image on the Screen",
        WIDTH, HEIGHT, {sdl.WindowFlags.RESIZABLE}
    )
    if window == nil {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    screen_surface = sdl.GetWindowSurface(window)
    return true
}

load_media :: proc() -> bool {
    path : cstring = "./x.bmp"
    lobal_img = sdl.LoadBMP(path)
    if lobal_img == nil {
        fmt.eprintfln("Unable to load image %s! SDL Error: %s", path, sdl.GetError())
        return false
    }
    return true
}