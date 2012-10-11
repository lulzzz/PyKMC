# Fredrickson Andersen (FA) Model 
# Original Source:
#     G. H. Fredrickson and H. C. Andersen
#     Kinetic Ising Model of the Glass Transition. PRL 53, 1244 (1984).
import numpy as np
cimport numpy as np
changes_per_step = 1
model_name = "FA"

cdef ConstraintI( int site_idx, np.ndarray[np.int_t,ndim=1] configuration, int nsites, np.ndarray[np.int_t,ndim=2] neighbors, int nneighbors_per_site ):
    """ This function gives the FA model 'constraint' 

    Functions adjacent to activations are activated.
    Functions bounded by n active sites are n-fold activated.
    """
    cdef float constraint = 0.0
    cdef int j
    for j in range(nneighbors_per_site):
        constraint = constraint+configuration[neighbors[site_idx,j]]
    return constraint

def AllEvents( float betaexp, np.ndarray[np.int_t,ndim=1] events, np.ndarray[np.float_t,ndim=1] event_rates, np.ndarray[np.int_t,ndim=1] event_refs, np.ndarray[np.int_t,ndim=1] configuration, int nsites, np.ndarray[np.int_t,ndim=2] neighbors, int nneighbors_per_site ):
    """ This function generates the full list of allowed FA moves and their respective rates """
    cdef int i, state_i, n_possible_events
    cdef int j = 0
    cdef float constraint = 0.0
    cdef float event_rate = 0.0
    n_possible_events = 0

    # first clear out rates, and events, just in case
    for j in range(nsites):
        events[j] = 0
        events[j] = 0
        event_rates[j] = 0.0
        event_refs[j] = -1

    for i in range(nsites):
        state_i = configuration[i]
        constraint = ConstraintI( i, configuration, nsites, neighbors, nneighbors_per_site )
        # next line means that if up, flip down and if down, flip up
        # next line is equivalent to
        # rate_{0->1} = e^(-beta) * constraint
        # rate_{1->0} = constraint
        event_rate = (1-state_i)*constraint*betaexp + state_i*constraint
        if( event_rate > 0 ):
            # flip spin i
            events[i] = (1-state_i) 
            # with rate event_rate
            event_rates[i] = event_rate
            # the n'th event is flipping spin i
            event_refs[n_possible_events] = i
            n_possible_events += 1
    return n_possible_events

#def UpdateEventsI( int site_idx, float betaexp, np.ndarray[np.int_t,ndim=2] events, np.ndarray[np.float_t,ndim=1] event_rates, np.ndarray[np.int_t,ndim=1] event_refs, int n_possible_events, np.ndarray[np.int_t,ndim=1] configuration, int nsites, np.ndarray[np.int_t,ndim=2] neighbors, int nneighbors_per_site ):
#    """ This function updates the list of allowed FA moves and their respective rates after an update to site I"""

def UpdateConfiguration( np.ndarray[np.int_t,ndim=1] configuration, np.ndarray[np.int_t,ndim=1] events,np.ndarray[np.int_t,ndim=1] event_refs, int event_i ):
    """ Update configuration based on an event

    Given that event 'event_i' out of 'n_possible_events' is selected by the algorithm elsewhere,
        update the state of the configuration by changing the state referred to by events[event_i,0]
        to the final state referred to by events[event_i,1]
    """
    cdef int change_idx = event_refs[event_i]
    cdef int result = events[change_idx]
    configuration[change_idx] = result
