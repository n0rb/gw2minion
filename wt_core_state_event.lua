-- The Event State
-- Looking for Dynamic Events on the mesh

-- We inherit from wt_core_state, which gives us: function wt_core_state:run(), function wt_core_state:add( kelement ) and function wt_core_state:register()
wt_core_state_event = inheritsFrom(wt_core_state)
wt_core_state_event.name = "Eventing"
wt_core_state_event.kelement_list = { }
--wt_core_state_event.repaired = false 
--wt_core_state_event.repaircount = 0

--wt_global_information.nextEvent = 0


-- Search for Events
local c_eventsearch = inheritsFrom(wt_cause)
local e_eventsearch = inheritsFrom(wt_effect)



wt_core_state_event.dynamicevents =  {}
wt_core_state_event.dynamicevents[1] = "Event"
wt_core_state_event.dynamicevents[6] = "Eventdefend" -- follow and protect to 27
wt_core_state_event.dynamicevents[91] = "Eventprotect"
wt_core_state_event.dynamicevents[68] = "Eventprotect"
-- wt_core_state_event.dynamicevents[69] = "EventStartCharacter" -- need to implent start procedure
wt_core_state_event.dynamicevents[145] = "EventProtectTarget"
wt_core_state_event.dynamicevents[99] = "Eventdefend"
wt_core_state_event.dynamicevents[92] = "Eventdefend"
wt_core_state_event.dynamicevents[109] = "EventProtect" -- belongs to 145
wt_core_state_event.dynamicevents[108] = "Eventprevent"
--zzj.dynamicevents[27] = "EventFollowEnd",
-- wt_core_state_event.dynamicevents[138] = "EventKill"
-- zzj.dynamicevents[70] = "KillEventTarget" -- shows wrong pos if distance>5000

function c_eventsearch:evaluate()
-- and (wt_global_information.Now-wt_global_information.lastEventSearch>wt_global_information.eventSearchPause)
	wt_debug("event eval")
	if (wt_global_information.nextEvent == 0 or wt_global_information.nextEvent == nil) then
		wt_debug("searching event")
		wt_global_information.searchingEvent = 1
		return true
	end
	return false
end



function e_eventsearch:execute()
	if (wt_global_information.nextEvent == 0 or wt_global_information.nextEvent ==  nil) then
		UpdateEvents()
		wt_debug(TableSize(wt_global_information.nextEvent))
		if (wt_global_information.nextEvent ~= 0 and wt_global_information.nextEvent ==  nil) then
			wt_debug("We've found an Event: " .. wt_global_information.nextEvent.type)
		end
	end
	wt_global_information.lastEventSearch = wt_global_information.Now
end


function UpdateEvents()
	if (wt_global_information.nextEvent == nil or wt_global_information.nextEvent == 0) then	
		wt_debug("updating events")
		local ppos = Player.pos
		c_eventsearch.objects = MapObjectList("onmesh")
		if ( TableSize(c_eventsearch.objects) > 0 ) then
			j=1
			eventDistances = {}
			events = {}
			id,object = next(c_eventsearch.objects)
			while(id ~= nil) do
				eventTypeName = wt_core_state_event.dynamicevents[object.type]
				if (eventTypeName ~= nil and eventTypeName ~= "") then
					eventDistances[j] = Distance3D(ppos.x,ppos.y,ppos.z,object.pos.x,object.pos.y,object.pos.z)
					events[j] = object
					j = j+1
				end
				id,object = next(c_eventsearch.objects,id)
			end
				
			eID,eDistance = (max(eventDistances, function(a,b) return a > b end))
			if (eID ~= nil and events[eID] ~= nil and events[eID].type>0) then
				wt_global_information.nextEvent = events[eID]
				return true
			else
				return false
			end
		
			
		else
			wt_global_information.nextEvent = 0
		end
	end
end

-- No Event found - set the lastSearch and switch back to idle state
local c_noevent = inheritsFrom(wt_cause)
local e_noevent = inheritsFrom(wt_effect)

function c_noevent:evaluate()
	if (wt_global_information.nextEvent == 0 and wt_global_information.searchingEvent == 1) then
		return true
	end
	return false
end

function e_noevent:execute()
	wt_debug("Could not find any Events - next Event Search soon ")
	wt_global_information.lastEventSearch = wt_global_information.Now
	wt_global_information.searchingEvent = 0
	wt_global_information.nextEvent = 0
	wt_core_controller.requestStateChange(wt_core_state_idle)
end















-- MoveTo event Cause & Effect
local c_movetoeventcheck = inheritsFrom(wt_cause)
local e_movetoevent = inheritsFrom(wt_effect)

function c_movetoeventcheck:evaluate()
	if (wt_global_information.nextEvent ~= nil and wt_global_information.nextEvent ~= 0) then		
		if (wt_global_information.nextEvent.pos ~= nil) then
			ePos = wt_global_information.nextEvent.pos
			wt_debug("move to event")
			local ppos = Player.pos
			distance =  Distance3D(ePos.x,ePos.y,ePos.z,ppos.x,ppos.y,ppos.z)
			wt_debug("eventdist : "..distance)
			if (distance >= 110) then
				return true	
			end		
		end
	end
	return false
