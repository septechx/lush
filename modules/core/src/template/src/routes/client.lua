Count, SetCount = CreateSignal(0)

function HandleClick()
	SetCount(Count() + 1)
end
