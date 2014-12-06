module healthgage;

import derelict.sdl2.sdl;
import entity;
import player;

class HealthGage : Entity
{
	this(Player player)
	{
		this.player = player;
	}

	override void draw(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
		SDL_SetRenderDrawColor(renderer, 255, 0, 0, 128);
		SDL_Rect rect;

		// Health Bar
		rect.x = 10;
		rect.y = 10;
		rect.w = player.component.health;
		rect.h = 10;
		SDL_RenderFillRect(renderer, &rect);

		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);

		// top border
		rect.x = 8;
		rect.y = 8;
		rect.w = 204;
		rect.h = 2;
		SDL_RenderFillRect(renderer, &rect);

		// bottom border
		rect.y = 20;
		SDL_RenderFillRect(renderer, &rect);

		// left border
		rect.y = 8;
		rect.w = 2;
		rect.h = 12;
		SDL_RenderFillRect(renderer, &rect);

		// right border
		rect.x = 210;
		SDL_RenderFillRect(renderer, &rect);
	}

	Player player;
}
