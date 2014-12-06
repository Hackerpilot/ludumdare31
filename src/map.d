module map;

import std.math;
import std.file;
import std.stdio;
import std.json;
import std.algorithm;
import std.string;
import derelict.sdl2.sdl;
import entity;
import textures;

immutable int TILE_SIZE = 32;
immutable int COLLISION_DEBUG_WIDTH = 8;
immutable byte BLOCK_TOP = 0b0001;
immutable byte BLOCK_RIGHT = 0b0010;
immutable byte BLOCK_BOTTOM = 0b0100;
immutable byte BLOCK_LEFT = 0b1000;

private struct TileLocation
{
	int x;
	int y;
	size_t index;
}

private struct Layer
{
public:

	void draw(SDL_Renderer* renderer, SDL_Texture*[] textures)
	{
		// TODO: Fix this
		int beginX = 0;
		int endX = cast (int) tiles.length;


		int beginY = 0;
		int endY = cast (int) tiles[0].length;

		SDL_Rect srcRect;
		srcRect.w = TILE_SIZE;
		srcRect.h = TILE_SIZE;
		SDL_Rect dstRect;
		dstRect.w = TILE_SIZE;
		dstRect.h = TILE_SIZE;

		foreach(i; beginX .. endX)
		{
			foreach(j; beginY .. endY)
			{
				TileLocation* location = tiles[i][j];
				if (location is null)
					continue;

				srcRect.x = location.x * TILE_SIZE;
				srcRect.y = location.y * TILE_SIZE;
				dstRect.x = (i * TILE_SIZE);
				dstRect.y = (j * TILE_SIZE);
				SDL_RenderCopy(renderer, textures[location.index], &srcRect,
					&dstRect);
			}
		}
	}

	TileLocation*[][] tiles;

}

class TileMap : Entity
{
public:
	this(int width, int height)
	{
		_width = width;
		_height = height;
		blockInfo = new byte[][](height);
		foreach (ref byte[] row; blockInfo)
			row = new byte[](width);
	}

	override void draw(SDL_Renderer* renderer)
	{
		foreach (Layer layer; layers)
		{
			layer.draw(renderer, textures);
		}
//		drawCollisionInfo(renderer, blockInfo);
	}

	@property int width() {return this.width;}
	@property int height() {return this.height;}

	/// Height in tiles
	int _height;

	/// Width in tiles
	int _width;

	/**
	 * Each byte represents pathing information
	 * 0b0001 = cannot go up from here
	 * 0b0010 = cannot go right from here
	 * 0b0100 = cannot go down from here
	 * 0b1000 = cannot go left from here
	 */
	byte[][] blockInfo;
	Layer[] layers;
	SDL_Texture*[] textures;

}

TileMap loadTileMap(string fileName, SDL_Renderer* renderer)
in
{
	assert(renderer);
	assert(fileName.length);
}
body
{
	writeln("Loading map ", fileName);
	string text = readText(fileName);
	JSONValue value = parseJSON(text);

	assert(value.type == JSON_TYPE.OBJECT);
	JSONValue tileMap = value.object["tileMap"];

	int width = cast(int) tileMap.object["width"].integer;
	int height = cast(int) tileMap.object["height"].integer;
	TileMap map = new TileMap(width, height);
	JSONValue layers = tileMap.object["layers"];
	map.blockInfo.length = width;
	foreach (ref blockColumn; map.blockInfo)
		blockColumn.length = height;
	foreach (JSONValue layer; layers.array)
	{
		Layer l;
		l.tiles.length = width;
		foreach (ref row; l.tiles)
			row.length = height;
		int index = cast(int) layer.object["index"].integer;
		assert("tiles" in layer.object);
		JSONValue[] tiles = layer.object["tiles"].array;
		foreach (JSONValue tile; tiles)
		{
			TileLocation* tl = new TileLocation;
			int x = cast(int) tile.object["x"].integer;
			int y = cast(int) tile.object["y"].integer;
			int ii = cast(int) tile.object["ii"].integer;
			int ix = cast(int) tile.object["ix"].integer;
			int iy = cast(int) tile.object["iy"].integer;
			tl.x = ix;
			tl.index = ii;
			tl.y = iy;
			l.tiles[x][y] = tl;
		}
		if (index >= map.layers.length)
			map.layers.length = index + 1;
		map.layers[index] = l;
	}

	foreach (JSONValue image; tileMap.object["images"].array)
	{
		int index = cast(int) image.object["index"].integer;
		string imageFileName = image.object["fileName"].str;
		SDL_Texture* tex = loadTexture(renderer, imageFileName);
		if (index >= map.textures.length)
			map.textures.length = index + 1;
		map.textures[index] = tex;
	}

	foreach (int x, JSONValue blockColumn; tileMap.object["blocking"].array)
	{
		foreach (int y, JSONValue v; blockColumn.array)
			map.blockInfo[x][y] = cast(byte) v.integer;
	}

	return map;
}

/**
 * For debugging
 */
