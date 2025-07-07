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
arrow: ^tex.Texture = new(tex.Texture)

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    flip_mode : sdl.FlipMode = sdl.FlipMode.NONE
    angle: f64
    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            } else if e.type == sdl.EventType.KEY_DOWN {
                switch e.key.key {
                    case sdl.K_LEFT:
                        angle -= 36
                    case sdl.K_RIGHT:
                        angle += 36
                    case sdl.K_1:
                        flip_mode = sdl.FlipMode.HORIZONTAL
                    case sdl.K_2:
                        flip_mode = sdl.FlipMode.NONE
                    case sdl.K_3:
                        flip_mode = sdl.FlipMode.VERTICAL
                }
            }
        }
        // Fill the background white
        sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
        sdl.RenderClear(renderer)
        
        // Define center from corner of image
        center := sdl.FPoint{
            f32(arrow.w) / 2.0,
            f32(arrow.h) / 2.0,
        }
        // Calculate position to center the texture on screen
        x := f32(WIDTH - arrow.w) / 2.0
        y := f32(HEIGHT - arrow.h) / 2.0
        
        dst_rect := sdl.FRect{
            x = x,
            y = y,
            w = f32(arrow.w),
            h = f32(arrow.h),
        }
        // Draw texture rotated/flipped
        sdl.RenderTextureRotated(renderer, arrow.texture, nil, &dst_rect, angle, center, flip_mode)
        // Update screen
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    tex.destroy(arrow)
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.InitFlags{.VIDEO}) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "SDL3 Tutorial: Rotation and Flipping",
        WIDTH, HEIGHT,
        {sdl.WindowFlags.RESIZABLE},
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window and renderer. SDL_Error: %s", sdl.GetError())
        return false
    }
    if !load_media() {
        fmt.eprintln("Failed to load_media!")
        return false
    }
    return true
}

load_media :: proc() -> bool {
    tex.from_img(renderer, arrow, "arrow.png")
    if arrow == nil {
        fmt.eprintln("Failed to load arrow texture image.")
        return false
    }
    return true
}