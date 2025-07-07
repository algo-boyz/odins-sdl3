package timer

import sdl "vendor:sdl3"

Timer :: struct {
	start_ticks, paused_ticks: u64,
	started, paused:           bool,
}

create :: proc() ->Timer {
	return Timer{start_ticks = 0, paused_ticks = 0, started = false, paused = false}
}

start :: proc(timer: ^Timer) {
	timer.started = true
	timer.paused = false
	timer.start_ticks = sdl.GetTicks()
	timer.paused_ticks = 0
}

stop :: proc(timer: ^Timer) {
	timer.started = false
	timer.paused = false
	timer.start_ticks = 0
	timer.paused_ticks = 0
}

pause :: proc(timer: ^Timer) {
	if timer.started && !timer.paused {
		timer.paused = true
		timer.paused_ticks = sdl.GetTicks() - timer.start_ticks
		timer.start_ticks = 0
	}
}

unpause :: proc(timer: ^Timer) {
	if timer.started && timer.paused {
		timer.paused = false
		timer.start_ticks = sdl.GetTicks() - timer.paused_ticks
		timer.paused_ticks = 0
	}
}

is_started :: proc(timer: ^Timer) -> bool {
	return timer.started
}

is_paused :: proc(timer: ^Timer) -> bool {
	return timer.started && timer.paused
}

tick :: proc(timer: ^Timer) -> u64 {
	if !timer.started {
		return 0
	}
	return timer.paused_ticks if timer.paused else sdl.GetTicks() - timer.start_ticks
}

cap :: proc(timer: ^Timer, fps: u32) -> u64 {
	if !timer.started {
		return 0
	}
	ns_per_frame: u64 = 1000000000 / u64(fps)
	frame_ns := tick(timer)
	if frame_ns < ns_per_frame {
		sdl.DelayNS(ns_per_frame - frame_ns)
	}
	return frame_ns
}