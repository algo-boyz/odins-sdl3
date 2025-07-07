package sdl3slang_example

import "core:log"
import "core:os"
import "core:slice"
import "core:time"

import sdl "vendor:sdl3"
import sp  "slang"

DEFAULT_SCREEN_RES_X :: 1280
DEFAULT_SCREEN_RES_Y :: 720

SHADER_FILE_PATH :: "triangle.slang"

SHADER_ENTRY_NAME_VERTEX   :: "vertexmain"
SHADER_ENTRY_NAME_FRAGMENT :: "fragmentmain"

Application :: struct {
	window:  ^sdl.Window,
	device:  ^sdl.GPUDevice,
	gfxPipe: ^sdl.GPUGraphicsPipeline,

	shaderSession: ^sp.IGlobalSession,
	lastWriteTime: os.File_Time,

	isRunning: bool,
	frameId:   u64,
}

g_app: Application

main :: proc() {
	context.logger = log.create_console_logger()

	defer fini_application()
	if !init_application() {
		return
	}

	run_application()
}

run_application :: proc() {
	for loop_application() {}
}

loop_application :: proc() -> bool {
	event: sdl.Event
	for g_app.isRunning && sdl.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			g_app.isRunning = false

		case .KEY_DOWN:
			if event.key.scancode == .ESCAPE {
				g_app.isRunning = false
			}
		}
	}

	if !g_app.isRunning {
		return false
	}

	_ = reload_shader_pipelines_if_necessary()
	g_app.frameId += 1

	cmdBuf := sdl.AcquireGPUCommandBuffer( g_app.device )
	if cmdBuf == nil {
		log.errorf( "Failed to acquire command buffer. Error: %s", sdl.GetError() )
		g_app.isRunning = false
		return false
	}

	backbuffer: ^sdl.GPUTexture
	if !sdl.WaitAndAcquireGPUSwapchainTexture( cmdBuf, g_app.window, &backbuffer, nil, nil ) {
		log.errorf( "Failed to acquire backbuffer. Error: %s", sdl.GetError() )
		g_app.isRunning = false
		return false
	}

	colorTarget := sdl.GPUColorTargetInfo {
		texture     = backbuffer,
		clear_color = sdl.FColor { 0.1, 0.3, 0.5, 1.0 },
		load_op     = .CLEAR,
		store_op    = .STORE,
	}

	renderPass := sdl.BeginGPURenderPass( cmdBuf, &colorTarget, 1, nil )
	{
		//===================//
		// Render stuff here //
		//===================//

		if g_app.gfxPipe != nil {
			sdl.BindGPUGraphicsPipeline( renderPass, g_app.gfxPipe )
			// Draw one triangle; triangle.slang synthesizes the data, so we
			// don't need the vertex buffer, index buffer, or other details.
			sdl.DrawGPUPrimitives( renderPass, 3, 1, 0, 0 )
		}
	}
	sdl.EndGPURenderPass( renderPass )
	renderPass = nil

	if !sdl.SubmitGPUCommandBuffer( cmdBuf ) {
		log.errorf( "Failed to submit command queue: %s", sdl.GetError() )
		g_app.isRunning = false
		return false
	}

	if g_app.frameId == 1 {
		sdl.ShowWindow( g_app.window )
	}

	return true
}

init_application :: proc() -> bool {
	if !sdl.Init( {.VIDEO} ) {
		log.errorf( "Unable to initialize SDL3. Error: %s", sdl.GetError() )
		return false
	}

	g_app.device = sdl.CreateGPUDevice( {.SPIRV, .DXIL, .MSL}, false, nil )
	if g_app.device == nil {
		log.errorf( "Unable to initialize GPU. Error: %s", sdl.GetError() )
		return false
	}

	screenRes := [2]i32 { DEFAULT_SCREEN_RES_X, DEFAULT_SCREEN_RES_Y }
	g_app.window = sdl.CreateWindow( "SDL3 + Slang Demo", screenRes.x, screenRes.y, {.RESIZABLE,.HIDDEN} )
	if g_app.window == nil {
		log.errorf( "Unable to initialize window. Error: %s", sdl.GetError() )
		return false
	}

	if !sdl.ClaimWindowForGPUDevice( g_app.device, g_app.window ) {
		log.errorf( "Unable tie window to GPU. Error: %s", sdl.GetError() )
		return false
	}

	log.infof( "GPU driver: %s", sdl.GetGPUDeviceDriver(g_app.device) )
	log.infof( "GPU shader formats: %v", sdl.GetGPUShaderFormats(g_app.device) )

	if sp.createGlobalSession( sp.API_VERSION, &g_app.shaderSession ) != sp.OK {
		log.errorf( "Failed to create shader-slang global session." )
		return false
	}

	g_app.isRunning = true
	return true
}
fini_application :: proc() {
	if g_app.shaderSession != nil {
		g_app.shaderSession->release()
		g_app.shaderSession = nil
	}

	if g_app.window != nil {
		sdl.DestroyWindow( g_app.window )
		g_app.window = nil
	}

	if g_app.gfxPipe != nil {
		sdl.ReleaseGPUGraphicsPipeline( g_app.device, g_app.gfxPipe )
		g_app.gfxPipe = nil
	}

	if g_app.device != nil {
		sdl.DestroyGPUDevice( g_app.device )
		g_app.device = nil
	}
}

