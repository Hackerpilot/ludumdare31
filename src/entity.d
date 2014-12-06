module entity;

import derelict.sdl2.sdl;
import map;

enum MovementState
{
	running,
	standing,
	jumping
}

enum MovementTransition
{
	start,
	stop,
	jump,
	land
}

enum Facing
{
	left,
	right
}

struct Universe
{
	this(float g)
	{
		this._gravity = g;
	}

	/// Returns: damage taken
	int checkHitBoxes(ref SDL_Rect[8] hurtBoxes, ubyte mask)
	{
		int damage = 0;
		foreach (entity; entities)
			damage += entity.checkHitBoxes(hurtBoxes, mask);
		return damage;
	}

	Entity addEntity(Entity entity)
	{
		entities.insert(entity);
		return entity;
	}

	void removeEntity(Entity entity)
	{
		entities.remove(entity);
	}

	void update()
	{
		Entity[] toRemove;
		foreach (entity; entities)
		{
			entity.update();
			if (entity.dead)
				toRemove ~= entity;
		}
		foreach (e; toRemove)
			removeEntity(e);
	}

	void draw(SDL_Renderer* renderer)
	{
		foreach (entity; entities)
			entity.draw(renderer);
	}

	void handleInput(const(SDL_Event*) event)
	{
		foreach (entity; entities)
			entity.handleInput(event);
	}

	float gravity() const @property { return _gravity; }

	TileMap map;

private:

	import containers.unrolledlist : UnrolledList;

	float _gravity;
	UnrolledList!Entity entities;
}

abstract class Entity
{
public:
	void update() {}
	void draw(SDL_Renderer*) {}
	void handleInput(const(SDL_Event*)) {}
	int checkHitBoxes(ref const SDL_Rect[8], ubyte) { return 0; }
	bool dead;
}

struct CombatComponent
{
	bool screenKill()
	{
		return collisionBox.x <= 0
			|| collisionBox.y <= 0
			|| collisionBox.x + collisionBox.w >= 780
			|| collisionBox.y + collisionBox.h >= 580;
	}

	void draw(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
		// Collision box in blue
		SDL_SetRenderDrawColor(renderer, 0, 0, 255, 128);
		SDL_RenderFillRect(renderer, &collisionBox);

		// Hit boxes in red
		SDL_SetRenderDrawColor(renderer, 255, 0, 0, 128);
		foreach (i, ref box; hitBoxes)
		{
			if (1 << i & hitMask)
			{
				SDL_Rect r = box;
				r.x += collisionBox.x;
				r.y += collisionBox.y;
				SDL_RenderFillRect(renderer, &r);
			}
		}

		// Hurt boxes in green
		SDL_SetRenderDrawColor(renderer, 0, 255, 0, 128);
		foreach (i, ref box; hurtBoxes)
		{
			if (1 << i & hurtMask)
			{
				SDL_Rect r = box;
				r.x += collisionBox.x;
				r.y += collisionBox.y;
				SDL_RenderFillRect(renderer, &r);
			}
		}
	}

	int checkHitBoxes(ref const SDL_Rect[8] hurtBoxes, ubyte mask)
	{
		bool tookDamage;
		foreach (size_t i; 0 .. hurtBoxes.length)
		{
			if ((mask & (1 << i)) == 0)
				continue;
			foreach (size_t j; 0 .. hitBoxes.length)
			{
				if ((hitMask & (1 << j)) == 0)
					continue;
				SDL_Rect r = hitBoxes[j];
				r.x += collisionBox.x;
				r.y += collisionBox.y;
				if (SDL_HasIntersection(&hurtBoxes[i], &r))
					tookDamage = true;
			}
		}
		return tookDamage ? 10 : 0;
	}

	void handleInjury()
	{
		if (hurtLag > 0)
		{
			hurtLag--;
			return;
		}
		SDL_Rect[8] r;
		r[] = hurtBoxes[];
		foreach (ref b; r)
		{
			b.x += collisionBox.x;
			b.y += collisionBox.y;
		}
		int damageTaken = universe.checkHitBoxes(r, hurtMask);
		if (damageTaken > 0)
		{
//			import std.stdio:writeln;
//			writeln("Took ", damageTaken, " damage");
			hurtLag = 10;
			health -= damageTaken;
		}
	}

	uint hitLag;
	uint hurtLag;
	SDL_Rect[8] hitBoxes;
	SDL_Rect[8] hurtBoxes;
	ubyte hitMask;
	ubyte hurtMask;
	int health;
	SDL_Rect collisionBox;
	Universe* universe;
	float xVel;
	float yVel;
	Facing facing;
}
