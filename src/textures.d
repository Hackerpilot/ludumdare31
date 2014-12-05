import derelict.sdl2.sdl;
import derelict.sdl2.image;

SDL_Texture* loadTexture(SDL_Renderer* renderer, string fileName)
{
	import std.string : toStringz;
	import std.exception : enforce;
	SDL_Surface* surface = IMG_Load(toStringz(fileName));
	SDL_Texture* texture = enforce(SDL_CreateTextureFromSurface(renderer, surface));
	SDL_FreeSurface(surface);
	return texture;
}
