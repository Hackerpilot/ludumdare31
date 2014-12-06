import std.stdio;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

import textures;
import entity;
import particles;
import background;
import map;
import player;
import snowman;
import healthgage;
import timer;

void main()
{
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictSDL2Mixer.load();
//    DerelictSDL2ttf.load();

	SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER);
	scope (exit) SDL_Quit();
	IMG_Init(IMG_INIT_PNG);
	scope (exit) IMG_Quit();

	SDL_Renderer* renderer;
	SDL_Window* window;

	SDL_CreateWindowAndRenderer(800, 600, 0, &window, &renderer);

	Universe universe = Universe(0.75);

	SDL_Texture* texture = loadTexture(renderer, "images/background.png");
	scope (exit) SDL_DestroyTexture(texture);

	universe.addEntity(new Background(texture));
	createSnow(universe, renderer);

	TileMap map = loadTileMap("maps/map1.json", renderer);
	universe.addEntity(map);
	universe.map = map;

	SDL_Texture* snowmanTexture = loadTexture(renderer, "images/snowman.png");
	scope (exit) SDL_DestroyTexture(snowmanTexture);
	SnowmanSpawner spawner = new SnowmanSpawner(snowmanTexture, &universe);
	universe.addEntity(spawner);

	SDL_Texture* playerTexture = loadTexture(renderer, "images/player.png");
	scope (exit) SDL_DestroyTexture(playerTexture);
	Player player = new Player(playerTexture, &universe);
	universe.addEntity(player);
	player.component.collisionBox.x = 100;
	player.component.collisionBox.y = 300;

	HealthGage gage = new HealthGage(player);
	universe.addEntity(gage);

	SDL_Texture* timerTexture = loadTexture(renderer, "images/numbers.png");
	scope (exit) SDL_DestroyTexture(timerTexture);
	Timer timer = new Timer(timerTexture);
	universe.addEntity(timer);

	gameLoop(universe, renderer, player);
}

void gameLoop(ref Universe universe, SDL_Renderer* renderer, Player player)
{
	enum frameRate = 16;
	bool running = true;
	while (running)
	{
		running = handleInput(universe);
		if (!running)
			break;
		universe.update();

		if (player.dead)
			break;

		SDL_Delay(frameRate);
		handleGraphics(universe, renderer);
	}
}

bool handleInput(ref Universe universe)
{
	SDL_Event event;
	bool retVal = true;
	SDL_PollEvent(&event);
	switch (event.type)
	{
	case SDL_QUIT:
		writeln("Quitting");
		retVal = false;
		break;
	case SDL_KEYDOWN:
		if (event.key.keysym.sym == SDLK_ESCAPE)
			retVal = false;
		goto default;
	default:
		universe.handleInput(&event);
		break;
	}
	return retVal;
}

void handleGraphics(ref Universe universe, SDL_Renderer* renderer)
{
	SDL_RenderClear(renderer);
	universe.draw(renderer);
	SDL_RenderPresent(renderer);
}

void createSnow(ref Universe universe, SDL_Renderer* renderer)
{
	void createSnow(string fileName, int w, int h)
	{
		enum particleCount = 200;
		SDL_Texture* snow = loadTexture(renderer, fileName);
		ParticleSystem system = new ParticleSystem(200, snow, 170);
		system.origin.x = 400;
		system.origin.y = -20;
		system.sourceXRandom = 400;
		system.sourceYRandom = 20;
		system.xRandom = 0.75;
		system.yRandom = 0.75;
		system.xForce = 0;
		system.yForce = .02;
		system.initialXVelocity = 0;
		system.initialYVelocity = 0;
		system.dimensions.x = w;
		system.dimensions.y = h;
		system.alphaDecay = 1;
		universe.addEntity(system);
		foreach (i; 0 .. particleCount * 10)
			system.update();
	}
	createSnow("images/snow8x8.png", 8, 8);
	createSnow("images/snow16x16.png", 16, 16);
}