end
e_movetoevent.throttle = 250
function e_movetoevent:execute()
	UpdateEvents()
	if ( wt_global_information.nextEvent ~= nil and wt_global_information.nextEvent ~= 0) then
		wt_debug("MoveToevent.. "..wt_global_information.nextEvent.type)	
		if (wt_global_information.nextEvent.pos ~= nil) then
			ePos = wt_global_information.nextEvent.pos
			wt_debug("actually moving")
			Player:MoveTo(ePos.x,ePos.y,ePos.z,80)
		else
			wt_debug("objectlist bug")
		end
	else 
		wt_global_information.nextEvent = 0
	end
end




-- Open event Cause & Effect
local c_openevent = inheritsFrom(wt_cause)
local e_openevent = inheritsFrom(wt_effect)

function c_openevent:evaluate()	
	if (wt_global_information.nextEvent ~= nil and wt_global_information.nextEvent ~= 0 and wt_global_information.nextEvent.type == 69) then			
		local epos = wt_global_information.nextEvent.pos
		local ppos = Player.pos
		distance =  Distance3D(epos.x,epos.y,epos.z,ppos.x,ppos.y,ppos.z)
		if (distance < 110) then
			Player:StopMoving()
			if( Player:GetTarget() ~= wt_global_information.nextEvent.characterID) then
				Player:SetTarget(wt_global_information.nextEvent.characterID)
			end			
			if ( not Player:IsConversationOpen()) then
				return true	
			end
		end		
	end
	return false
end

e_openevent.throttle = 1000
function e_openevent:execute()
	wt_debug("Opening event.. ")
	c_eventcheck.objects = MapObjectList("onmesh,nearest,type=69")
	if ( TableSize(c_eventcheck.objects) > 0 ) then
		nextEventChar , E  = next(c_eventcheck.objects)		
		if (nextEventChar ~= nil) then
			Player:Interact(E.characterID) 			
		end
	else
		-- failbob
		wt_debug("what the hell where did the event character go?!")
	end
end


-- event procedure:simplest - just switch back to idle mode when we're close

local c_startevent = inheritsFrom(wt_cause)
local e_startevent = inheritsFrom(wt_effect)

function c_startevent:evaluate()
	if (wt_global_information.nextEvent ~= nil and wt_global_information.nextEvent ~= 0) then		
		wt_debug("checking event arrived")
		local epos = wt_global_information.nextEvent.pos
		local ppos = Player.pos
		distance =  Distance3D(epos.x,epos.y,epos.z,ppos.x,ppos.y,ppos.z)
		wt_debug("eventdist : "..distance)
		if (distance <= 110) then
			Player:StopMoving()
			return true	
		end		
	end
	return false
end

function e_startevent:execute()
	wt_debug("we found the event, let's do the normal routine")
	wt_global_information.lastEventSearch = wt_global_information.Now
	wt_global_information.nextEvent = 0
	wt_global_information.searchingEvent = 0
	wt_core_controller.requestStateChange(wt_core_state_idle)
end



function wt_core_state_event:initialize()

	wt_debug("init event")

	local ke_aggro = wt_kelement:create("AggroCheck",c_aggro,e_aggro, 100 )
	wt_core_state_event:add(ke_aggro)
	
	local ke_eventsearch = wt_kelement:create("Eventsearch",c_eventsearch,e_eventsearch,90)
	wt_core_state_event:add(ke_eventsearch)
	
	local ke_noevent = wt_kelement:create("NoEventFound",c_noevent,e_noevent,80)
	wt_core_state_event:add(ke_noevent)
		
	local ke_movetoevent = wt_kelement:create("MoveToEvent",c_movetoeventcheck,e_movetoevent,70)
	wt_core_state_event:add(ke_movetoevent)
	
	-- event type 69 has to start the event first
	--local ke_openevent = wt_kelement:create("OpenEventConversation",c_openevent,e_openevent,69)
	--wt_core_state_event:add(ke_openevent)
	
	--local ke_eventconversation = wt_kelement:create("EventConversation",c_eventconvo,e_eventconvo,68)
	
	
	-- brauche noch ein event over check
	-- am besten schaun ob das event noch in der mapobjectlist ist
	
	local ke_startevent = wt_kelement:create("StartEvent",c_startevent,e_startevent,60)
	wt_core_state_event:add(ke_startevent)
	
end

-- setup kelements for the state
wt_core_state_event:initialize()
-- register the State with the system
wt_core_state_event:register()
















-- helper functions
function max(t, fn)
    if #t == 0 then return nil, nil end
    local key, value = 1, t[1]
    for i = 2, #t do
        if fn(value, t[i]) then
            key, value = i, t[i]
        end
    end
    return key, value
end