map_slang_result_to_string :: #force_inline proc(#any_int result: int) -> string {
	switch sp.Result(result) {
	case sp.FAIL():
		return "FAIL"
	case sp.E_NOT_IMPLEMENTED():
		return "E_NOT_IMPLEMENTED"
	case sp.E_NO_INTERFACE():
		return "E_NO_INTERFACE"
	case sp.E_ABORT():
		return "E_ABORT"
	case sp.E_INVALID_HANDLE():
		return "E_INVALID_HANDLE"
	case sp.E_INVALID_ARG():
		return "E_INVALID_ARG"
	case sp.E_OUT_OF_MEMORY():
		return "E_OUT_OF_MEMORY"
	case sp.E_BUFFER_TOO_SMALL():
		return "E_BUFFER_TOO_SMALL"
	case sp.E_UNINITIALIZED():
		return "E_UNINITIALIZED"
	case sp.E_PENDING():
		return "E_PENDING"
	case sp.E_CANNOT_OPEN():
		return "E_CANNOT_OPEN"
	case sp.E_NOT_FOUND():
		return "E_NOT_FOUND"
	case sp.E_INTERNAL_FAIL():
		return "E_INTERNAL_FAIL"
	case sp.E_NOT_AVAILABLE():
		return "E_NOT_AVAILABLE"
	case sp.E_TIME_OUT():
		return "E_TIME_OUT"
	case:
		return "Unknown error"
	}
}

slang_check :: proc(#any_int result: int, loc := #caller_location) {
	result := sp.Result(result)
	if sp.FAILED(result) {
		code     := sp.GET_RESULT_CODE(result)
		facility := sp.GET_RESULT_FACILITY(result)
		estr     := map_slang_result_to_string(result)

		log.panicf("Failed with error: %v (%v) Facility: %v", estr, code, facility, location=loc)
	}
}

diagnostics_check :: #force_inline proc(diagnostics: ^sp.IBlob, loc := #caller_location) {
	if diagnostics != nil {
		buffer := slice.bytes_from_ptr(
			diagnostics->getBufferPointer(),
			int(diagnostics->getBufferSize()),
		)

		log.panicf("Diagnostics failed <<<<\n%s>>>>\n", string(buffer), location=loc)
	}
}

get_preferred_shader_format :: proc() -> (sdlFormat: sdl.GPUShaderFormatFlag, target: sp.CompileTarget) {
	sdlFormats := sdl.GetGPUShaderFormats( g_app.device )

	if .SPIRV in sdlFormats {
		sdlFormat = .SPIRV
		target    = .SPIRV
		return
	}

	if .DXIL in sdlFormats {
		sdlFormat = .DXIL
		target    = .DXIL
		return
	}

	if .DXBC in sdlFormats {
		sdlFormat = .DXBC
		target    = .DXBC
		return
	}

	if .METALLIB in sdlFormats {
		sdlFormat = .METALLIB
		target    = .METAL_LIB
		return
	}

	if .MSL in sdlFormats {
		sdlFormat = .MSL
		target    = .METAL
		return
	}
	log.panicf("No conversion for SDL shader format: %v", sdlFormats)
}

