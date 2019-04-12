//*** DESCRIPTION

/
Handler library for 
\

//*** COMMAND LINE PARAMS

// params:.Q.def[enlist[`date]!enlist .z.D-1].Q.opt .z.x;

//*** REQUIRED SCRIPTS
\l utilities.q

//*** HANDLES

//*** GLOBAL VARS
.conn.HANDLES:([service:`symbol$()]handle:`int$();initTime:`timestamp$();active:`boolean$());
.conn.REGISTER:("SSSISIS";enlist ",")0:`connections.csv;

// *** FUNCTIONS

.conn.execute:{[h;query]
    @[h;query;{.log.info("Query failed:";`handle`query`error!(h;query;x));x}[h;query;]]
    }

.conn.hopen:{[handle;tmout]
    $[not null tmout;
        .[hopen;(handle;tmout);{'FailOnConnectTimeout}];
        @[hopen;handle;{'FailOnConnect}]
        ]
    }

.conn.connect:{[svc;conn]
    h:$[(conn[`encrypt]~`tls)&(.z.K>=3.4);
        .util.hopen[`$":tcps://",":" sv .util.string conn[`host`port];0n];
        (conn[`host] in (`localhost;.z.h))&(.z.o in `m64`l64)&(.z.K>=3.4);
            .conn.hopen[hsym `$"unix://",.util.string conn[`port];0n];
            .conn.hopen[hsym `$":" sv .util.string conn[`host`port];0n]
            ];
    .conn.HANDLES[svc]:(h;.z.P;1b);
    h
    }

.conn.getHandle:{[callback;conn]
    status:.conn.HANDLES[svc:` sv .util.symbol conn[`cluster`service`app`node]];
    handle:$[(null status[`handle])|(0b=status[`active]);
        .conn.connect[svc;conn];
        status[`handle]
        ];
    $[callback~`sync;
        abs handle;
        handle<0;
            handle;
            neg[handle]
    ]
    }

.conn.chkSvcName:{[svc]
    c:` vs svc;
    if[not count[c] in 3 4;'ServiceNameWrongLength];
    if[0=count select i from .conn.REGISTER where cluster=c[0],service=c[1],app=c[2];
        'ServiceNotAvailable];
    c
    }

.conn.findService:{[svc]
    $[3=count c:.conn.chkSvcName[svc];
        first select from .conn.REGISTER where cluster=c[0],service=c[1],app=c[2];
        first select from .conn.REGISTER where where cluster=c[0],service=c[1],app=c[2],node=c[3];
        ]
    }

.conn.async:{[svc;query]
    h:.conn.getHandle[`async;.conn.findService[svc]];
    .conn.execute[h;query]
    }

.conn.sync:{[svc;query]
    h:.conn.getHandle[`sync;.conn.findService[svc]];
    .conn.execute[h;query]
    }
