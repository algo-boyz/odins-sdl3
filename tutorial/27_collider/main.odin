package main

import "core:fmt"
import "core:time"
import sdl "vendor:sdl3"
import "../../sutil/timer"

WIDTH :: 640
HEIGHT :: 480
SCREEN_FPS :: 60

// Square constants
SQUARE_WIDTH :: 20
SQUARE_HEIGHT :: 20
SQUARE_VEL :: 10

// Square struct
Square :: struct {
    collision_box: sdl.Rect,
    vel_x: i32,
    vel_y: i32,
}

// Global variables
renderer: ^sdl.Renderer
window: ^sdl.Window

// Square procedures
square_init :: proc(square: ^Square) {
    square.collision_box = {0, 0, SQUARE_WIDTH, SQUARE_HEIGHT}
    square.vel_x = 0
    square.vel_y = 0
}

square_handle_event :: proc(square: ^Square, e: ^sdl.Event) {
    // If a key was pressed
    if e.type == sdl.EventType.KEY_DOWN && !e.key.repeat {
        switch e.key.key {
        case sdl.K_UP:
            square.vel_y -= SQUARE_VEL
        case sdl.K_DOWN:
            square.vel_y += SQUARE_VEL
        case sdl.K_LEFT:
            square.vel_x -= SQUARE_VEL
        case sdl.K_RIGHT:
            square.vel_x += SQUARE_VEL
        }
    } else if e.type == sdl.EventType.KEY_UP && !e.key.repeat {
        // If a key was released
        switch e.key.key {
        case sdl.K_UP:
            square.vel_y += SQUARE_VEL
        case sdl.K_DOWN:
            square.vel_y -= SQUARE_VEL
        case sdl.K_LEFT:
            square.vel_x += SQUARE_VEL
        case sdl.K_RIGHT:
            square.vel_x -= SQUARE_VEL
        }
    }
}

square_move :: proc(square: ^Square, collider: sdl.Rect) {
    // Move the square left or right
    square.collision_box.x += square.vel_x
    
    // If the square went off screen or hit the wall
    if square.collision_box.x < 0 || 
       square.collision_box.x + SQUARE_WIDTH > WIDTH ||
       check_collision(square.collision_box, collider) {
        // Move back
        square.collision_box.x -= square.vel_x
    }
    
    // Move the square up or down
    square.collision_box.y += square.vel_y
    
    // If the square went off screen or hit the wall
    if square.collision_box.y < 0 || 
       square.collision_box.y + SQUARE_HEIGHT > HEIGHT ||
       check_collision(square.collision_box, collider) {
        // Move back
        square.collision_box.y -= square.vel_y
    }
}

square_render :: proc(renderer: ^sdl.Renderer, square: ^Square) {
    // Show the square
    drawing_rect := sdl.FRect{
        f32(square.collision_box.x),
        f32(square.collision_box.y),
        f32(square.collision_box.w),
        f32(square.collision_box.h),
    }
    sdl.SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF)
    sdl.RenderRect(renderer, &drawing_rect)
}

check_collision :: proc(a: sdl.Rect, b: sdl.Rect) -> bool {
    // Calculate the sides of rect A
    a_min_x := a.x
    a_max_x := a.x + a.w
    a_min_y := a.y
    a_max_y := a.y + a.h
    
    // Calculate the sides of rect B
    b_min_x := b.x
    b_max_x := b.x + b.w
    b_min_y := b.y
    b_max_y := b.y + b.h
    
    // If left side of A is to the right of B
    if a_min_x >= b_max_x {
        return false
    }
    
    // If the right side of A is to the left of B
    if a_max_x <= b_min_x {
        return false
    }
    
    // If the top side of A is below B
    if a_min_y >= b_max_y {
        return false
    }
    
    // If the bottom side of A is above B
    if a_max_y <= b_min_y {
        return false
    }
    
    // If none of the sides from A are outside B
    return true
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "SDL3 Tutorial: Collision Detection",
        WIDTH, HEIGHT, {},
        &window, &renderer
    ) {
        fmt.eprintfln("Window could not be created! SDL error: %s", sdl.GetError())
        return false
    }
    return true
}

close :: proc() {
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

main :: proc() {
    exit_code: int
    if !init() {
        fmt.eprintln("Unable to initialize program!")
        exit_code = 1
    } else {
        // Timer to cap frame rate
        cap_timer: timer.Timer
        // Square we will be moving around on the screen
        square: Square
        square_init(&square)
        
        // The wall we will be colliding with
        wall_width := SQUARE_WIDTH
        wall_height := HEIGHT - SQUARE_HEIGHT * 2
        wall := sdl.Rect{
            i32((WIDTH - wall_width) / 2),
            i32((HEIGHT - wall_height) / 2),
            i32(wall_width),
            i32(wall_height),
        }
        
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
                square_handle_event(&square, &e)
            }
            
            // Update square
            square_move(&square, wall)
            
            // Fill the background
            sdl.SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF)
            sdl.RenderClear(renderer)
            
            // Render wall
            wall_drawing_rect := sdl.FRect{
                f32(wall.x),
                f32(wall.y),
                f32(wall.w),
                f32(wall.h),
            }
            sdl.SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF)
            sdl.RenderRect(renderer, &wall_drawing_rect)
            
            // Render square
            square_render(renderer, &square)
            
            // Update screen
            sdl.RenderPresent(renderer)
            
            // Cap frame rate
            timer.cap(&cap_timer, SCREEN_FPS)
        }
    }
    close()
}