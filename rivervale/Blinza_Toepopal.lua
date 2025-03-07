function event_spawn(e)
	eq.set_timer("jillin",550000);
end

function event_timer(e)
	if(e.timer == "jillin") then
		e.self:Say("[Jillin]? Jillin? Where did he go? Hrumph!");
	end
end

function event_say(e)
	if(e.message:findi("hail")) then
		e.self:Say("Hello, " .. e.other:GetCleanName() .. ".  Welcome to the Fool's Gold!  Cards are upstairs, drinks are down here.  Have fun!"); 
	elseif(e.message:findi("jillin")) then
		e.self:Say("Jillin is my courier. He was supposed to take this pot of [stew] over to Deputy Lowmot in Guardian Stronghold. It is just about ready and Mayor Gubbin hates cold stew!"); 
	elseif(e.message:findi("stew")) then
		e.self:Say("Here. Take it to Lowmot. The stew is already paid for but the good Deputy usually tips Jillin quite well. Hurry! It's getting cold!");
		e.other:SummonCursorItem(13959); -- Item: Carrot Stew
	end
end

function event_trade(e)
	local item_lib = require("items");

	if (item_lib.check_turn_in(e.self, e.trade,  {item1 = 13958})) then
		e.self:Say("Well it is about time!  The mayor gets very upset if he does not have the freshest of carrots in his stew.  Here is the money for the carrots.  Be off with you.  Now, where the heck did [Jillin] go?");
		e.other:Faction(e.self,241, 1); -- Faction: DeepPockets
		e.other:Faction(e.self,223, 1); -- Faction: Circle of Unseen Hands
		e.other:Faction(e.self,292, -1); -- Faction: Merchants of Rivervale
		e.other:Faction(e.self,336, 1); -- Faction: Coalition of Tradefolk Underground
		e.other:Faction(e.self,329, 1); -- Faction: Carson McCabe
		e.other:QuestReward(e.self,1,0,0,0,0,10);
	elseif (item_lib.check_turn_in(e.self, e.trade,  {item1 = 13957})) then
		e.self:Say("Oh excellent! These carrots are perfect! The finest Reebo has ever sent us. The mayor will be so pleased. Here is the payment for the carrots. Excuse me, but I must finish preparing the stew. Hmm. Where the heck did [Jillin] go?");
		e.other:Faction(e.self,241, 5); -- Faction: DeepPockets
		e.other:Faction(e.self,223, 1); -- Faction: Circle of Unseen Hands
		e.other:Faction(e.self,292, -1); -- Faction: Merchants of Rivervale
		e.other:Faction(e.self,336, 1); -- Faction: Coalition of Tradefolk Underground
		e.other:Faction(e.self,329, 1); -- Faction: Carson McCabe
		e.other:QuestReward(e.self,math.random(5),math.random(2),0,0,0,20);
	elseif (item_lib.check_turn_in(e.self, e.trade,  {item1 = 13971})) then
		e.self:Say("What are these?!  I am trying to make stew for the mayor and you bring me ROTTEN CARROTS?!  Have you no sense??  Take these back to Reebo.");
		e.other:Faction(e.self,241, -5); -- Faction: DeepPockets
		e.other:Faction(e.self,223, -1); -- Faction: Circle of Unseen Hands
		e.other:Faction(e.self,292, 1); -- Faction: Merchants of Rivervale
		e.other:Faction(e.self,336, -1); -- Faction: Coalition of Tradefolk Underground
		e.other:Faction(e.self,329, -1); -- Faction: Carson McCabe
		e.other:QuestReward(e.self,0,0,0,0,13972);
	end
	item_lib.return_items(e.self, e.other, e.trade);
end

--END of FILE Zone:rivervale  ID:19091 -- Blinza_Toepopal