reload_shader_pipelines_if_necessary :: proc() -> bool {
	{
		lastWriteTime, err := os.last_write_time_by_name( SHADER_FILE_PATH )
		if ( err != nil || g_app.lastWriteTime == lastWriteTime ) && g_app.frameId != 0 {
			return true
		}

		g_app.lastWriteTime = lastWriteTime
	}

	startCompileTime := time.tick_now()

	sdlFormat, slangTarget := get_preferred_shader_format()

	targetDesc := sp.TargetDesc {
		structureSize = size_of(sp.TargetDesc),
		format        = slangTarget,
		flags         = slangTarget == .SPIRV ? {.GENERATE_SPIRV_DIRECTLY} : {},
		profile       = g_app.shaderSession->findProfile("sm_6_0"),
	}

	compilerOptions := [?]sp.CompilerOptionEntry {
		{ name = .VulkanUseEntryPointName, value = {intValue0=1} },
	}
	sessionDesc := sp.SessionDesc {
		structureSize            = size_of(sp.SessionDesc),
		targets                  = &targetDesc,
		targetCount              = 1,
		compilerOptionEntries    = raw_data(&compilerOptions),
		compilerOptionEntryCount = len(compilerOptions),
	}

	session: ^sp.ISession
	slang_check( g_app.shaderSession->createSession( sessionDesc, &session ) )
	defer session->release()

	diagnostics: ^sp.IBlob
	module: ^sp.IModule

	if module = session->loadModule( SHADER_FILE_PATH, &diagnostics ); module == nil {
		diagnostics_check(diagnostics)

		log.errorf( "Shader compile error!" )
		return false
	}
	defer module->release()

	result: sp.Result

	vertexEntry: ^sp.IEntryPoint
	result = module->findAndCheckEntryPoint( SHADER_ENTRY_NAME_VERTEX, .VERTEX, &vertexEntry, &diagnostics )
	diagnostics_check(diagnostics)
	slang_check( result )

	fragmentEntry: ^sp.IEntryPoint
	result = module->findAndCheckEntryPoint( SHADER_ENTRY_NAME_FRAGMENT, .FRAGMENT, &fragmentEntry, &diagnostics )
	diagnostics_check(diagnostics)
	slang_check( result )

	if vertexEntry == nil {
		log.errorf( "Expected '%s' entry point in shader", SHADER_ENTRY_NAME_VERTEX )
		return false
	}

	if fragmentEntry == nil {
		log.errorf( "Expected '%s' entry point in shader", SHADER_ENTRY_NAME_FRAGMENT )
		return false
	}

	Stage :: struct {
		entryname: cstring,
		stage: sdl.GPUShaderStage,
		entryptr: ^sp.IEntryPoint,
	}
	stages := [2]Stage {
		{ entryname=SHADER_ENTRY_NAME_VERTEX,   stage=.VERTEX,   entryptr=vertexEntry   },
		{ entryname=SHADER_ENTRY_NAME_FRAGMENT, stage=.FRAGMENT, entryptr=fragmentEntry },
	}

	shaders: [2]^sdl.GPUShader
	for stage, i in stages {
		components := [2]^sp.IComponentType { module, stage.entryptr }

		linkedProgram: ^sp.IComponentType
		result = session->createCompositeComponentType(
			raw_data(&components),
			len(components),
			&linkedProgram,
			&diagnostics,
		)
		diagnostics_check( diagnostics )
		slang_check( result )
		assert( linkedProgram != nil )

		targetCode: ^sp.IBlob
		result = linkedProgram->getTargetCode( 0, &targetCode, &diagnostics )
		diagnostics_check( diagnostics )
		slang_check( result )

		codeSize   := targetCode->getBufferSize()
		sourceCode := slice.bytes_from_ptr( targetCode->getBufferPointer(), auto_cast codeSize )

		shaderCreateInfo := sdl.GPUShaderCreateInfo {
			code                 = raw_data(sourceCode),
			code_size            = len(sourceCode),
			entrypoint           = stage.entryname,
			format               = {sdlFormat},
			stage                = stage.stage,
			num_samplers         = 0,
			num_uniform_buffers  = 0,
			num_storage_buffers  = 0,
			num_storage_textures = 0,
		}

		shaders[i] = sdl.CreateGPUShader( g_app.device, shaderCreateInfo )
		if shaders[i] == nil {
			log.errorf( "Failed to create GPU shader. Error: %s", sdl.GetError() )
			return false
		}
	}

	colorTargetDesc := [1]sdl.GPUColorTargetDescription {
		{ format = sdl.GetGPUSwapchainTextureFormat( g_app.device, g_app.window ) },
	}

	pipelineCreateInfo := sdl.GPUGraphicsPipelineCreateInfo {
		target_info = sdl.GPUGraphicsPipelineTargetInfo {
			num_color_targets         = u32(len(colorTargetDesc)),
			color_target_descriptions = raw_data(&colorTargetDesc),
		},

		primitive_type  = .TRIANGLELIST,
		vertex_shader   = shaders[0],
		fragment_shader = shaders[1],

		rasterizer_state = sdl.GPURasterizerState {
			fill_mode = .FILL,
		},
	}

	newGfxPipe := sdl.CreateGPUGraphicsPipeline( g_app.device, pipelineCreateInfo )
	if newGfxPipe == nil {
		log.errorf( "Failed to create graphics pipeline. Error: %s", sdl.GetError() )
		return false
	}

	if g_app.gfxPipe != nil {
		sdl.ReleaseGPUGraphicsPipeline( g_app.device, g_app.gfxPipe )
	}
	g_app.gfxPipe = newGfxPipe

	durationMilli := time.tick_since(startCompileTime)
	log.infof( "Loaded shader in %v", durationMilli )

	return true
}