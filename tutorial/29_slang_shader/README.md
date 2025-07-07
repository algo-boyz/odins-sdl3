An example of [SDL3's new GPU API](https://wiki.libsdl.org/SDL3/CategoryGPU) being
used with [Slang](https://shader-slang.org/slang/user-guide/introduction.html) in
the [Odin programming language](https://odin-lang.org/), supporting hot-reloading
of the shader. This example is a modification of existing API examples:

> - [DragosPopse/odin-slang:example/example.odin](https://github.com/DragosPopse/odin-slang/blob/master/example/example.odin)
> - [foureyez/odin-sdl3-examples:examples/basic_triangle.odin](https://github.com/foureyez/odin-sdl3-examples/blob/main/examples/basic_triangle.odin)

The SDL3 GPU API is initialized by first telling it which shader formats
you are able to provide it. Based on that list, SDL then selects the
best available underlying API (e.g., D3D12, Metal, etc).

We pass along SPIR-V (Vulkan), DXIL (D3D12), and MSL (Metal) as the
supported formats. On Windows, this causes SDL GPU to select Vulkan as
the rendering API. If instead we only passed in DXIL and MSL then on
Windows, SDL GPU would select D3D12 instead.

The example has been tested on Windows with Vulkan and D3D12, and on
macOS with Metal.

On Windows, copy `odin-slang/slang/lib/slang.dll` to this example's root
folder.

On macOS, a newer version of libslang.dylib than included in `odin-slang`
is needed for the example to run properly. (Metal support is still
experimental for Slang.)