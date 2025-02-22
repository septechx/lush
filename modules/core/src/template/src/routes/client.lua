--!strict

local count, setCount = createSignal(0)

local function handleClick()
	setCount(count() + 1)
end

Export = {
	count = count,
	handleClick = handleClick,
}
