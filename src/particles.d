module particles;

import std.random;
import derelict.sdl2.sdl;
import entity;


class ParticleSystem : Entity
{
	float initialXVelocity = 0;
	float initialYVelocity = 0;
	float xRandom = 0;
	float yRandom = 0;
	float xForce = 0;
	float yForce = 0;
	float sourceXRandom = 0;
	float sourceYRandom = 0;
	ubyte alphaDecay;
	ubyte initialAlpha;
	float[] xCoords;
	float[] yCoords;
	float[] xVels;
	float[] yVels;
	int[] alphas;
	SDL_Texture* texture;
	SDL_Point dimensions;
	SDL_Point origin;
	int initialized;

	this(int particleCount, SDL_Texture* texture, ubyte initialAlpha)
	{
		this.initialAlpha = initialAlpha;
		this.texture = texture;
		xCoords.length = particleCount;
		yCoords.length = particleCount;
		alphas.length = particleCount;
		xVels.length = particleCount;
		yVels.length = particleCount;
		foreach (i; 0 .. particleCount)
		{
			resetParticle(i);
			alphas[i] = 0;
		}
	}

	override void update()
	{
		if (initialized < xCoords.length - 1)
		{
			initialized++;
			alphas[initialized] = initialAlpha;
		}

		xVels[] += xForce;
		yVels[] += yForce;
		xCoords[0..initialized] += xVels[0..initialized];
		yCoords[0..initialized] += yVels[0..initialized];
		alphas[] -= alphaDecay;
		foreach (i; 0 .. cast(int) xCoords.length)
			if (alphas[i] <= 0)
				resetParticle(i);
	}

	override void draw(SDL_Renderer* renderer)
	{
		SDL_Rect dstRect;
		foreach (int i; 0 .. cast(int) xCoords.length)
		{
			dstRect.x = cast (int) xCoords[i];
			dstRect.y = cast (int) yCoords[i];
			dstRect.w = dimensions.x;
			dstRect.h = dimensions.y;
			SDL_SetTextureAlphaMod(texture, cast(ubyte) alphas[i]);
			SDL_RenderCopy(renderer, texture, null, &dstRect);
		}
	}

	void resetParticle(int index)
	{
		alphas[index] = initialAlpha;
		if (sourceXRandom != 0)
			xCoords[index] = origin.x + uniform(-sourceXRandom, sourceXRandom);
		else
			xCoords[index] = origin.x;

		if (sourceYRandom != 0)
			yCoords[index] = origin.y + uniform(-sourceYRandom, sourceYRandom);
		else
			yCoords[index] = origin.y;

		if (xRandom == 0)
			xVels[index] = initialXVelocity;
		else
			xVels[index] = initialXVelocity + uniform(-xRandom, xRandom);

		if (yRandom == 0)
			yVels[index] = initialYVelocity;
		else
			yVels[index] = initialYVelocity + uniform(-yRandom, yRandom);
	}
}
