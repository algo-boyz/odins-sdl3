package tex

import "core:fmt"
import "core:strings"

import sdl "vendor:sdl3"
import sdl_image "vendor:sdl3/image"

Texture :: struct {
    texture : ^sdl.Texture,
    h, w : i32,
}

destroy :: proc(texture : ^Texture) {
    if texture.texture != nil {
        sdl.DestroyTexture(texture.texture)
        texture.texture = nil
        texture.w = 0
        texture.h = 0
    }
}

from_img :: proc(renderer : ^sdl.Renderer, texture: ^Texture, file : string) -> bool {
    destroy(texture)
    img := sdl_image.Load(strings.clone_to_cstring(file))
    if img == nil {
        fmt.eprintfln("Unable to load images %s! sdl_image error: %s", file, sdl.GetError())
        return false
    }
    defer sdl.DestroySurface(img)
    if !sdl.SetSurfaceColorKey(img, true, sdl.MapSurfaceRGB(img, 0, 0xFF, 0xFF)) {
        fmt.eprintfln("Unable to set color key for %s! sdl error: %s", file, sdl.GetError())
        return false
    }
    surf := sdl.CreateTextureFromSurface(renderer, img)
    if surf == nil {
        fmt.eprintfln("Unable to create texture from %s! sdl error: %s", file, sdl.GetError())
        return false
    }
    texture.texture = surf
    texture.w = img.w
    texture.h = img.h
    return true
}

sdl_from_img :: proc(renderer : ^sdl.Renderer, path : string) -> (texture : ^sdl.Texture) {
    loaded_surface := sdl_image.Load(strings.clone_to_cstring(path))
    if loaded_surface == nil {
        fmt.eprintfln("Unable to load image %s! SDL_image error: %s", path, sdl.GetError())
        return nil
    }
    texture = sdl.CreateTextureFromSurface(renderer, loaded_surface)
    if texture == nil {
        fmt.eprintfln("Unable to create texture from %s! SDL error: %s", path, sdl.GetError())
        return nil
    }
    sdl.DestroySurface(loaded_surface)
    return texture
}

img_to_surface :: proc(path : string, format: sdl.PixelFormat) -> ^sdl.Surface {
    img := sdl_image.Load(strings.clone_to_cstring(path))
    if img == nil {
        fmt.eprintfln("Unable to load image %s! SDL error: %s", img, sdl.GetError())
        return img
    }
    surf := sdl.ConvertSurface(img, format)
    if surf == nil {
        fmt.eprintfln("Unable to optimise image %s! SDL error: %s", surf, sdl.GetError())
        return surf
    }
    sdl.DestroySurface(img)

    return surf
}

// renders the texture at original size to current rendering position 
// (typically 0,0 - the top-left corner of the screen or current viewport
render :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture) {
    sdl.RenderTexture(renderer, texture, nil, nil)
}

render_rect :: proc(renderer: ^sdl.Renderer, texture: ^Texture, x : f32, y : f32) {
    dst_rect := sdl.FRect {
        x = x,
        y = y,
        w = f32(texture.w),
        h = f32(texture.h)
    }
    sdl.RenderTexture(renderer, texture.texture, nil, &dst_rect)
}

render_scaled :: proc(renderer: ^sdl.Renderer, texture: ^Texture, x : i32, y : i32, clip : ^sdl.Rect) {
    dst_rect := sdl.FRect {
        x = f32(x),
        y = f32(y),
        w = f32(texture.w),
        h = f32(texture.h)
    }
    if clip != nil {
        dst_rect.w = f32(clip.w)
        dst_rect.h = f32(clip.h)
    }
    sdl.RenderTexture(renderer, texture.texture, nil, &dst_rect)
}

render_rotated :: proc(renderer: ^sdl.Renderer, texture: ^Texture, x : f32, y : f32, angle : f64, flip_mode : sdl.FlipMode) {
    // Define center from corner of image
    center := sdl.FPoint{
        f32(texture.w) / 2.0,
        f32(texture.h) / 2.0,
    }
    dst_rect := sdl.FRect {
        x = x,
        y = y,
        w = f32(texture.w),
        h = f32(texture.h)
    }
    sdl.RenderTextureRotated(renderer, texture.texture, nil, &dst_rect, angle, center, flip_mode)
}

set_alpha :: proc(texture : ^Texture, alpha : u8) {
    sdl.SetTextureAlphaMod(texture.texture, alpha)
}

set_blend_mode :: proc(texture : ^Texture, blend_mode : sdl.BlendMode) {
    sdl.SetTextureBlendMode(texture.texture, blend_mode)
}

set_colour :: proc(texture : ^Texture, r : u8, g : u8, b : u8) {
    sdl.SetTextureColorMod(texture.texture, r, g, b)
}