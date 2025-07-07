package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"
import "../../sutil/tex"

Color_Channel :: enum {
    TEXTURE_RED = 0,
    TEXTURE_GREEN = 1,
    TEXTURE_BLUE = 2,
    TEXTURE_ALPHA = 3,
    BACKGROUND_RED = 4,
    BACKGROUND_GREEN = 5,
    BACKGROUND_BLUE = 6,
    TOTAL = 7,
    UNKNOWN = 8,
}
COLOR_MAGNITUDE_COUNT :: 3
COLOR_MAGNITUDES := [COLOR_MAGNITUDE_COUNT]u8{0x00, 0x7F, 0xFF}
WIDTH :: 640
HEIGHT :: 480
window : ^sdl.Window
renderer : ^sdl.Renderer
colors_texture :tex.Texture

main :: proc() {
    if !init() {
        fmt.eprintln("Failed to init!")
        return
    }
    if !load_media() {
        fmt.eprintln("Failed to load_media")
        return
    }
    // Init color channels
    color_channels_indices: [int(Color_Channel.TOTAL)]int
    color_channels_indices[int(Color_Channel.TEXTURE_RED)] = 2
    color_channels_indices[int(Color_Channel.TEXTURE_GREEN)] = 2
    color_channels_indices[int(Color_Channel.TEXTURE_BLUE)] = 2
    color_channels_indices[int(Color_Channel.TEXTURE_ALPHA)] = 2
    color_channels_indices[int(Color_Channel.BACKGROUND_RED)] = 2
    color_channels_indices[int(Color_Channel.BACKGROUND_GREEN)] = 2
    color_channels_indices[int(Color_Channel.BACKGROUND_BLUE)] = 2

    tex.set_blend_mode(colors_texture, {sdl.BlendModeFlag.BLEND})

    e: sdl.Event
    quit: bool
    for !quit {
        for sdl.PollEvent(&e) {
            if e.type == sdl.EventType.QUIT {
                quit = true
            } else if e.type == sdl.EventType.KEY_DOWN {
                channel_to_update := Color_Channel.UNKNOWN
                switch e.key.key {
                    // Update texture color
                    case sdl.K_A: channel_to_update = Color_Channel.TEXTURE_RED
                    case sdl.K_S: channel_to_update = Color_Channel.TEXTURE_GREEN
                    case sdl.K_D: channel_to_update = Color_Channel.TEXTURE_BLUE
                    case sdl.K_F: channel_to_update = Color_Channel.TEXTURE_ALPHA
                    // Update background color
                    case sdl.K_Q: channel_to_update = Color_Channel.BACKGROUND_RED
                    case sdl.K_W: channel_to_update = Color_Channel.BACKGROUND_GREEN
                    case sdl.K_E: channel_to_update = Color_Channel.BACKGROUND_BLUE
                } // If channel key was pressed
                if channel_to_update != Color_Channel.UNKNOWN {
                    // Cycle through channel values
                    color_channels_indices[int(channel_to_update)] += 1
                    if color_channels_indices[int(channel_to_update)] >= COLOR_MAGNITUDE_COUNT {
                        color_channels_indices[int(channel_to_update)] = 0
                    } // Write color values to console
                    fmt.printfln("Texture - R:%d G:%d B:%d A:%d | Background - R:%d G:%d B:%d",
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_RED)]],
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_GREEN)]],
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_BLUE)]],
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_ALPHA)]],
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.BACKGROUND_RED)]],
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.BACKGROUND_GREEN)]],
                        COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.BACKGROUND_BLUE)]])
                }
            }
        }
        // Fill the background
        sdl.SetRenderDrawColor(renderer,
            COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.BACKGROUND_RED)]],
            COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.BACKGROUND_GREEN)]],
            COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.BACKGROUND_BLUE)]],
            0xFF)
        sdl.RenderClear(renderer)
        // Set texture color and render
        tex.set_colour(colors_texture,
            COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_RED)]],
            COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_GREEN)]],
            COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_BLUE)]])
        tex.set_alpha(colors_texture, COLOR_MAGNITUDES[color_channels_indices[int(Color_Channel.TEXTURE_ALPHA)]]) 
        // Center the texture on screen
        x := (WIDTH - colors_texture.w) / 2
        y := (HEIGHT - colors_texture.h) / 2
        tex.render_clipped(renderer, colors_texture, x, y, nil)
        sdl.RenderPresent(renderer)
    }    
    exit()
}

exit :: proc() {
    tex.destroy(&colors_texture)
    sdl.DestroyRenderer(renderer)
    sdl.DestroyWindow(window)
    sdl.Quit()
}

init :: proc() -> bool {
    if !sdl.Init(sdl.INIT_VIDEO) {
        fmt.eprintfln("SDL could not init! SDL_Error: %s", sdl.GetError())
        return false
    }
    if !sdl.CreateWindowAndRenderer(
        "SDL3 Tutorial: Color Modulation and Blending",
        WIDTH, HEIGHT, {},
        &window, &renderer
    ) {
        fmt.eprintfln("Could not create window. SDL_Error: %s", sdl.GetError())
        return false
    }
    return true
}

load_media :: proc() -> bool {
    if !tex.from_img(renderer, &colors_texture, "colors.png") {
        fmt.eprintln("Failed to load colors image.")
        return false
    }
    return true
}