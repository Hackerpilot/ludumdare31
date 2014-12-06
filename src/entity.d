module entity;

import derelict.sdl2.sdl;
import map;

struct Universe
{
	this(float g)
	{
		this._gravity = g;
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
		foreach (entity; entities)
			entity.update();
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

	float _gravity;

	import containers.unrolledlist : UnrolledList;

	UnrolledList!Entity entities;
}

abstract class Entity
{
public:
	void update() {}
	void draw(SDL_Renderer*) {}
	void handleInput(const(SDL_Event*)) {}
}
