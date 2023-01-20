--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Lucas 01">
 <unique />
 <chance>20</chance>
 <location>Bar</location>
 <cond>
   -- Required to bribe Maanen's Moon
   if faction.get("Empire"):playerStanding() &lt; 0 then
      return false
   end

   -- Should start at a normal planet
   local t = spob.cur():tags
   if t.refugee or t.station then
      return false
   end

   -- Distance to closest refugee planet
   local dist = math.huge
   for k,v in ipairs(spob.getAll())
      if v:tags().refugee
         dist = math.min( dist, v:system():jumpDist() )
      end
   end
   return dist &lt; 6
 </cond>
 <notes>
  <tier>1</tier>
  <campaign>Lucas</campaign>
 </notes>
</mission>
--]]
--[[
   Refugee Family

   A person who escaped the Incident is trying to get in touch with their family.
--]]
local fmt = require "format"
local vn = require "vn"
local lmisn = require "lmisn"
local mg = require "minigames.flip"
local lcs = require "common.lucas"

local title = _([[Refugee Family]])
local reward = 300e3

-- Mission stages
-- 0: just started
-- 1: visited first spob
-- 2: visited last spob and got family
mem.stage = 0

local first_spob, first_sys
local last_spob, last_sys = spob.getS("Maanen's Moon")

function create ()
   misn.finish(false)

   -- Get closest refugee planet
   local candidates = lmisn.getSpobAtDistance( nil, 0, math.huge, nil, false, function( s )
      return s:tags().refugee
   end )
   if #candidates <= 0 then
      misn.finish(false)
      return
   end
   table.sort( candidates, function ( a, b )
      return a:system():jumpDist() < b:system():jumpDist()
   end )

   -- First spob is closest one, second one is fixed
   first_spob, first_sys = candidates[1], candidates[1]:system()
   mem.return_spob, mem.return_sys = spob.cur()

   misn.setNPC( lcs.lucas.name, lcs.lucas.portrait, _([[The person looks stressed and worn out.]]) )
end

function accept ()
   local accepted = false

   vn.clear()
   vn.scene()
   local lucas = lcs.vn_lucas()
   vn.transition()
   vn.na(_([[You approach the stressed out individual gnawing at their nails at the bar.]]))
   lucas(_([["Say, you wouldn't be able to help me find my family? I'll pay, I promise!"]]))
   vn.menu{
      {_([[Accept]]), "accept"},
      {_([[Refuse]]), "refuse"},
   }

   vn.label("refuse")
   lucas(_([[They go back to chewing their nails.]]))
   vn.done()

   vn.label("accept")
   vn.func( function ()
      accepted = true
   end )
   lucas(_([["My name is Lucas, I was a Nebula refugee. When I was very young, me and my family escaped the Incident, but I don't know what happened and I got separated."]]))
   lucas(_([["I guess I never really thought about it too much, just did what I was told and went with the flow, but then one day I couldn't. You understand?"]]))
   lucas(_([[The pause and tighten their fists.
"I guess there was always something missing in me, like something fundamental was taken away by the Incident. However, I just didn't realize it, didn't understand."]]))
   lucas(_([["One day it snapped, and I had a dream remembering stuff I had forgotten about: my family. I guess I had repressed it for so long. Survival instincts maybe?"]]))
   lucas(_([["Since then I've been trying to find my family with the credits I was able to scrounge up working. I don't think they had as much luck as I had, they are probably stuck on some refugee world. The governments don't care for us at all. They just toss refugees into barely habitable planets and turn their eyes away. We are humans too!"]]))
   lucas(fmt.f(_([["I've narrowed it down a bit, I think they should be on {spb} in the {sys} system. Please try to find them! I'll give you all the information I have. Here take this locket, it is the only thing I have from them."]]),
      {spb=first_spob, sys=first_sys}))
   vn.na(_([[They hand you an old locket that looks like is missing half of it. It is fairly simple and made of some resistant metal alloy, but bears signs of heavy use.]]))
   lucas(_([["I'll be waiting here."]]))
   vn.run()

   if not accepted then return end

   misn.accept()
   misn.setTitle( title )
   misn.setDesc(_([[You promised to help Lucas, the ex-Nebula refugee, find his family who may not have made it far from the Nebula.]]))
   misn.setReward(fmt.credits(reward))

   local c = commodity.new( N_("Old Pendant"), N_("An old locket belonging to Lucas.") )
   mem.cargo = misn.cargoAdd( c, 0 )

   misn.osdCreate(_(title), {
      fmt.f(_([[Search for the family at {pnt} ({sys} system)]]),
         {pnt=first_spob, sys=first_sys}),
      fmt.f(_([[Return to {pnt} ({sys} system)]]),
         {pnt=mem.return_spob, sys=mem.return_sys}),
   })
   mem.mrk = misn.markerAdd( first_spob )

   hook.land("land")
end

function land ()
   local spb = spob.cur()
   if mem.stage==0 and spb==first_spob then
      vn.clear()
      vn.scene()

      vn.na(_([[You land and begin to ask around to see if there are any traces of Lucas family.]]))
      vn.na(fmt.f(_([[As you converse with many of the refugees at {spb}, you begin to appreciate the magnitude of the Incident calamity. Many refugees are missing or searching for family members, with deep psychological scars that are unable to heal.]]),
         {spb=spb}))
      vn.na(fmt.f(_([[Feeling like searching for a needle in a haystack, you are almost about to give up when you find an older one-armed refugee. They take a close look at the locket and mention that they used to share a cell with someone using the same locket on {spb} in the {sys} system.]]),
         {spb=last_spob, sys=last_sys}))
      vn.na(fmt.f(_([[From their story, it seems like {spb} is a horrible traumatic place, a refugee limbo where atrocities are commonplace. It also seems like the planet is locked down, you'll likely have to bribe the authorities to access it.]]),
         {spb=last_spob}))
      vn.na(_([[They give you the location of the cell where they were and wish you luck. Looks like you have a lead.]]))

      vn.run()

      misn.osdCreate(_(title), {
         fmt.f(_([[Search for the family at {pnt} ({sys} system, bribe if necessary)]]),
            {pnt=last_spob, sys=last_sys}),
         fmt.f(_([[Return to {pnt} ({sys} system)]]),
            {pnt=mem.return_spob, sys=mem.return_sys}),
      })
      mem.markerMove( mem.mrk, last_spob )
      mem.stage = 1

   elseif mem.stage==1 and spb==last_spob then
      vn.clear()
      vn.scene()

      vn.na(fmt.f(_([[You manage to land on {spb}.]]),
         {spb=spb}))

      mg.vn()
      vn.func( function ()
         if mg.completed() then
            misn.osdActive(2)
            mem.markerMove( mem.mrk, mem.return_spob )
            mem.stage=1
         else
            vn.jump("failed")
         end
      end )

      vn.label("failed")
      vn.na(_([[]]))
      vn.done()

      vn.run()

   elseif mem.stage==2 and spb==mem.return_spob then
      vn.clear()
      vn.scene()
      local lucas = lcs.vn_lucas()
      lucas(_([[]]))

      vn.sfxVictory()
      vn.func( function ()
         player.pay( reward )
      end )
      vn.na(fmt.reward(reward))

      vn.run()

   end

   misn.finish(true)
end