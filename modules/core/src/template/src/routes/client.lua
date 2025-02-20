--!strict

Count, SetCount = createSignal(0)

function HandleClick()
	SetCount(Count() + 1)
end
