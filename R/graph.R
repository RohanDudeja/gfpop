##  GPL-3 License
## Copyright (c) 2019 Vincent Runge

#' Edge generation
#'
#' @description Edge creation for graph
#' @param state1 a string defining the starting state of the edge
#' @param state2 a string defining the ending state of the edge
#' @param type a string equal to "null", "std", "up", "down" or "abs"
#' @param decay a nonnegative number to give the strength of the exponential decay into the segment
#' @param gap a nonnegative number to constrain the size of the gap in the change of state
#' @param penalty a nonnegative number. The penality associated to this state transition
#' @param K a positive number. Threshold for the Biweight robust loss
#' @param a a positive number. Slope for the Huber robust loss
#' @return a one-row dataframe with 9 variables
#' @examples
#' Edge("Dw", "Up", "up", gap = 1, penalty = 10, K = 3)
Edge <- function(state1, state2, type = "null", decay = 1, gap = 0, penalty = 0, K = Inf, a = 0)
{
  allowed.types <- c("null", "std", "up", "down", "abs", "start", "end")
  if(!type %in% allowed.types){
    stop(
      'type must be one of: ',
      paste(allowed.types, collapse=", "))
  }
  if(!is.double(penalty)){stop('penalty is not a double.')}
  if(!is.double(decay)){stop('decay is not a double.')}
  if(!is.double(gap)){stop('gap is not a double.')}
  if(!is.double(penalty)){stop('penalty is not a double.')}
  if(!is.double(K)){stop('K is not a double.')}
  if(!is.double(a)){stop('a is not a double.')}
  if(any(penalty < 0, na.rm=TRUE)){stop('penalty must be nonnegative')}
  if(any(decay < 0, na.rm=TRUE)){stop('decay must be nonnegative')}
  if(any(type == "null" && decay == 0, na.rm=TRUE))stop(
    'decay must be non-zero')
  if(any(gap < 0, na.rm=TRUE)){stop('gap must be nonnegative')}
  if(any(K <= 0, na.rm=TRUE)){stop('K must be positive')}
  if(any(a < 0, na.rm=TRUE)){stop('a must be nonnegative')}
  if(type == "null"){parameter <- decay}else{parameter <- gap}
  data.frame(
    state1, state2, type, penalty, parameter, K, a,
    min=NA, max=NA, stringsAsFactors = FALSE)
}


###############################################

#' Start and End nodes for the graph
#'
#' @description Defining the beginning and ending states of a graph
#' @param start a vector of states. The beginning nodes for the changepoint inference
#' @param end a vector of states. The ending nodes for the changepoint inference
#' @return dataframe with 9 variables with only `state1` and `type` = start or end defined.
#' @examples
#' StartEnd(start = "A", end = c("A","B"))

StartEnd <- function(start = NULL, end = NULL)
{
  ### delete repetitions if any
  start <- unique(start)
  end <- unique(end)
  rbind(
    Edge(start, NA, "start", decay=NA_real_, gap=NA_real_, penalty=NA_real_, K=NA_real_, a=NA_real_),
    Edge(end, NA, "end", decay=NA_real_, gap=NA_real_, penalty=NA_real_, K=NA_real_, a=NA_real_))
}


###############################################

#' Node Values
#'
#' @description Constrain the range of values to consider at a node
#' @param state a string defining the state to constrain
#' @param min minimal value for the inferred parameter
#' @param max maximal value for the inferred parameter
#' @return a dataframe with 9 variables with only `state1`, `min` and `max` defined.
#' @examples
#' Node(state = "S", min = 0, max = 2)

