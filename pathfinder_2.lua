function table.copy(oldTable)
	local newTable = {}
	for a,b in pairs(oldTable) do
		newTable[a] = b
	end
	return newTable
end

worldManager = {}
function worldManager.initialize()
	worldManager.gaseous = {"Air","Torch","Grass","Flower","Mushroom","Dead Bush","Oak Sapling"} --can walk through
	worldManager.liquid = {"Water","Lava"} --DON'T STAND ON THIS, DON'T GO THROUGH THIS
	if(not worldManager.blockSave) then
		worldManager.blockSave = {}
	end
	
	
	
	
	for a,b in pairs(worldManager.gaseous) do
		if(a==1) then
			worldManager.gaseous = {}
		end
		worldManager.gaseous[b] = true	
	end
	for a,b in pairs(worldManager.liquid) do
		if(a==1) then
			worldManager.liquid = {}
		end
		worldManager.liquid[b] = true	
	end
end
--everything else is considered solid

function worldManager.getBlock(loc)
	if(not worldManager.blockSave[loc[1]]) then
		worldManager.blockSave[loc[1]] = {}
	end
	if(not worldManager.blockSave[loc[1]][loc[2]]) then
		worldManager.blockSave[loc[1]][loc[2]]= {}
	end
	if(not worldManager.blockSave[loc[1]][loc[2]][loc[3]]) then
		local block = getBlock(loc[1],loc[2],loc[3])
		if(not block) then 
		return false 
		end --not in render distance
		local blockType = 1--solid
		if(worldManager.liquid[block.name]) then
			blockType = 2
		elseif(worldManager.gaseous[block.name]) then
			blockType = 0
		end
		worldManager.blockSave[loc[1]][loc[2]][loc[3]] = blockType
	end
	return worldManager.blockSave[loc[1]][loc[2]][loc[3]]

end
worldManager.initialize()
















pathfinder = {}
function createNode(x,y,z)
	local createdNode = {}--form x,y,z,totalcost,past cost,future cost
	
	return createdNode
end
function pathfinder.hCost(start)
	return math.sqrt((start[1]-pathfinder.destination[1])*(start[1]-pathfinder.destination[1])+(start[2]-pathfinder.destination[2])*(start[2]-pathfinder.destination[2])+(start[3]-pathfinder.destination[3])*(start[3]-pathfinder.destination[3]))

end
function pathfinder.saveNode(storage,node)
	if(not storage[node[1]]) then
		storage[node[1]] = {}
	end
	if(not storage[node[1]][node[2]]) then
		--log(node[1], " ", node[2], " ", node[3])
		--IDK what to do about this one
		storage[node[1]][node[2]] = {}
	end
	local values = {}
	values.hCost = node.hCost
	values.fCost = node.fCost
	values.parent = node.parent
	storage[node[1]][node[2]][node[3]] = values
end
function pathfinder.removeNode(storage,node)
	--these checks can probably be removed!
	storage[node[1]][node[2]][node[3]] = nil
	--remove y if empty
	if(not pathfinder.isEmpty(storage[node[1]][node[2]])) then
		return
	end
	storage[node[1]][node[2]] = nil
	if(not pathfinder.isEmpty(storage[node[1]])) then
		return
	end
	storage[node[1]] = nil
end
function pathfinder.hasNode(storage,node)
	if(not storage[node[1]]) then
		return false
	end
	if(not storage[node[1]][node[2]]) then
		return false
	end
	if(not storage[node[1]][node[2]][node[3]]) then return false end
	return true
end
function pathfinder.lowestNode(storage)
	local lowestCost = 100000000
	local lowestNode
	for xCord,xTable in pairs(storage) do
		for yCord,yTable in pairs(xTable) do
			for zCord,values in pairs(yTable) do
				if(lowestCost>values.hCost+values.fCost) then 
					lowestCost = values.hCost+values.fCost
					lowestNode = {xCord,yCord,zCord}
					lowestNode.fCost = values.fCost
					lowestNode.parent = values.parent
					lowestNode.hCost = values.hCost
				end	
			end
		end
	end
	return lowestNode
