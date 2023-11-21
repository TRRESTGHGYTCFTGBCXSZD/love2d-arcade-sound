-- Love2D Dialogic VOX ADPCM Player - It's used on OKI MSM6295, and Audacity Supports This Format.
-- Created By GerioSB, ONLY FEED RAW FILES

local VOXVelocity = {16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,88,97,
107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,598,658,
724,796,876,963,1060,1166,1282,1411,1552}

local function GetStepSize(OldStepSize,Sample)
	local StepSize
	if math.fmod(Sample,8) == 4 then
		StepSize = OldStepSize + 2
	elseif math.fmod(Sample,8) == 5 then
		StepSize = OldStepSize + 4
	elseif math.fmod(Sample,8) == 6 then
		StepSize = OldStepSize + 6
	elseif math.fmod(Sample,8) == 7 then
		StepSize = OldStepSize + 8
	else
		StepSize = OldStepSize - 1
	end
	return StepSize
end

local function clamp(x, a, b)
    return x > b and b or x < a and a or x;
end

local function lerp(a,b,t) return a * (1-t) + b * t end

local function inverselerp(a,b,t) return (t-a)/(b-a) end

local function ProcessVOX(self)
	self.CurrentPosition = self.CurrentPosition + 1
	if not self.Samples[self.CurrentPosition] then return end
	diff = VOXVelocity[self.CurrentStepSize]/8
	if math.fmod(self.Samples[self.CurrentPosition],2) >= 1 then
	diff = diff + VOXVelocity[self.CurrentStepSize]/4
	end
	if math.fmod(self.Samples[self.CurrentPosition],4) >= 2 then
	diff = diff + VOXVelocity[self.CurrentStepSize]/2
	end
	if math.fmod(self.Samples[self.CurrentPosition],8) >= 4 then
	diff = diff + VOXVelocity[self.CurrentStepSize]
	end
	self.CurrentSampleLoudness = clamp(self.CurrentSampleLoudness + (diff * (self.Samples[self.CurrentPosition] >= 8 and -1 or 1)),0,4095)
	self.CurrentStepSize = clamp(GetStepSize(self.CurrentStepSize,self.Samples[self.CurrentPosition]),1,49)
	--[[if (math.fmod(self.Samples[self.CurrentPosition],8) < 8) ~= self.ZeroChainPositive then
		self.ZeroChain = self.ZeroChain + 1
	else
		self.ZeroChain = 0
	end
	if self.ZeroChain >= 48 then
	self.CurrentSampleLoudness = 2048
	self.CurrentStepSize = 1
	self.ZeroChain = 0
	end--]]
	self.ZeroChainPositive = math.fmod(self.Samples[self.CurrentPosition],8) < 8
end

return function(Sound,Hertz,MSM62xx,SwapNibbles)

local GerioVOX = {}

--GerioVOX.Buffer = nil
--GerioVOX.Qsource = nil
GerioVOX.Samples = {}
GerioVOX.Hertz = 8000
GerioVOX.Loops = 0
GerioVOX.EndPosition = 0
GerioVOX.LoopPosition = 0
GerioVOX.CurrentPosition = 0
GerioVOX.CurrentSubPosition = 0
GerioVOX.Volume = 1
GerioVOX.Playing = false
GerioVOX.CurrentSampleLoudness = 0
GerioVOX.CurrentStepSize = 0
GerioVOX.PreviousSampleLoudness = 0
GerioVOX.ZeroChain = 0
GerioVOX.ZeroChainPositive = false
GerioVOX.QueueExhaustion = false

	if MSM62xx and MSM62xx == 1 then
		Hertz = Hertz * (8000/1056000)
	elseif MSM62xx and MSM62xx == 2 then
		Hertz = Hertz * (6400/1056000)
	else
		Hertz = Hertz
	end
	GerioVOX.Buffer = love.sound.newSoundData(2048,Hertz,16,1)
	GerioVOX.Qsource = love.audio.newQueueableSource(Hertz,16,1,4)
	for p = 1,string.len(Sound) do
		local DualSample = string.byte(string.sub(Sound,p,p))
		if SwapNibbles then -- MSM6258
		table.insert(GerioVOX.Samples,math.fmod(DualSample,16))
		table.insert(GerioVOX.Samples,math.floor(DualSample/16))
		else -- MSM6295
		table.insert(GerioVOX.Samples,math.floor(DualSample/16))
		table.insert(GerioVOX.Samples,math.fmod(DualSample,16))
		end
	end

