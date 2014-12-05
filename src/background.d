module background;

import entity;
import derelict.sdl2.sdl;

class Background : Entity
{
	this(SDL_Texture* texture)
	{
		this.texture = texture;
	}

	override void draw(SDL_Renderer* renderer)
	{
		SDL_RenderCopy(renderer, texture, null, null);
	}

private:
	SDL_Texture* texture;
}
