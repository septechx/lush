--!strict

local fetched = fetch("https://whatthecommit.com/index.txt")

Export = {
	fetched = fetched,
}
