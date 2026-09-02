--[[
	The EQLegends server had the pre-revamp Highpass zone and it was observed to get the classic behavior.
	
	There are 14 orc spawn points.  I checked these locations against the ficticiousname9 data and they matched.
	
	Sony's spawn behavior is different than the emus.  On Sony servers, mobs can spawn in multiple different locations,
	and Sony had a not-often used feature where the mobs can be duplicated when they spawn.  Highpass orcs use this
	behavior: when an orc spawn is killed, the repop has a chance to respawn as two orcs.  Killing the 2nd orc doesn't
	trigger a repop, just the 'real one' does.  They don't spawn on top of each other, they spawn in different locations.
	Duplication chance seemed to be 50%.  The named placeholder does not duplicate however.
	
	I did observe spawns stacked on each other as there were only 14 spawn locations, but I did not observe stacking from
	killing a single mob and seeing it duplicate although I could have easily missed it.
	
	The respawn time on EQL was about 4.8 minutes for all orcs which is expected because at some point Sony reduced spawn
	timers globally by 20%.  So the real respawn time is six minutes and this matches AK logs.
	
	A lot of old player commentary mentions "waves" but the spawns are simply six minute spawns that can double.  Wave-like
	spawning is most likely because orcs died close together from guards.
	
	The maxmimum number of orcs I saw spawned simultaneously was 10.  The minimum I recall seeing was six.  10 was quite rare;
	I only saw 10 once but six seemed more common.  I'm not sure exactly how Sony did this.  It might have been something like
	4 spawns duplicated and two did not, one being the named.  I have doubts it was 5+1 as that seems too many but I cannot know.
	
	Since emu servers don't innately have this random spawn location behavior nor spawn duplication, I replicated it
	this way: each non-named orc spawn has its own spawngroup with multiple spawn locations, with a spawn limit of 1.  Our
	Quillmane spawns like this as well.  This script handles the spawn duplication.
	
	The 14 spawn locations are:  (some of these might be off by 1 and the Z locs more so)
	
	1  x: 266   y: -806   z: 7.7
	2  x: 252   y: -816   z: 7
	3  x: 244   y: -825   z: 17
	4  x: 244   y: -835   z: 21.4
	5  x: 245   y: -843   z: 12.7
	6  x: 241   y: -856   z: 10
	7  x: 234   y: -861   z: 14
	8  x: 227   y: -867   z: 17.2
	9  x: 223   y: -867   z: 30
	10 x: 213   y: -873   z: 42
	11 x: 204   y: -877   z: 50
	12 x: 258   y: -862   z: 4
	13 x: 228   y: -884   z: 5	(this one might be off by more than 1 as it was eyeballed)
	14 x: 232   y: -896   z: 5

	Note that the named only spawn from locs 9, 10, 11
	
	For gnolls, there are at least 29 spawn points. (I may have missed one)  Gnolls spawn on some of their grid points on Sony's servers.
	
	There seems to be about six gnoll spawns, at least two of which had six minute timers but I didn't spend much time trying to figure
	this out so this is uncertain.  Some of the timers may have been longer.
	
	To replicate gnoll spawning, I used waypoint spawning to randomize their spawn locations, then this script constructs a new grid on
	spawn which takes them under the ramp, then it sets another grid from the database which runs them through the zone.  Orcs didn't
	require this because they spawned close enough together to share a grid.
	
	From my observations gnolls duplicated much less frequently than orcs, so I set the chance lower.
]]

local ORC_SPAWNGROUPID = 5001;  -- important: this spawn group needs to have all 14 spawn locations in it, the others don't
local ORC_TYPES = { 5002, 5014, 5082, 5085, 5012, 5001, 5089, 5084, 5130, 5135, 5127, 5142 };
local ORC_DUPE_GROUPS = { [448352] = true, [448353] = true, [448354] = true, [448354] = true };	-- these spawngroups will spawn duplicates

local GNOLL_TYPES = { 5075, 5110, 5113, 5124, 5076, 5081 };

-- Gnolls shouldn't have a spawn limit.  Instead set their database grids to one of two grids for upper and lower areas and use waypoint spawning
-- I'm using grids 15 and 20 for this
local GNOLL_DUPE_GROUPS = { [222363] = true, [224134] = true  };  -- exclude the named gnoll spawngrounp

