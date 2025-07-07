package main

import "core:fmt"
import "core:time"
import sdl "vendor:sdl3"
import "../../sutil/tex"
import "../../sutil/timer"

WIDTH :: 640
HEIGHT :: 480
SCREEN_FPS :: 60

WALKING_ANIMATION_FRAMES :: 4
WALKING_ANIMATION_FRAMES_PER_SPRITE :: 6
SPRITE_WIDTH :: 64
SPRITE_HEIGHT :: 205

renderer: ^sdl.Renderer
window: ^sdl.Window
sprite_sheet_texture: ^tex.Texture

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "SDL3 Tutorial: Animation",
        WIDTH, HEIGHT, {},
        &window, &renderer
    ) {
        fmt.eprintfln("Window could not be created! SDL error: %s", sdl.GetError())
        return false
    }
    return true
}

load_media :: proc() -> bool {
    sprite_sheet_texture = new(tex.Texture)
    if ok := tex.from_img(renderer, sprite_sheet_texture, "foo-sprite.png"); !ok {
        fmt.eprintln("Failed to load sprite sheet!")
        return false
    }
    return true
}

main :: proc() {
    exit_code: int
    if !init() {
        fmt.eprintln("Failed to init")
        exit_code = 1
    } else {
        if !load_media() {
            fmt.eprintln("Failed to load media")
            exit_code = 2
        } else {
            cap_timer: timer.Timer
            frame: int = 0 // Start at frame 0, not -1
            e: sdl.Event
            quit: bool
            
            // Pre-define sprite clips as SDL_FRect for SDL3
            sprite_clips := [WALKING_ANIMATION_FRAMES]sdl.FRect{
                {f32(SPRITE_WIDTH * 0), 0.0, f32(SPRITE_WIDTH), f32(SPRITE_HEIGHT)},
                {f32(SPRITE_WIDTH * 1), 0.0, f32(SPRITE_WIDTH), f32(SPRITE_HEIGHT)},
                {f32(SPRITE_WIDTH * 2), 0.0, f32(SPRITE_WIDTH), f32(SPRITE_HEIGHT)},
                {f32(SPRITE_WIDTH * 3), 0.0, f32(SPRITE_WIDTH), f32(SPRITE_HEIGHT)},
            }
            
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
                }
                
                // Calculate current animation frame
                current_frame := (frame / WALKING_ANIMATION_FRAMES_PER_SPRITE) % WALKING_ANIMATION_FRAMES
                
                // Fill background
                sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
                sdl.RenderClear(renderer)
                
                // Calculate render position (centered)
                render_x := f32((WIDTH - SPRITE_WIDTH) / 2)
                render_y := f32((HEIGHT - SPRITE_HEIGHT) / 2)
                
                // Create destination rectangle
                dst_rect := sdl.FRect{
                    x = render_x,
                    y = render_y,
                    w = f32(SPRITE_WIDTH),
                    h = f32(SPRITE_HEIGHT),
                }
                
                // Render current frame using SDL3's rendering function
                if sprite_sheet_texture != nil && sprite_sheet_texture.texture != nil {
                    current_clip := &sprite_clips[current_frame]
                    
                    // Use SDL3's rendering function directly
                    sdl.RenderTexture(renderer, sprite_sheet_texture.texture, current_clip, &dst_rect)
                }
                
                sdl.RenderPresent(renderer)
                
                // Advance frame
                frame += 1
                
                // Cap frame rate
                timer.cap(&cap_timer, SCREEN_FPS)
            }
        }
    }
    exit()
}

exit :: proc() {
    if sprite_sheet_texture != nil {
        tex.destroy(sprite_sheet_texture)
        free(sprite_sheet_texture)
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