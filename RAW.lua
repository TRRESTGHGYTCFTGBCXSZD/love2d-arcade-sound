-- Love2D Raw Decoder
-- Created By GerioSB, ONLY FEED RAW FILES

local function lerp(a,b,t) return a * (1-t) + b * t end

local function inverselerp(a,b,t) return (t-a)/(b-a) end

return {
["Create8"]=function(Sound,Hertz,Channels,Unsigned,SwapNibbles)
	local Samples={}
	for p = 1,string.len(Sound) do
		local Sample = string.byte(string.sub(Sound,p,p))
		if SwapNibbles then
			Sample = math.fmod(Sample*16,256)+math.floor(Sample/16)
		end
		if Unsigned then
			Sample = math.fmod(Sample+128,256)
		end
		table.insert(Samples,Sample)
	end
	local Sanyo = love.sound.newSoundData(string.len(Sound), Hertz, 8, Channels )
	local SanSanyoyo = 0
	for i=0, Sanyo:getSampleCount() - 1 do
		for j=1,Channels do
			SanSanyoyo = SanSanyoyo + 1
			Sanyo:setSample(i, j, lerp(-.5,.5,inverselerp(0,255,Samples[SanSanyoyo])))
		end
	end
	return love.audio.newSource(Sanyo)
end,
["Create16"]=function(Sound,Hertz,Channels,Unsigned,BigEndian)
	local Samples={}
	for p = 1,string.len(Sound) do
		local HalfSample1 = string.byte(string.sub(Sound,p,p))
		local HalfSample2 = string.byte(string.sub(Sound,p,p))
		if BigEndian then
			Sample = (HalfSample1*256)+HalfSample2
		else
			Sample = (HalfSample2*256)+HalfSample1
		end
		if Unsigned then
			Sample = math.fmod(Sample+32768,65536)
		end
	end
	local Sanyo = love.sound.newSoundData(string.len(Sound)/2, Hertz, 16, Channels )
	local SanSanyoyo = 0
	for i=0, Sanyo:getSampleCount() - 1 do
		for j=1,Channels do
			SanSanyoyo = SanSanyoyo + 1
			Sanyo:setSample(i, j, lerp(-.5,.5,inverselerp(0,65535,Samples[SanSanyoyo])))
		end
	end
	return love.audio.newSource(Sanyo)
end,
}