-- These are the gnoll spawn locations, except the last three locs.  These are also grid points
local GNOLL_LOCS1 = {
	126.00, 819.00, 3.10,
	158.00, 818.00, 3.10,
	175.00, 805.00, 3.10,
	182.00, 776.00, 3.10,
	152.00, 755.00, 3.10,
	116.00, 755.00, 3.10,
	98.00, 733.00, 3.10,
	98.00, 700.00, 3.10,
	122.00, 673.00, 5.80,
	147.00, 663.00, 8.10,
	163.00, 632.00, 8.10,
	166.00, 597.00, 6.20,
	155.00, 575.00, 4.50,
	155.00, 543.00, 3.10,
	155.00, 519.00, 3.10,	
	127, 507, 3.1,
	130, 482, 3.1,
	163, 427, 3.1,
};
local GNOLL_LOCS2 = {
	84.00, 664.00, 49.00,
	71.00, 644.00, 45.70,
	88.00, 629.00, 43.70,
	96.00, 610.00, 34.80,
	91.00, 592.00, 34.50,
	82.00, 572.00, 39.20,
	77.00, 553.00, 43.00,
	79.00, 538.00, 37.00,
	80.00, 520.00, 31.10,
	95.00, 500.00, 30.10,
	94.00, 481.00, 30.10,
	92.00, 462.00, 29.10,
	113.00, 446.00, 33.50,
	132.00, 438.00, 37.70,
	90, 453, 29.1,
	106, 427, 19.1,
	163, 427, 3.1,
};

local orcLocs = {};
local errorCount = 0;

function GetClosestGnollLoc(npc)
	local t;
	if ( npc:GetZ() < 25 ) then
		t = GNOLL_LOCS1;
	else
		t = GNOLL_LOCS2;
	end
	
	local x, y = npc:GetX(), npc:GetY();
	local x2, y2, dist, loc;
	local closestL, closestD = 1, 999;
	local i = 1;
	while (t[i]) do
		x2 = t[i];
		y2 = t[i+1];
		dist = math.abs(x - x2) + math.abs(y - y2);
		if ( dist < 5 ) then
			loc = i;
			break;
		end
		if ( dist < closestD ) then
			closestL = i;
			closestD = dist;
		end
		i = i + 3;
	end
	if ( loc ) then
		return loc, t;
	else
		return closestL, t;	-- this shouldn't happen; make sure gnoll spawnpoints are the same or approximate as the locs in the tables minus the last three
	end
end

function GetRandomOrcSpawnLoc()
	local length = #orcLocs;
	
	if ( length < 3 ) then
		-- this will happen on the first wave of a zone boot, then it shouldn't anymore
		-- if it always happens, set the correct ORC_SPAWNGROUPID and make sure the points are right
		return 258, -862, 4;
	end
	
	local rng = (math.random(length/3) - 1) * 3;
	local x, y, z = orcLocs[rng+1], orcLocs[rng+2], orcLocs[rng+3];
	
	if ( y > -800 ) then
		-- sanity check; spawn loc is farther north than expected
		errorCount = errorCount + 1;
		if ( errorCount < 10 ) then
			eq.debug("Error with the orc script: invalid orc spawn loc.  ("..x..", "..y..", "..z..")");
		end
		return 258, -862, 4;
	end
	
	return x, y, z;
end

function OrcSpawnEvent(e)
	if ( e.self:GetY() > -800 ) then
		return; -- sanity check
	end
	
	if ( e.self:GetGrid() > 0 ) then
		
		-- make the northenmost spawn points skip the first onr or two waypoints so they path better
		if ( e.self:GetY() > -836 ) then
			e.self:CalculateNewWaypoint();
		end
		if ( e.self:GetY() > -860 ) then
			e.self:CalculateNewWaypoint();
		end
		
		e.self:PauseWandering(45);
	end
	
	if ( not ORC_DUPE_GROUPS[e.self:GetSp2()] ) then
		--eq.debug("refusing to duplicate a duplicate");
		return;
	end

	if ( math.random(2) == 2 ) then  -- 50% chance
	
		local x, y, z = GetRandomOrcSpawnLoc();
		
		if ( y == e.self:GetY() and x == e.self:GetX() ) then
			-- try to avoid stacking
			x, y, z = GetRandomOrcSpawnLoc();
		end
		
		--eq.debug("duplicate "..e.self:GetName().." spawned at "..x..", "..y..", "..z);
		local duplicate = eq.spawn2(e.self:GetNPCTypeID(), 14, 0, x, y, z, 0);
		duplicate:CastToNPC():PauseWandering(45);
	end
end

