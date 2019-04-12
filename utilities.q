//*** DESCRIPTION

/
Simple helper functions for kdb usage
\

//*** COMMAND LINE PARAMS

// params:.Q.def[enlist[`date]!enlist .z.D-1].Q.opt .z.x;

//*** REQUIRED SCRIPTS

//*** HANDLES

//*** GLOBAL VARS

// *** FUNCTIONS
.util.nlist:{
    $[0<type x;
        enlist x;
        x
        ]
    }

.util.string:{
    $[10h~abs type x;
        x;
        string x]
    }

.util.symbol:{
    $[11h~abs type x;
        x;
        `$.util.string x
        ]
    }
//*** RUNNER
