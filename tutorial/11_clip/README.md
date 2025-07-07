[Lazy Foo](https://lazyfoo.net/tutorials/SDL/11_clip_rendering_and_sprite_sheets/index.php)

 - init
   - Create the window
   - Create the renderer
   - Set the render draw colour
   - init sdl_image
 - Load the media
    - Load the sprite sheet
      - Set the color key
    - Populate sdl.Rect structs for the 4 sprites on the spritesheet
 - Loop until a quit command is received
    - Set the rendering colour (clear to colour)
    - Clear the renderer
    - Render the sprites
    - Update the screen
 - Cleanup and quit

> Written with [StackEdit](https://stackedit.io/).