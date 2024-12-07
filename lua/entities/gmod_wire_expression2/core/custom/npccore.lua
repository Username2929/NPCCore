-- Register the extension
E2Lib.RegisterExtension("npccore", true)

NPCCORE = NPCCORE or {}

-- Define CVars for NPC spawning
NPCCORE.CVARS = {
    NPC_ENABLED = CreateConVar("npccore_enabled", "1", FCVAR_ARCHIVE, "Allow E2 to spawn NPCs", 0, 1),
    NPC_MAXHEALTH = CreateConVar("npccore_maxhealth", "100", FCVAR_ARCHIVE, "Maximum health NPCs can have (set to -1 for no limit)"),
    NPC_DELAY = CreateConVar("npccore_delay", "1", FCVAR_ARCHIVE, "Minimum time between NPC spawns"),
    NPC_LIMIT = CreateConVar("npccore_limit", "5", FCVAR_ARCHIVE, "Maximum number of NPCs a player can spawn"),
}

NPCCORE.NPC_ENABLED = NPCCORE.CVARS.NPC_ENABLED:GetBool()
NPCCORE.NPC_MAXHEALTH = NPCCORE.CVARS.NPC_MAXHEALTH:GetInt()
NPCCORE.NPC_DELAY = NPCCORE.CVARS.NPC_DELAY:GetFloat()
NPCCORE.NPC_LIMIT = NPCCORE.CVARS.NPC_LIMIT:GetInt()

-- Track spawned NPCs
NPCCORE.SpawnedNPCs = NPCCORE.SpawnedNPCs or {}

-- Function to spawn NPC
function NPCCORE.SpawnNPC(owner, npcClass, pos, health)
    if not NPCCORE.NPC_ENABLED then
        owner:ChatPrint("NPC spawning is disabled!")
        return
    end

    local count = NPCCORE.SpawnedNPCs[owner] and #NPCCORE.SpawnedNPCs[owner] or 0
    if count >= NPCCORE.NPC_LIMIT then
        owner:ChatPrint("Set NPC spawn limit was reached. Kill or delete some npcs to fix this.")
        return
    end

    local maxHealth = NPCCORE.NPC_MAXHEALTH
    if maxHealth > 0 and health > maxHealth then
        health = maxHealth
    end

    local npc = ents.Create(npcClass)
    if not IsValid(npc) then
        owner:ChatPrint("Invalid NPC class!")
        return
    end

    npc:SetPos(pos)
    npc:SetKeyValue("spawnflags", "256") -- Prevent default weapons
    npc:Spawn()
    npc:SetHealth(health)

    -- Track the NPC
    NPCCORE.SpawnedNPCs[owner] = NPCCORE.SpawnedNPCs[owner] or {}
    table.insert(NPCCORE.SpawnedNPCs[owner], npc)

    -- Cleanup when the NPC is removed
    npc:CallOnRemove("NPCCORE_RemoveNPC", function(ent)
        for k, v in ipairs(NPCCORE.SpawnedNPCs[owner] or {}) do
            if v == ent then
                table.remove(NPCCORE.SpawnedNPCs[owner], k)
                break
            end
        end
    end)
end

-- E2 function to spawn NPC
__e2setcost(50) -- Cost of the function
e2function void spawnNPC(string npcClass, vector pos, number health)
    if not NPCCORE.NPC_ENABLED then return end
    local owner = self.player

    -- Rate limiting (delay)
    if not self.npcNextSpawn or self.npcNextSpawn < CurTime() then
        self.npcNextSpawn = CurTime() + NPCCORE.NPC_DELAY
    else
        owner:ChatPrint("Wait until spawning another npc. ")
        return
    end

    local position = Vector(pos[1], pos[2], pos[3])
    NPCCORE.SpawnNPC(owner, npcClass, position, health)
end
