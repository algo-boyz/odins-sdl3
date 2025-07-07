package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"

WIDTH :: 640
HEIGHT :: 480
current_surface : ^sdl.Surface
key_press_surfaces : [KeyPressesSurfaces.Total] ^sdl.Surface
screen_surface : ^sdl.Surface
window : ^sdl.Window

KeyPressesSurfaces :: enum {
    Default,
    Up,
    Down,
    Left,
    Right,
    Total,
}

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
    current_surface = key_press_surfaces[KeyPressesSurfaces.Default]
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            }
            else if e.type == sdl.EventType.KEY_DOWN {
                switch e.key.key {
                    case sdl.K_UP:
                        current_surface = key_press_surfaces[KeyPressesSurfaces.Up]
                    case sdl.K_DOWN:
                        current_surface = key_press_surfaces[KeyPressesSurfaces.Down]
                    case sdl.K_LEFT:
                        current_surface = key_press_surfaces[KeyPressesSurfaces.Left]
                    case sdl.K_RIGHT:
                        current_surface = key_press_surfaces[KeyPressesSurfaces.Right]
                    case:
                        current_surface = key_press_surfaces[KeyPressesSurfaces.Default]
                }
            }
        }
        sdl.BlitSurface(current_surface, nil, screen_surface, nil)
        sdl.UpdateWindowSurface(window)
    }    
    exit()
}

exit :: proc() {
    for surface in key_press_surfaces {
        sdl.DestroySurface(surface)
    }
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.InitFlags{.VIDEO}) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    window = sdl.CreateWindow(
        "Image on Screen",
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

load_media :: proc() -> (ok: bool) {
    default := "./assets/press.bmp"
    up    := "./assets/up.bmp"
    down  := "./assets/down.bmp"
    left  := "./assets/left.bmp"
    right := "./assets/right.bmp"
    key_press_surfaces[KeyPressesSurfaces.Default] = load_surface(default)

    if key_press_surfaces[KeyPressesSurfaces.Default] == nil {
        fmt.eprintfln("Failed to load default image: %s", default)
        return
    }
    key_press_surfaces[KeyPressesSurfaces.Up] = load_surface(up)

    if key_press_surfaces[KeyPressesSurfaces.Up] == nil {
        fmt.eprintfln("Failed to load up image: %s", up)
        return
    }
    key_press_surfaces[KeyPressesSurfaces.Down] = load_surface(down)

    if key_press_surfaces[KeyPressesSurfaces.Down] == nil {
        fmt.eprintfln("Failed to load down image: %s", down)
        return
    }
    key_press_surfaces[KeyPressesSurfaces.Left] = load_surface(left)

    if key_press_surfaces[KeyPressesSurfaces.Left] == nil {
        fmt.eprintfln("Failed to load left image: %s", left)
        return
    }
    key_press_surfaces[KeyPressesSurfaces.Right] = load_surface(right)

    if key_press_surfaces[KeyPressesSurfaces.Right] == nil {
        fmt.eprintfln("Failed to load right image: %s", right)
        return
    }
    ok = true
    return
}

load_surface :: proc(path : string) -> ^sdl.Surface {
    surf := sdl.LoadBMP(strings.clone_to_cstring(path))
    if surf == nil {
        fmt.eprintfln("Unable to load image %s! SDL error: %s", path, sdl.GetError())
    }
    return surf
}