end
function pathfinder.isEmpty(storage)
	local isEmpty = true
	for a,b in pairs(storage) do
		isEmpty = false
		break
	end
	return isEmpty
end



pathfinder.move={}
function pathfinder.move.applyTransformation(object,transformation)
	for i=1,3 do
		if(transformation[i]and transformation[i]~=0) then	
			object[i] = object[i]+transformation[i]
		end
	end
end
function pathfinder.move.checkBlockType(loc,transformation,checkType)
	local loc = table.copy(loc)--we don't want to modify the original location.
	--apply transformation
	pathfinder.move.applyTransformation(loc,transformation)
	local isType = worldManager.getBlock(loc)
	if(isType==checkType) then return true else return false end
end
function pathfinder.move.walk(currentNode,x,z)
	local potentialNode = {currentNode[1],currentNode[2],currentNode[3]}
	if(pathfinder.move.checkBlockType(potentialNode, {x,-1,z}, 1) --ground is solid
		and pathfinder.move.checkBlockType(potentialNode, {x,0,z}, 0) --feet space is air
		and pathfinder.move.checkBlockType(potentialNode, {x,1,z}, 0) --head space is air
		) then
		--log(potentialNode)
		pathfinder.move.applyTransformation(potentialNode, {x,0,z})
		--log(potentialNode)
		potentialNode.fCost = 1
		return(potentialNode)
	end
	return nil
end
function pathfinder.move.jump(currentNode,x,z)
	local potentialNode = {currentNode[1],currentNode[2],currentNode[3]}
	if(pathfinder.move.checkBlockType(potentialNode, {x,0,z}, 1) --ground is solid
		and pathfinder.move.checkBlockType(potentialNode, {x,1,z}, 0) --feet space is air
		and pathfinder.move.checkBlockType(potentialNode, {x,2,z}, 0) --head space is air
		and pathfinder.move.checkBlockType(potentialNode, {0,2,0}, 0)
		) then
		--log(potentialNode)
		pathfinder.move.applyTransformation(potentialNode, {x,1,z})
		--log(potentialNode)
		potentialNode.fCost = 4
		return(potentialNode)
	end
	return nil
end
function pathfinder.move.fall(currentNode,x,z)
	local potentialNode = {currentNode[1],currentNode[2],currentNode[3]}
	if(pathfinder.move.checkBlockType(potentialNode, {x,-2,z}, 1) --ground is  solid
		and pathfinder.move.checkBlockType(potentialNode, {x,-1,z}, 0) --fall is air
		and pathfinder.move.checkBlockType(potentialNode, {x,0,z}, 0) --feet space is air
		and pathfinder.move.checkBlockType(potentialNode, {x,1,z}, 0) --head space is air
		) then
		--log(potentialNode)
		pathfinder.move.applyTransformation(potentialNode, {x,-1,z})
		--log(potentialNode)
		potentialNode.fCost = 1.5
		return(potentialNode)
	end
	return nil
end
function pathfinder.successors(currentNode)
	local successors = {}
	table.insert(successors, pathfinder.move.walk(currentNode,1,0))
	table.insert(successors, pathfinder.move.walk(currentNode,-1,0))
	table.insert(successors, pathfinder.move.walk(currentNode,0,1))
	table.insert(successors, pathfinder.move.walk(currentNode,0,-1))
	
	table.insert(successors, pathfinder.move.jump(currentNode,1,0))
	table.insert(successors, pathfinder.move.jump(currentNode,-1,0))
	table.insert(successors, pathfinder.move.jump(currentNode,0,1))
	table.insert(successors, pathfinder.move.jump(currentNode,0,-1))
	
	table.insert(successors, pathfinder.move.fall(currentNode,1,0))
	table.insert(successors, pathfinder.move.fall(currentNode,-1,0))
	table.insert(successors, pathfinder.move.fall(currentNode,0,1))
	table.insert(successors, pathfinder.move.fall(currentNode,0,-1))
	
	--stopAllScripts()
	return successors
