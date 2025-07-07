package renderer

import "vendor:wgpu"

Shader :: struct {
	shader: wgpu.ShaderModule,
}

triangle_shader := #load("triangle.wgsl", string)

init_shader :: proc(renderer: Renderer) -> Shader {
	code_desc := wgpu.ShaderSourceWGSL {
		chain = {next = nil, sType = .ShaderSourceWGSL},
		code = triangle_shader,
	}
	shader_desc := wgpu.ShaderModuleDescriptor {
		label       = "My Shader",
		nextInChain = &code_desc,
	}
	shader := wgpu.DeviceCreateShaderModule(renderer.device, &shader_desc)
	return {shader}
}

init_pipeline :: proc(renderer: Renderer, shader: Shader) -> wgpu.RenderPipeline {
	vertex_state := wgpu.VertexState {
		module        = shader.shader,
		entryPoint    = "vs_main",
		constantCount = 0,
		constants     = nil,
		bufferCount   = 0,
		buffers       = nil,
	}
	primitive_state := wgpu.PrimitiveState {
		topology         = .TriangleList,
		stripIndexFormat = .Undefined,
		frontFace        = .CCW,
		cullMode         = .None,
	}
	blend_state := wgpu.BlendState {
		color = {srcFactor = .SrcAlpha, dstFactor = .OneMinusSrcAlpha, operation = .Add},
		alpha = {srcFactor = .Zero, dstFactor = .One, operation = .Add},
	}
	color_target_state := wgpu.ColorTargetState {
		format    = .BGRA8Unorm,
		blend     = &blend_state,
		writeMask = {.Alpha, .Blue, .Green, .Red},
	}
	fragment_state := wgpu.FragmentState {
		module        = shader.shader,
		entryPoint    = "fs_main",
		constantCount = 0,
		constants     = nil,
		targetCount   = 1,
		targets       = &color_target_state,
	}
	depth_stencil_state := wgpu.DepthStencilState {
		format = .Stencil8,
	}
	multi_sample_state := wgpu.MultisampleState {
		count                  = 1,
		mask                   = 0xFFFFFFFF,
		alphaToCoverageEnabled = false,
	}
	pipeline_desc := wgpu.RenderPipelineDescriptor {
		label        = "new Pipeline",
		nextInChain  = nil,
		layout       = nil,
		vertex       = vertex_state,
		primitive    = primitive_state,
		depthStencil = nil,
		multisample  = multi_sample_state,
		fragment     = &fragment_state,
	}
	pipline := wgpu.DeviceCreateRenderPipeline(renderer.device, &pipeline_desc)
	return pipline
}

deinit_shader :: proc(shader: Shader) {
	wgpu.ShaderModuleRelease(shader.shader)
}

deinit_pipeline :: proc(pipeline: wgpu.RenderPipeline) {
	wgpu.RenderPipelineRelease(pipeline)
}
