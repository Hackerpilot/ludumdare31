module entity;

import derelict.sdl2.sdl;

struct Universe
{
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

private:

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