function GerioVOX.Play(self,Position,EndPosition,Volume,Loop,LoopPosition) -- position on samples
	
	if Loop and Loop == true then
		self.Loops = math.huge
	elseif Loop and type(Loop) == "number" then
		self.Loops = Loop
	else
		self.Loops = 0
	end
	self.QueueExhaustion = true
	
	self.CurrentPosition = Position
	self.CurrentSampleLoudness = 2048
	self.CurrentStepSize = 1
	self.EndPosition = EndPosition
	self.ZeroChain = 0
	self.ZeroChainPositive = false
	self.LoopPosition = LoopPosition or Position
	self.Playing = true
	self.Volume = Volume or 1
end

function GerioVOX.PlayNoQueueExhaustion(self,Position,EndPosition,Volume,Loop,LoopPosition) -- position on samples
	
	if Loop and Loop == true then
		self.Loops = math.huge
	elseif Loop and type(Loop) == "number" then
		self.Loops = Loop
	else
		self.Loops = 0
	end
	
	self.CurrentPosition = Position
	self.CurrentSampleLoudness = 2048
	self.CurrentStepSize = 1
	self.EndPosition = EndPosition
	self.ZeroChain = 0
	self.ZeroChainPositive = false
	self.LoopPosition = LoopPosition or Position
	self.Playing = true
	self.Volume = Volume or 1
end

function GerioVOX.Change(self,EndPosition,Volume,Loop,LoopPosition)
	if LoopPosition then self.LoopPosition = LoopPosition end
	if EndPosition then self.EndPosition = EndPosition end
	if Loop and Loop == true then
		self.Loops = math.huge
	elseif Loop and type(Loop) == "number" then
		self.Loops = Loop
	end
	if Volume then self.Volume = Volume end
end

function GerioVOX.Stop(self)
	self.Playing = false
end

function GerioVOX.Update(self)
	if self.Playing == true then
	if self.QueueExhaustion then
		self.Qsource:setPitch(1e+38)
		self.QueueExhaustion = self.Qsource:getFreeBufferCount() < 4
	end
	if not self.QueueExhaustion then
	if self.Qsource:getFreeBufferCount() > 0 then
	-- generate one buffer's worth of audio data; the above line is enough for timing purposes
		for i = 0, self.Buffer:getSampleCount()-1 do
			--self.Buffer:getSampleRate()
			ProcessVOX(self)
			--print(((self.CurrentSampleLoudness-2048)*(1/4096))*self.Volume)
			self.PreviousSampleLoudness = self.CurrentSampleLoudness
			for c = 1, self.Buffer:getChannelCount() do
				self.Buffer:setSample(i, c, clamp((lerp(-1,1,inverselerp(0,4095,self.CurrentSampleLoudness)))*self.Volume,-1,1))
			end
		-- queue it up
			if self.CurrentPosition >= self.EndPosition or (not self.Samples[self.CurrentPosition]) then
				if self.Loops > 1 then
					self:PlayNoQueueExhaustion(self.LoopPosition,self.EndPosition,self.Volume,self.Loops - 1,self.LoopPosition)
				else
					self.Playing = "Paused"
					break
				end
			end
		end
		self.Qsource:queue(self.Buffer)
		self.Qsource:setPitch(1)
		self.Qsource:play() -- keep playing so playback never stalls, even if there are underruns; no, this isn't heavy on processing.
		end
	end
	elseif self.Playing == "Paused" then
	elseif self.Playing == false then
		self.QueueExhaustion = true
	end
end

--[[setmetatable(GerioVOX, {
})]]

return GerioVOX
end