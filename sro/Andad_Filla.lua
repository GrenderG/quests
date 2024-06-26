-- Zone: Southern Ro
-- Short Name: sro
-- Zone ID: 35

-- NPC Name: Andad Filla
-- NPC ID: 35030
-- Quest Status: finished
-- Converted to .lua by Speedz

function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Hello, traveler, please do not bother me right now. I am waiting for someone.");
	end
end

function event_trade(e)
	local item_lib = require("items");
	if(item_lib.check_turn_in(e.self, e.trade, {item1 = 20533})) then
		e.self:Say("You still have a way to go!  Seek out Misty Tekcihta near the arena at Lake Rathe.  Run like the wind!");
		e.other:QuestReward(e.self,0,0,0,0,20534,1000);
	end
	item_lib.return_items(e.self, e.other, e.trade)
end