void drawCollisionInfo(SDL_Renderer* renderer, byte[][] blockInfo)
{
	foreach(int i, column; blockInfo)
	{
		foreach (int j, block; column)
		{
			if (block & BLOCK_TOP)
			{
				SDL_Rect rect;
				rect.x = i * TILE_SIZE;
				rect.y = j * TILE_SIZE;
				rect.w = TILE_SIZE;
				rect.h = COLLISION_DEBUG_WIDTH;
				SDL_SetRenderDrawColor(renderer, 255, 0, 0, 128);
				SDL_RenderFillRect(renderer, &rect);
			}

			if (block & BLOCK_RIGHT)
			{
				SDL_Rect rect;
				rect.x = ((i + 1) * TILE_SIZE) - COLLISION_DEBUG_WIDTH;
				rect.y = j * TILE_SIZE;
				rect.w = COLLISION_DEBUG_WIDTH;
				rect.h = TILE_SIZE;
				SDL_SetRenderDrawColor(renderer, 255, 0, 0, 128);
				SDL_RenderFillRect(renderer, &rect);
			}

			if (block & BLOCK_BOTTOM)
			{
				SDL_Rect rect;
				rect.x = (i * TILE_SIZE);
				rect.y = ((j + 1) * TILE_SIZE) - COLLISION_DEBUG_WIDTH;
				rect.w = TILE_SIZE;
				rect.h = COLLISION_DEBUG_WIDTH;
				SDL_SetRenderDrawColor(renderer, 255, 0, 0, 128);
				SDL_RenderFillRect(renderer, &rect);
			}

			if (block & BLOCK_LEFT)
			{
				SDL_Rect rect;
				rect.x = i * TILE_SIZE;
				rect.y = j * TILE_SIZE;
				rect.w = COLLISION_DEBUG_WIDTH;
				rect.h = TILE_SIZE;
				SDL_SetRenderDrawColor(renderer, 255, 0, 0, 0);
				SDL_RenderFillRect(renderer, &rect);
			}
		}
	}
}

struct CollisionDisplacement
{
	SDL_Rect rect;
	int displacement;
	bool vertical;
}


void checkCollision(ref SDL_Rect objectPosition, const TileMap map,
	ref float xVel, ref float yVel)
in
{
	assert (map !is null);
//	assert (xVel < TILE_SIZE / 4 && xVel > -(TILE_SIZE / 4));
//	assert (yVel < TILE_SIZE / 4 && yVel > -(TILE_SIZE / 4));
}
body
{
	SDL_Point tl;
	tl.x = objectPosition.x / TILE_SIZE;
	tl.y = objectPosition.y / TILE_SIZE;

	SDL_Point br;
	br.x = (objectPosition.x + objectPosition.w) / TILE_SIZE;
	br.y = (objectPosition.y + objectPosition.h) / TILE_SIZE;

	SDL_Rect[] collisionRects = new SDL_Rect[(br.x - tl.x + 1) * (br.y - tl.y + 1)];
	CollisionDisplacement[] displacements;
	if (xVel != 0)
	{
		int sign;
		if (xVel < 0)
			sign = -1;
		else
			sign = 1;

		foreach (i; tl.x .. br.x + 1)
			foreach (j; tl.y .. br.y + 1)
				if (map.blockInfo[i][j] & (sign > 0 ? BLOCK_RIGHT : BLOCK_LEFT))
				{
					SDL_Rect r;
					r.x = (i + sign) * TILE_SIZE;
					r.y = j * TILE_SIZE;
					r.w = TILE_SIZE;
					r.h = TILE_SIZE;
					collisionRects ~= r;
				}
		foreach (ref rect; collisionRects)
		{
			if (!SDL_HasIntersection(&rect, &objectPosition))
				continue;
			CollisionDisplacement disp;
			disp.displacement = sign > 0 ? rect.x - (objectPosition.x + objectPosition.w)
				: (rect.x + rect.w) - objectPosition.x;
			disp.rect = rect;
			disp.vertical = false;
			displacements ~= disp;
		}
	}
	collisionRects = [];

	tl.x = objectPosition.x / TILE_SIZE;
	tl.y = objectPosition.y / TILE_SIZE;
	br.x = (objectPosition.x + objectPosition.w) / TILE_SIZE;
	br.y = (objectPosition.y + objectPosition.h) / TILE_SIZE;

	if (yVel != 0)
	{
		int sign;
		if (yVel < 0)
			sign = -1;
		else
			sign = 1;

		foreach (i; tl.x .. br.x + 1)
			foreach (j; tl.y .. br.y + 1)
				if (map.blockInfo[i][j] & (sign > 0 ? BLOCK_BOTTOM : BLOCK_TOP))
				{
					SDL_Rect r;
					r.x = i * TILE_SIZE;
					r.y = (j + sign) * TILE_SIZE;
					r.w = TILE_SIZE;
					r.h = TILE_SIZE;
					collisionRects ~= r;
				}
		foreach (ref rect; collisionRects)
		{
			if (!SDL_HasIntersection(&rect, &objectPosition))
				continue;
			CollisionDisplacement disp;
			disp.displacement = sign > 0 ? rect.y - (objectPosition.y + objectPosition.h)
				: (rect.y + rect.h) - objectPosition.y;
			disp.rect = rect;
			disp.vertical = true;
			displacements ~= disp;
		}
	}

	sort!("abs(a.displacement) < abs(b.displacement)")(displacements);
	foreach (ref CollisionDisplacement disp; displacements)
	{
		if (!SDL_HasIntersection(&disp.rect, &objectPosition))
			continue;
		if (disp.vertical)
		{
			yVel = 0;
			objectPosition.y += disp.displacement;
		}
		else
		{
			xVel = 0;
			objectPosition.x += disp.displacement;
		}
	}
}
