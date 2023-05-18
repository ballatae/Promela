#define liquid 1 // a bit

mtype = {on, off, open, close, status_query, status_query_ack, filled, notfilled, filling, req_filling,req_filling_ack, filling_ack, ready};


//mtype system = on;
//when a channel has size of 0,
//the sender and receiver must be ready and waiting at the channel at the same time
//for communication to occur
//zero-buffered channel 
chan Vessel = [2] of {bit};
chan InValveToInController =  [0] of {mtype};
chan InValveFromInController = [0] of {mtype};
chan OutValveToOutController = [0] of {mtype};
chan OutValveFromOutController = [0] of {mtype};
chan InControllerToOutController = [0] of {mtype};
chan OutControllerToInController = [0] of {mtype};
chan StatusOfVessel = [0] of {mtype};


proctype InValve(chan outflow, ValveFromController, ValveToController){
    mtype action = close;
    do
    :: ValveToController!liquid
    :: ValveFromController?open -> outflow!liquid -> ValveFromController?close
    od
}

proctype InController(chan ValveToController,ValveFromController,ControllerToController1,ControllerToController2,StatusVessel) {
    mtype system = on;
    mtype message,valve_status;
    do
    :: (system == on) -> ValveToController?valve_status -> system = off -> ValveToController!status_query
    :: ControllerToController2?message -> if
                                                :: (message == status_query_ack) -> StatusVessel?notfilled -> ControllerToController1!req_filling
                                                :: (message == req_filling_ack) -> StatusVessel?ready -> ValveFromController!open -> ControllerToController1!filling
                                                :: (message == filling_ack) -> StatusVessel?filled -> ValveFromController?close -> StatusVessel!notfilled -> system = on
                                            fi;
    od
}

proctype OutValve(chan ValveToController,ValveFromController,inflow) {
    do
    :: inflow?liquid -> ValveToController!liquid ->ValveFromController?close
    :: ValveFromController?open
    od
}
proctype OutController(chan ValveToController,ValveFromController,ControllerToController1,ControllerToController2,StatusVessel) {
    mtype system = on;
    mtype message,valve_status;
    do
    :: (system == on) -> ValveToController?valve_status -> system = off -> ValveToController!close
    :: ControllerToController1?message -> if
                                                :: (message == status_query) -> ControllerToController2!status_query_ack -> StatusVessel!notfilled
                                                :: (message == req_filling) -> ControllerToController2!req_filling_ack -> StatusVessel!ready -> ValveFromController!close
                                                :: (message == filling) -> ControllerToController2!filling_ack -> StatusVessel!filled -> ValveFromController!open -> system = on
                                            fi;
    od
}
init {
    atomic {
        run InValve(InValveFromInController,InValveToInController,Vessel);
        run InController(InValveToInController,InValveFromInController,InControllerToOutController,OutControllerToInController,StatusOfVessel);
        run OutValve(OutValveToOutController,OutValveFromOutController,Vessel);
        run OutController(OutValveToOutController,OutValveFromOutController,InControllerToOutController,OutControllerToInController,StatusOfVessel);
    }
}