module timer;

import derelict.sdl2.sdl;
import entity;

class Timer : Entity
{
	this(SDL_Texture* texture)
	{
		startTime = SDL_GetTicks();
		this.texture = texture;
	}

	override void draw(SDL_Renderer* renderer)
	{
		immutable uint currentTime = SDL_GetTicks();
		immutable uint elapsed = currentTime - startTime;
		immutable uint seconds = elapsed / 1_000;
		immutable uint minutes = seconds / 60;
		immutable uint minutesOnes = minutes % 10;
		immutable uint secondsTens = seconds % 60 / 10;
		immutable uint secondsOnes = seconds % 10;

		SDL_Rect src;
		src.w = 64;
		src.h = 64;
		src.x = 0;

		SDL_Rect dst;
		dst.y = 30;
		dst.w = 64;
		dst.h = 64;

		SDL_Rect colon;
		SDL_SetRenderDrawColor(renderer, 36, 38, 33, 255);
		colon.w = 10;
		colon.h = 10;
		colon.x = 48;
		colon.y = 50;
		SDL_RenderFillRect(renderer, &colon);
		colon.y += 20;
		SDL_RenderFillRect(renderer, &colon);

		src.y = minutesOnes * 64;
		dst.x = -10;
		SDL_RenderCopy(renderer, texture, &src, &dst);
		src.y = secondsTens * 64;
		dst.x = 50;
		SDL_RenderCopy(renderer, texture, &src, &dst);
		src.y = secondsOnes * 64;
		dst.x = 90;
		SDL_RenderCopy(renderer, texture, &src, &dst);
	}

	SDL_Texture* texture;
	uint startTime;
}
