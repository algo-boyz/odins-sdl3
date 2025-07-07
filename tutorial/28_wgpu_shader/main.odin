package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:time"
import r "renderer"
import "vendor:sdl3"
import "vendor:wgpu"
import "vendor:wgpu/sdl3glue"


main :: proc() {
	flags := sdl3.InitFlags{.VIDEO, .EVENTS}
	sdlRes := sdl3.Init(flags)
	if !sdlRes {
		fmt.eprintln("SDL failed to init")
		os.exit(1)
	}
	fmt.println("SDL initialized successfully")

	rndr, ok := r.init_renderer()
	if !ok {
		panic("SDL Renderer failed to init")
	}
	res := r.command_queue(&rndr)
	fmt.printfln("Result: %v", res)

	event: sdl3.Event
	running := true
	now := sdl3.GetPerformanceCounter()
	last: u64
	dt: f32
	shader := r.init_shader(rndr)
	pipeline := r.init_pipeline(rndr, shader)

	for running {
		last = now
		now = sdl3.GetPerformanceCounter()
		dt = f32((now - last) * 1000) / f32(sdl3.GetPerformanceFrequency())

		for sdl3.PollEvent(&event) {
			if event.type == .QUIT {
				running = false
			} else if event.type == .KEY_UP {
				if event.key.scancode == .B {
					fmt.println("Testing buffers...")
					r.test_buffers(rndr)
				} else {
					fmt.printfln("Key: %v", event.key)
				}
			}
		}
		r.start_frame(&rndr)
		r.clear_screen(rndr)
		r.render_pipeline(rndr, pipeline)
		r.end_frame(&rndr)
	}
	r.deinit_pipeline(pipeline)
	r.deinit_shader(shader)
	r.deinit_renderer(rndr)
	sdl3.Quit()
	os.exit(0)
}
