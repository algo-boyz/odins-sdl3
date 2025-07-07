[Lazy Foo](https://lazyfoo.net/tutorials/SDL/13_alpha_blending/index.php)

 - init
   - Create the window
   - Create the renderer
   - Set the render draw colour
   - init sdl_image
 - Load the media
    - Load the textures
      - Set the color key
    - Set the blend mode on the fade in texture
 - Loop until a quit command is received
    - Set the rendering colour (clear to colour)
    - Clear the renderer
    - Change alpha blending based on user input
    - Render the textures
    - Update the screen
 - Cleanup and quit

> Written with [StackEdit](https://stackedit.io/).