function GetRandomGnollSpawnLoc(t)
	local rng = (math.random(1, (#t - 9)/3) - 1) * 3;
	local x, y, z = t[rng+1], t[rng+2], t[rng+3];

	if ( y < 430 or x > 200 or x < 70 ) then
		errorCount = errorCount + 1;
		if ( errorCount < 10 ) then
			eq.debug("Error with the gnoll script: invalid gnoll spawn loc.  ("..x..", "..y..", "..z..")");
		end
		return 92.00, 462.00, 29.10;
	end
	return x, y, z;
end

function GetGnollCount()
	local npcList = eq.get_entity_list():GetNPCList();
	local count = 0;
	
	if ( npcList ) then
		for npc in npcList.entries do
			if ( npc.valid ) then
				local i = 1;
				while ( GNOLL_TYPES[i] ) do
					if ( GNOLL_TYPES[i] == npc:GetNPCTypeID() ) then
						count = count + 1;
					end
					i = i + 1;
				end
			end
		end
	end
	return count;
end

-- this adds a new grid to the NPC.  It will move to a location under the ramp then we'll add a grid from the database
function GnollSpawnEvent(e)
	if ( e.self:GetY() < 435 ) then
		return; -- sanity check
	end
	e.self:RemoveWaypoints();	-- remove spawnpoint grid which is only used to randomize their spawn locations
	e.self:SetWanderType(0);	-- circular
	e.self:SetPauseType(1);		-- full duration
	e.self:AddWaypoint(e.self:GetX(), e.self:GetY(), e.self:GetZ(), -1, 0, false);	-- the server ignores the first waypoint for whatever reason
	e.self:AddWaypoint(e.self:GetX(), e.self:GetY(), e.self:GetZ(), -1, 45, false);	-- gnolls and orcs loiter for 45s before moving

	local i, t = GetClosestGnollLoc(e.self);
	while (t[i]) do
		if ( t[i+2] < 25 or t[i] < 100 ) then	-- this will exclude the southernmost two gnoll spawnpoints; we don't want them pathing to these
			e.self:AddWaypoint(t[i], t[i+1], t[i+2], -1, 0, false);
			--eq.debug(e.self:GetName().." waypoint added "..t[i].." "..t[i+1].." "..t[i+2]);
		end
		i = i + 3;
	end
	
	if ( not GNOLL_DUPE_GROUPS[e.self:GetSp2()] ) then
		--eq.debug("refusing to duplicate a duplicate; current gnoll count == "..GetGnollCount());
		return;
	end
	
	if ( math.random(6) == 1 and #t > 12 and GetGnollCount() < 8 ) then  -- 1 in 6 chance.  idle zones will spawn endless gnolls so we check gnoll count
	
		local x, y, z = GetRandomGnollSpawnLoc(t);

		if ( y == e.self:GetY() and x == e.self:GetX() ) then
			x, y, z = GetRandomGnollSpawnLoc(t);
		end
		
		--eq.debug("duplicate "..e.self:GetName().." spawned at "..x..", "..y..", "..z);
		local duplicate = eq.spawn2(e.self:GetNPCTypeID(), 0, 0, x, y, z, 0);
	end
end

function GnollWaypointArrive(e)
	if ( e.wp == (e.self:GetMaxWp() - 1) and e.self:GetY() > 300 and e.self:GetY() < 450 ) then
		e.self:RemoveWaypoints();
		e.self:AssignWaypoints(23);
	end
end

-- this won't work in event_encounter_load() seemingly because it executes before spawns load
function event_timer(e)
	if ( e.timer ~= "getlocs" ) then
		return;
	end
	
	local spawnList = eq.get_entity_list():GetSpawnList();
	for spawn in spawnList.entries do
		if ( spawn:SpawnGroupID() == ORC_SPAWNGROUPID ) then
			table.insert(orcLocs, spawn:GetX());
			table.insert(orcLocs, spawn:GetY());
			table.insert(orcLocs, spawn:GetZ());
			--eq.debug("orc spawn loc x,y: "..spawn:GetX().." "..spawn:GetY().." "..spawn:GetZ());
		end
	end
	eq.stop_timer(e.timer);
end

function event_encounter_load(e)

	for _, id in ipairs(ORC_TYPES) do
		eq.register_npc_event("OrcGnollSpawns", Event.spawn, id, OrcSpawnEvent);
	end
	for _, id in ipairs(GNOLL_TYPES) do
		eq.register_npc_event("OrcGnollSpawns", Event.spawn, id, GnollSpawnEvent);
		eq.register_npc_event("OrcGnollSpawns", Event.waypoint_arrive, id, GnollWaypointArrive);
	end

	eq.set_timer("getlocs", 3000);
end