Node <- function(state = NULL, min = -Inf, max = Inf)
{
  ############
  ### STOP ###
  ############
  if(!is.double(min)){stop('max is not a double.')}
  if(!is.double(max)){stop('min is not a double.')}
  if(min > max){stop('min is greater than max')}

  df <- data.frame(character(), character(), character(), numeric(0), numeric(0), numeric(0), numeric(0), numeric(0), numeric(0), stringsAsFactors = FALSE)
  colnames(df) <- c("state1", "state2", "type", "parameter", "penalty", "K", "a", "min", "max")
  df [1,] <- data.frame(state, state, "node", NA, NA, NA, NA, min, max, stringsAsFactors = FALSE)
  return(df)
}


###############################################

#' Graph generation
#'
#' @description Graph creation using component functions "Edge", "StartEnd" and "Node"
#' @param ... This is a list of edges definied by functions "Edge", "StartEnd" and "Node"
#' @param type a string equal to "std", "isotonic", "updown", "relevant". to build a predefined classic graph
#' @param decay a nonnegative number to give the strength of the exponential decay into the segment
#' @param gap a nonnegative number to constrain the size of the gap in the change of state
#' @param penalty a nonnegative number equals to the common penalty to use for all edges
#' @param K a positive number. Threshold for the Biweight robust loss
#' @param a a positive number. Slope for the Huber robust loss
#' @return a dataframe with 9 variables (columns are named "state1", "state2", "type", "parameter", "penalty", "K", "a", "min", "max") with additional "graph" class.
#' @examples
#' UpDownGraph <- graph(type = "updown", gap = 1.3, penalty = 10)
#' MyGraph <- graph(Edge(0,0), Edge(1,1), Edge(0,1,"up", gap = 0.5, penalty = 10),
#' Edge(1,0,"down"), StartEnd(0,0), Node(0,0,1), Node(1,0,1))

graph <- function(..., type = "empty", decay = 1, gap = 0, penalty = 0, K = Inf, a = Inf, all.null.edges=TRUE)
{
  if(!is.double(penalty)){stop('penalty is not a double.')}
  if(penalty < 0){stop('penalty must be nonnegative')}
  myNewGraph <- if(type == "std"){
    Edge("Std", "Std", "std", penalty = penalty, K = K, a = a)
  }else if(type == "isotonic"){
    Edge("Iso", "Iso", "up", gap = gap, penalty = penalty, K = K, a = a)
  }else if(type == "updown"){
    rbind(
      Edge("Dw", "Up", "up", gap = gap, penalty = penalty, K = K, a = a),
      Edge("Up", "Dw", "down", gap = gap, penalty = penalty, K = K, a = a))
  }else if(type == "relevant"){
    Edge("Std", "Std", "abs", gap = gap, penalty = penalty, K = K, a = a)
  }else{#user-provided graph.
    no.edge <- Edge(NA_character_, NA_character_)[0,]
    dots.list <- list(...)
    is.ok <- sapply(dots.list, function(df)identical(names(df), names(no.edge)))
    i.bad <- which(!is.ok)
    if(length(i.bad)){
      stop(
        "please use gfpop::Edge to specify graph, problem arguments: ",
        paste(i.bad, collapse=", "))

    }
    rbind(no.edge, ...)
  }
  not.special <- subset(myNewGraph, ! type %in% c("null", "start", "end"))
  if(isTRUE(all.null.edges) && 0<nrow(not.special)){
    u.states <- with(not.special, unique(c(state1, state2)))
    myNewGraph <- rbind(
      subset(not.special, type != "null"),
      Edge(u.states, u.states, "null", decay=decay))
  }
  class(myNewGraph) <- c("graph", "data.frame")
  myNewGraph
}


###############################################
###############################################
###############################################
# invisible function for the user
#Order the graph and create integer state values


###############################################
# invisible function for the user

typeOfGraph <- function(mygraph)
{
  return("gfpop")
}


###############################################