end


















function pathfinder.start()
	pathfinder.destination = {-17,66,170}
	local x,y,z = getPlayerBlockPos()
	local startPosition = {}
	startPosition[1] = x
	startPosition[2] = y
	startPosition[3] = z
	startPosition.fCost = 0
	startPosition.hCost = pathfinder.hCost(startPosition)
	--position format is 1=x,2=y,3=z,parent=previousPosition,hCost=(distance left),fCost=distance traveled
	local OPEN = {} --three layers of table, x,y,z -> hCost and fCost
	pathfinder.saveNode(OPEN,startPosition)
	local CLOSED = {}
	
	local currentNode
	local currentNodeIndex
	local foundPath = false
	while not pathfinder.isEmpty(OPEN) do
		--get lowest cost node
		currentNode = pathfinder.lowestNode(OPEN)
		--display
		local hb = hud3D.newBlock(currentNode[1], currentNode[2], currentNode[3])
		hb.enableDraw()
		--sleep(30)
		--stop if at destination
		if(currentNode[1]==pathfinder.destination[1] and currentNode[2]==pathfinder.destination[2] and currentNode[3]==pathfinder.destination[3]) then
			pathfinder.saveNode(CLOSED,currentNode)
			pathfinder.removeNode(OPEN,currentNode)
			foundPath = true
			break
		end
		
		local successors = pathfinder.successors(currentNode)
		for a,successor in pairs(successors) do
			--save values
			successor.parent = {currentNode[1],currentNode[2],currentNode[3]}
			successor.hCost = pathfinder.hCost(successor)
			successor.fCost = currentNode.fCost+successor.fCost
			--if node is open
			if(pathfinder.hasNode(OPEN,successor)) then
				--better route already exists
				if(OPEN[successor[1]][successor[2]][successor[3]].fCost+OPEN[successor[1]][successor[2]][successor[3]].hCost<successor.fCost+successor.hCost) then
					goto continue
				end
			-- node is closed
			elseif(pathfinder.hasNode(CLOSED,successor)) then
				--better path to node already exists
				if(CLOSED[successor[1]][successor[2]][successor[3]].fCost+CLOSED[successor[1]][successor[2]][successor[3]].hCost<successor.fCost+successor.hCost) then
					goto continue
				end
				
				--log("------------------")
				--log(CLOSED[successor[1]][successor[2]][successor[3]])
				--log(successor)
				pathfinder.removeNode(CLOSED,successor)
				pathfinder.saveNode(OPEN,successor)
			end
			pathfinder.saveNode(OPEN,successor)
			::continue::
		end
		pathfinder.saveNode(CLOSED,currentNode)
		pathfinder.removeNode(OPEN,currentNode)
		--[[
		currentNode = getLowestCostNode()
		at destination:
			break
		
		get movement options from node
		for each movement option:
			
			
			
			
		add node to closedNodes
		remove node from openNodes
		==]]
	
	end
	--construct final path
	--stopAllScripts()
	if(foundPath) then
		local finalPath = {}
		
		while currentNode do
			table.insert(finalPath,currentNode)
			
			currentNode = CLOSED[currentNode[1]][currentNode[2]][currentNode[3]].parent
		end
		--highlight path
		
		hud3D.clearAll()
		for a,b in pairs(finalPath) do
			local hb = hud3D.newBlock(b[1], b[2], b[3])
			hb.enableDraw()
		end
	else
		log("&cNo path")
	end
end
start = os.time()
hud3D.clearAll()
pathfinder.start()
log("took: ",os.time()-start)
--[[
it breaks at
214,6,174

--]]




