import std.stdio;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

void main()
{
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2ttf.load();

	SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER);
	scope(exit) SDL_Quit();

	SDL_Renderer* renderer;
	SDL_Window* window;

	SDL_CreateWindowAndRenderer(640, 480, 0, &window, &renderer);
	SDL_RenderClear(renderer);
	SDL_RenderPresent(renderer);
	SDL_Delay(2_000);

	writeln("Hello World");
}
