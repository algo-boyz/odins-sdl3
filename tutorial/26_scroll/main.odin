package main

import "core:fmt"
import "core:time"
import sdl "vendor:sdl3"
import "../../sutil/tex"
import "../../sutil/timer"

WIDTH :: 640
HEIGHT :: 480
SCREEN_FPS :: 60

// Level constants
LEVEL_WIDTH :: 1280
LEVEL_HEIGHT :: 960

// Dot constants
DOT_WIDTH :: 20
DOT_HEIGHT :: 20
DOT_VEL :: 10

// Dot struct
Dot :: struct {
    pos_x: i32,
    pos_y: i32,
    vel_x: i32,
    vel_y: i32,
}

// Camera struct
Camera :: sdl.Rect

// Global variables
renderer: ^sdl.Renderer
window: ^sdl.Window
dot_texture: ^tex.Texture
bg_texture: ^tex.Texture

// Dot procedures
dot_init :: proc(dot: ^Dot) {
    dot.pos_x = 0
    dot.pos_y = 0
    dot.vel_x = 0
    dot.vel_y = 0
}

dot_handle_event :: proc(dot: ^Dot, e: ^sdl.Event) {
    // If a key was pressed
    if e.type == sdl.EventType.KEY_DOWN && !e.key.repeat {
        // Adjust the velocity
        switch e.key.key {
        case sdl.K_UP:
            dot.vel_y -= DOT_VEL
        case sdl.K_DOWN:
            dot.vel_y += DOT_VEL
        case sdl.K_LEFT:
            dot.vel_x -= DOT_VEL
        case sdl.K_RIGHT:
            dot.vel_x += DOT_VEL
        }
    } else if e.type == sdl.EventType.KEY_UP && !e.key.repeat {
        // If a key was released adjust the velocity
        switch e.key.key {
        case sdl.K_UP:
            dot.vel_y += DOT_VEL
        case sdl.K_DOWN:
            dot.vel_y -= DOT_VEL
        case sdl.K_LEFT:
            dot.vel_x += DOT_VEL
        case sdl.K_RIGHT:
            dot.vel_x -= DOT_VEL
        }
    }
}

dot_move :: proc(dot: ^Dot) {
    // Move the dot left or right
    dot.pos_x += dot.vel_x
    // If the dot went too far to the left or right
    if dot.pos_x < 0 || dot.pos_x + DOT_WIDTH > LEVEL_WIDTH {
        // Move back
        dot.pos_x -= dot.vel_x
    }
    // Move the dot up or down
    dot.pos_y += dot.vel_y
    // If the dot went too far up or down
    if dot.pos_y < 0 || dot.pos_y + DOT_HEIGHT > LEVEL_HEIGHT {
        // Move back
        dot.pos_y -= dot.vel_y
    }
}

dot_render :: proc(renderer: ^sdl.Renderer, dot: ^Dot, camera: ^Camera) {
    if dot_texture != nil {
        // Render dot relative to camera position
        tex.render_rect(renderer, dot_texture, f32(dot.pos_x - camera.x), f32(dot.pos_y - camera.y))
    }
}

dot_get_pos_x :: proc(dot: ^Dot) -> i32 {
    return dot.pos_x
}

dot_get_pos_y :: proc(dot: ^Dot) -> i32 {
    return dot.pos_y
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "SDL3 Tutorial: Scrolling",
        WIDTH, HEIGHT, {},
        &window, &renderer
    ) {
        fmt.eprintfln("Window could not be created! SDL error: %s", sdl.GetError())
        return false
    }
    return true
}

load_media :: proc() -> bool {
    // Allocate memory for the textures
    dot_texture = new(tex.Texture)
    if dot_texture == nil {
        fmt.eprintln("Failed to allocate memory for dot texture!")
        return false
    }
    if ok := tex.from_img(renderer, dot_texture, "../dot.png"); !ok {
        fmt.eprintln("Failed to load dot image!")
        return false
    }
    bg_texture = new(tex.Texture)
    if bg_texture == nil {
        fmt.eprintln("Failed to allocate memory for background texture!")
        return false
    }
    if ok := tex.from_img(renderer, bg_texture, "../bg.png"); !ok {
        fmt.eprintln("Failed to load background image!")
        return false
    }
    return true
}

main :: proc() {
    exit_code: int
    if !init() {
        fmt.eprintln("Failed to init program")
        exit_code = 1
    } else {
        if !load_media() {
            fmt.eprintln("Failed to load media")
            exit_code = 2
        } else {          
            // Timer to cap frame rate
            cap_timer: timer.Timer
            // Dot we will be moving around on screen
            dot: Dot
            dot_init(&dot)
            // Camera that follows the dot
            camera: Camera = {0.0, 0.0, WIDTH, HEIGHT}
            e: sdl.Event
            quit: bool  
            for !quit {
                timer.start(&cap_timer)
                for sdl.PollEvent(&e) {
                    #partial switch e.type {
                    case .QUIT:
                        quit = true
                    case .KEY_DOWN:
                        switch e.key.key {
                        case sdl.K_ESCAPE:
                            quit = true
                        }
                    }
                    // Process dot events
                    dot_handle_event(&dot, &e)
                }
                // Update dot
                dot_move(&dot)
                
                // Center camera over dot
                camera.x = i32(dot_get_pos_x(&dot) + DOT_WIDTH / 2 - WIDTH / 2)
                camera.y = i32(dot_get_pos_y(&dot) + DOT_HEIGHT / 2 - HEIGHT / 2)
                
                // Bound the camera
                if camera.x < 0 {
                    camera.x = 0
                } else if camera.x + camera.w > LEVEL_WIDTH {
                    camera.x = LEVEL_WIDTH - camera.w
                }
                if camera.y < 0 {
                    camera.y = 0
                } else if camera.y + camera.h > LEVEL_HEIGHT {
                    camera.y = LEVEL_HEIGHT - camera.h
                }
                // Fill the background
                sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
                sdl.RenderClear(renderer)
                // Show background (with camera offset)
                render_clipped(renderer, bg_texture, 0, 0, &camera)
                // Render dot
                dot_render(renderer, &dot, &camera)
                // Update screen
                sdl.RenderPresent(renderer)
                // Cap frame rate
                timer.cap(&cap_timer, SCREEN_FPS)
            }
        }
    }
    exit()
}

exit :: proc() {
    if dot_texture != nil {
        tex.destroy(dot_texture)
        free(dot_texture)
    }
    if bg_texture != nil {
        tex.destroy(bg_texture)
        free(bg_texture)
    }
    if renderer != nil {
        sdl.DestroyRenderer(renderer)
        renderer = nil
    }
    if window != nil {
        sdl.DestroyWindow(window)
        window = nil
    }
    sdl.Quit()
}

render_clipped :: proc(renderer: ^sdl.Renderer, texture: ^tex.Texture, x : i32, y : i32, clip : ^sdl.Rect) {
    dst_rect := sdl.FRect {
        x = f32(x),
        y = f32(y),
        w = f32(texture.w),
        h = f32(texture.h)
    }
    
    src_rect: ^sdl.FRect = nil
    
    if clip != nil {
        // Use clip as source rectangle to determine which part of texture to render
        src_clip := sdl.FRect {
            x = f32(clip.x),
            y = f32(clip.y),
            w = f32(clip.w),
            h = f32(clip.h)
        }
        src_rect = &src_clip
        
        // Destination should be the size of the clip (screen size)
        dst_rect.w = f32(clip.w)
        dst_rect.h = f32(clip.h)
    }
    
    // Render with source clipping
    sdl.RenderTexture(renderer, texture.texture, src_rect, &dst_rect)
}