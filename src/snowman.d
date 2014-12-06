module snowman;

import derelict.sdl2.sdl;
import entity;
import map;

class Snowman : Entity
{
	this(SDL_Texture* texture, Universe* universe, int x, int y)
	{
		this.texture = texture;
		component.universe = universe;

		component.collisionBox.x = x;
		component.collisionBox.y = y;
		component.collisionBox.h = 64;
		component.collisionBox.w = 32;

		component.hurtBoxes[0].x = 22 - 16;
		component.hurtBoxes[0].y = 5;
		component.hurtBoxes[0].w = 22;
		component.hurtBoxes[0].h = 29;

		component.hurtBoxes[1].x = 0;
		component.hurtBoxes[1].y = 34;
		component.hurtBoxes[1].w = 33;
		component.hurtBoxes[1].h = 30;

		component.hitBoxes[0].w = 10;
		component.hitBoxes[0].h = 30;
		component.hitBoxes[0].x = 30;
		component.hitBoxes[0].y = 0;

		component.hitBoxes[1].w = 10;
		component.hitBoxes[1].h = 30;
		component.hitBoxes[1].x = -10;
		component.hitBoxes[1].y = 0;

		component.xVel = 0;
		component.yVel = 0;

		component.hurtMask = 0b00000011;

		component.health = 20;
	}

	override void update()
	{
		import std.algorithm : max, min;
		import std.math : abs;
		import std.random : uniform;

		if (component.screenKill())
		{
			dead = true;
			return;
		}

		++decisionTimer;
		if (decisionTimer == 50)
		{
			bool goLeft = (uniform(0, 100) & 1) == 0;
			if (goLeft)
			{
				component.xVel = -2.0;
				component.facing = Facing.left;
			}
			else
			{
				component.xVel = 2.0;
				component.facing = Facing.right;
			}
			decisionTimer = 0;
		}

		frameTimer = frameTimer == 0 ? CYCLE_FRAMES : frameTimer - 1;

		component.yVel += component.universe.gravity;
		component.yVel = min(max(-15, component.yVel), 15);
		component.xVel = min(max(-10, component.xVel), 10);
		component.collisionBox.y += component.yVel;
		component.collisionBox.x += component.xVel;

		checkCollision(component.collisionBox, component.universe.map, component.xVel, component.yVel);

		component.hitMask = component.facing == Facing.left ? 2 : 1;

		component.handleInjury();
		if (component.health == 0)
		{

			if (!dead)
			{
//				import std.stdio:writeln;
//				writeln("Snowman died");
				dead = true;
			}
		}
	}

	override int checkHitBoxes(ref const SDL_Rect[8] hurtBoxes, ubyte mask)
	{
		return component.checkHitBoxes(hurtBoxes, mask);
	}

	override void draw(SDL_Renderer* renderer)
	{
		SDL_Rect src;
		src.x = (frameTimer > (CYCLE_FRAMES / 2)) * 64;
		src.y = (component.facing != Facing.right) * 64;
		src.w = 64;
		src.h = 64;

		SDL_Rect dst;
		dst.w = 64;
		dst.h = 64;
		dst.x = component.collisionBox.x - 16;
		dst.y = component.collisionBox.y;

		SDL_RenderCopy(renderer, texture, &src, &dst);
//		component.draw(renderer);
	}

	enum CYCLE_FRAMES = 20;

	int frameTimer;
	int decisionTimer = 0;
	CombatComponent component;
	SDL_Texture* texture;
}

class SnowmanSpawner : Entity
{
	this(SDL_Texture* texture, Universe* universe)
	{
		this.texture = texture;
		this.universe = universe;
	}

	override void update()
	{
		updateCounter++;
		if (updateCounter == updateFrequency)
		{
			updateFrequency = updateFrequency > 10 ? updateFrequency - 1 : updateFrequency;
			updateCounter = 0;
			spawnSnowman();
		}
	}

	void spawnSnowman()
	{
		import std.random : uniform;
		auto s = new Snowman(texture, universe, uniform(64, 800 - 64), 40);
		universe.addEntity(s);
	}

	long updateFrequency = 100;
	long updateCounter;
	Universe* universe;
	SDL_Texture* texture;
}
