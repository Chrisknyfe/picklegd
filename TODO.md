
# TODO
- Multiplayer Example: TCP server for larger packets in the example, UDP fragmentation starts at 1392 byte packets.

# TODO after seeing KoBeWi's serializer: https://godotengine.org/asset-library/asset/3167
- I never thought I would have to assign/overwrite an array's values like so:
			if value is Array:
				object.get(property).assign(value)
			else:
				object.set(property, value)
	do I need to also assign to dictionaries?
- copy Registry back to my game, along with unit tests