graphReorder <- function(mygraph)
{
  ### BUILD an ordered Graph : myOrderedGraph ###
  ##separate start, end, node from vertices
  graphNA <- mygraph[is.na(mygraph[,5]),] ## Start End nodes and range values nodes
  graphVtemp <-  mygraph[!is.na(mygraph[,5]),] ## Edges of the graph
  myVertices <- unique(c(graphVtemp[,1], graphVtemp[,2]))

  if(!all(is.element(mygraph[is.na(mygraph[,5]), 1], myVertices))){stop("Some start-end-node names not related to edges")}

  ###transform the abs edge into two edges (up and down)
  absEdge <- graphVtemp[,3] == "abs"

  if(!all(absEdge == FALSE))
  {
    graphVtemp[absEdge,3] <- "down"
    addToGraphVV <- graphVtemp[absEdge,]
    addToGraphVV[,3] <- "up"
    graphV <- rbind(graphVtemp, addToGraphVV)
  }else
  {
    graphV <- graphVtemp
  }

  ##create a new graph
  myNewGraph <- graph()
  selectNull <- graphV[, 3] == "null" ### => penalty = 0
  graphV[selectNull, 5] <- -1 #set penalty to -1

  for(vertex in myVertices)
  {
    selectRaw <- graphV[graphV[,2]==vertex, ]
    ordre <- order(selectRaw[,5])
    selectRaw <- selectRaw[ordre,]
    myNewGraph <- rbind(myNewGraph, selectRaw)
  }

  myNewGraph <- rbind(myNewGraph, graphNA)
  selectNull <- myNewGraph[, 3] == "null"
  myNewGraph[selectNull, 5] <- 0 #for ordering

  ###Label the vertices with integers from 0 to nbVertices
  for(i in 1:dim(myNewGraph)[1])
  {
    myNewGraph[i,1] <- which(myNewGraph[i,1] == myVertices) - 1
    if(!is.na(myNewGraph[i,2])){myNewGraph[i,2] <- which(myNewGraph[i,2] == myVertices) - 1}
  }

  class(myNewGraph$state1) <- "numeric"
  class(myNewGraph$state2) <- "numeric"

  list(graph = myNewGraph, vertices = myVertices)
}



###############################################
# invisible function for the user
# to use after graphAnalysis and test whether the graph can be used in the gfpop function

explore <- function(mygraph)
{
  graph <- mygraph$graph
  graph[,1] <- graph[,1] + 1
  graph[,2] <- graph[,2] + 1 ### states from 1 to nbState
  len <- length(mygraph$vertices)

  theStart <- graph[graph[,3] == "start", 1]
  theEnd <- graph[graph[,3] == "end", 1]
  if(length(theStart) == 0){theStart <- 1:len}
  if(length(theEnd) == 0){theEnd <- 1:len}

  recNodes <- graph[which(graph$state1 == graph$state2),]$state1 ### recursive nodes
  seenNodes <- NULL

  for(i in 1:len)
  {
    Vi <- visit(graph, i)
    if(length(intersect(Vi,theEnd)) == 0){stop('Not all nodes lead to an end node')}

    if(i %in% theStart && length(intersect(Vi,recNodes)) == 0){stop('Not all path have a recursive edge')}
    if(i %in% theStart){seenNodes <- c(seenNodes, Vi)}
  }
  seenNodes <- sort(unique(seenNodes))
  if(length(seenNodes) != len){stop('One or more nodes is/are not seen by the algorithm')}
}



###############################################

visit <- function(graph, startNode)
{
  visited <- NULL
  toVisit <- c(startNode)
  while(length(toVisit) > 0)
  {
    visited <- c(visited, toVisit[1]) #we visit toVisit[1]
    newToVisit <- graph[graph[,1] == toVisit[1], 2] #to visit from toVisit[1]
    newToVisit <- newToVisit[!is.na(newToVisit)] #remove NA
    newToVisit <- setdiff(newToVisit, visited)
    newToVisit <- setdiff(newToVisit, toVisit)
    toVisit <- toVisit[-1] #we remove toVisit[1] in node to visit
    toVisit <- c(newToVisit, toVisit)
  }
  return(visited)
}
