-- Love2D Yamaha YMZ ADPCM Player - It's used on YMZ/YMU Series, and Audacity Does not Support This Format.
-- Created By GerioSB, Ported From MAME, ONLY FEED RAW FILES
local YMZVelocity = {}
local YMZIndexScale = { 0x0e6, 0x0e6, 0x0e6, 0x0e6, 0x133, 0x199, 0x200, 0x266 }
	for nib = 0,15 do
		value = math.fmod(nib,8) * 2 + 1
		YMZVelocity[nib] = nib >= 8 and -value or value
	end

local qsourceblocks = 8

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

local function lerp(a,b,t) return a * (1-t) + b * t end

local function inverselerp(a,b,t) return (t-a)/(b-a) end

local function clamp(x, a, b)
    return x > b and b or x < a and a or x;
end

local function ProcessYMZ(self)
	self.CurrentPosition = self.CurrentPosition + 1
	self.CurrentSampleLoudness = clamp(self.CurrentSampleLoudness + (self.CurrentStepSize * YMZVelocity[self.Samples[self.CurrentPosition]]),0,65535)
	self.CurrentStepSize = clamp(math.floor((self.CurrentStepSize*YMZIndexScale[math.fmod(self.Samples[self.CurrentPosition],8)+1])/256),0x7f,0x6000)
end

return function(Sound)

local GerioYMZ = {}

GerioYMZ.Buffer = love.sound.newSoundData(2048,48000,16,1)
GerioYMZ.Qsource = love.audio.newQueueableSource(48000,16,1,qsourceblocks)
GerioYMZ.Samples = {}
GerioYMZ.Hertz = 22050
GerioYMZ.Loops = 0
GerioYMZ.EndPosition = 0
GerioYMZ.LoopPosition = 0
GerioYMZ.CurrentPosition = 0
GerioYMZ.PlayPosition = 0
GerioYMZ.Volume = 1
GerioYMZ.Looped = false
GerioYMZ.Playing = false
GerioYMZ.CurrentSampleLoudness = 32768
GerioYMZ.CurrentStepSize = 0
GerioYMZ.PreviousSampleLoudness = 0
GerioYMZ.QueueExhaustion = false

	for p = 1,string.len(Sound) do
		local DualSample = string.byte(string.sub(Sound,p,p))
		table.insert(GerioYMZ.Samples,math.floor(DualSample/16))
		table.insert(GerioYMZ.Samples,math.fmod(DualSample,16))
	end

function GerioYMZ.Play(self,Position,EndPosition,Hertz,Volume,Loop,LoopPosition) -- position on samples
	
	if Loop and Loop == true then
		self.Loops = math.huge
	elseif Loop and type(Loop) == "number" then
		self.Loops = Loop
	else
		self.Loops = 0
	end
	self.QueueExhaustion = true
	
	self.CurrentPosition = Position
	self.PlayPosition = Position
	self.CurrentSampleLoudness = 32768
	self.CurrentStepSize = 1
	self.Hertz = Hertz
	self.EndPosition = EndPosition
	self.LoopPosition = LoopPosition or Position
	self.Playing = true
	self.Volume = Volume or 1
	self.Looped = false
end

function GerioYMZ.PlayNoQueueExhaustion(self,Position,EndPosition,Hertz,Volume,Loop,LoopPosition) -- position on samples
	
	if Loop and Loop == true then
		self.Loops = math.huge
	elseif Loop and type(Loop) == "number" then
		self.Loops = Loop
	else
		self.Loops = 0
	end
	
	self.CurrentPosition = Position
	self.CurrentSampleLoudness = 32768
	self.CurrentStepSize = 1
	self.Hertz = Hertz
	self.EndPosition = EndPosition
	self.LoopPosition = LoopPosition or Position
	self.Playing = true
	self.Volume = Volume or 1
end

function GerioYMZ.Change(self,EndPosition,Hertz,Volume,Loop,LoopPosition)
	if LoopPosition then self.LoopPosition = LoopPosition end
	if EndPosition then self.EndPosition = EndPosition end
	if Loop and Loop == true then
		self.Loops = math.huge
	elseif Loop and type(Loop) == "number" then
		self.Loops = Loop
	end
	if Volume then self.Volume = Volume end
end

function GerioYMZ.GetPosition(self)
	if not self:IsPlaying() then return nil end
	local haribon = (self.CurrentPosition-((qsourceblocks-self.Qsource:getFreeBufferCount())*2048))+self.Qsource:tell("samples")
	if haribon < self.LoopPosition and self.Looped then haribon = haribon + math.abs(self.EndPosition - self.LoopPosition) end
	return haribon
end

function GerioYMZ.GetElapsedSamples(self)
	if not self:IsPlaying() then return nil end
	local haribon = (self.CurrentPosition-((qsourceblocks-self.Qsource:getFreeBufferCount())*2048)-self.PlayPosition)+self.Qsource:tell("samples")
	return haribon
end

function GerioYMZ.IsPlaying(self)
	local playing = self.Qsource:getFreeBufferCount() < qsourceblocks or self.Playing
	if playing == "Paused" then playing = false end
	return playing
end

function GerioYMZ.Stop(self)
	self.Playing = false
end

function GerioYMZ.Update(self)
	if self.Playing == true then
	if self.QueueExhaustion then
		self.Qsource:setPitch(1e+38)
		self.QueueExhaustion = self.Qsource:getFreeBufferCount() < qsourceblocks
	end
	if not self.QueueExhaustion then
	if self.Qsource:getFreeBufferCount() > 0 then
	-- generate one buffer's worth of audio data; the above line is enough for timing purposes
		for i = 0, self.Buffer:getSampleCount()-1 do
			--self.Buffer:getSampleRate()
			--if self.Hertz == self.Buffer:getSampleRate() then
				ProcessYMZ(self)
				self.PreviousSampleLoudness = self.CurrentSampleLoudness
				for c = 1, self.Buffer:getChannelCount() do
					self.Buffer:setSample(i, c, clamp((lerp(-1,1,inverselerp(0,65535,self.CurrentSampleLoudness)))*self.Volume,-1,1))
				end
			--[[else
				self.CurrentSubPosition = self.CurrentSubPosition + (self.Hertz/self.Buffer:getSampleRate())
				while self.CurrentSubPosition >= 1 do
					ProcessYMZ(self)
					self.PreviousSampleLoudness = self.CurrentSampleLoudness
					self.CurrentSubPosition = self.CurrentSubPosition - 1
				end
				local nriyrbgyu = lerp(lerp(-1,1,inverselerp(0,65535,self.PreviousSampleLoudness)),lerp(-1,1,inverselerp(0,65535,self.CurrentSampleLoudness)),self.CurrentSubPosition)
				for c = 1, self.Buffer:getChannelCount() do
					self.Buffer:setSample(i, c, clamp(nriyrbgyu*self.Volume,-1,1))
				end
			end--]]
			--print(((self.CurrentSampleLoudness-2048)*(1/4096))*self.Volume)
		-- queue it up
			if self.CurrentPosition >= self.EndPosition or (not self.Samples[self.CurrentPosition+1]) then
				if self.Loops > 1 then
					self:PlayNoQueueExhaustion(self.LoopPosition,self.EndPosition,self.Hertz,self.Volume,self.Loops - 1,self.LoopPosition)
					self.Looped = true
					self.PlayPosition = self.PlayPosition - math.abs(self.EndPosition - self.LoopPosition)
				else
					self.Playing = "Paused"
					break
				end
			end
		end
		self.Qsource:queue(self.Buffer)
		self.Qsource:setPitch(self.Hertz/self.Buffer:getSampleRate())
		self.Qsource:play() -- keep playing so playback never stalls, even if there are underruns; no, this isn't heavy on processing.
	end
	end
	elseif self.Playing == "Paused" then
		if not (self.Qsource:getFreeBufferCount() < qsourceblocks) then
			self.Playing = false
		end
	elseif self.Playing == false then
		self.QueueExhaustion = true
	end
end

--[[setmetatable(GerioYMZ, {
})]]

return GerioYMZ
end