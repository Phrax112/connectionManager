//*** DESCRIPTION
/
IPC Handler library for q programming language 

Phrax112@github
g.moynihan2@gmail.com
\

//*** GLOBAL VARS
@[value;`.conn.DIR;{`.conn.DIR set "/" sv -1_"/" vs value[{}]6}];
.conn.HANDLES:([service:`symbol$()]handle:`int$();initTime:`timestamp$();active:`boolean$());
.conn.REGISTER:("SSSISIS";enlist ",")0: hsym `$.conn.DIR,"/connections.csv";

// *** FUNCTIONS

// Execute a query against a remote process
// The svc param is the name of the servce to be queries
// callback specifies if a return is expected i.e sync or async
.conn.execute:{[svc;query;tmout;callback]
    .log.info("Executing";query;"on remote service";svc);
    h:.conn.getHandle[callback;.conn.findService[svc];tmout;query];
    @[h;query;{[h;query;err].log.info("Query failed:";`handle`query`error!(h;query;err))}[h;query;]]
    }

// Wrapper for a connnection open
.conn.hopen:{[handle;tmout]
    .log.info("Initialising connection for:";handle);
    $[tmout>0;
        @[hopen;(handle;tmout);{.log.error("Fail on connect";x);0Ni}];
        @[hopen;handle;{.log.error("Fail on connect";x);0Ni}]
        ]
    }

// Wrapper for a websocket open
.conn.wsOpen:{[host;msg;apiKey;apiSecret]
    conn:(`$":wss://",host);
    request:"GET ",msg," HTTP/1.1\r\nHost: ",host,"\r\n";
    auth:"api-key: ",apiKey,"\r\napi-signature: APISECRET\r\n\r\n";
    .log.info cmd:(conn;request,auth);
    h:cmd[0] ssr[cmd[1];"APISECRET";apiSecret];
    first h
    }

// Handle what type of connection should be opened
// Unless specified preference is to use UDS
// If it isn't available then standard TCP/IP is used
// If eforced TLS for the connection TLS is used but the certificates must already be in place
.conn.connect:{[svc;conn;tmout;query]
    h:$[(conn[`encrypt]~`tls)&(.z.K>=3.4);
        .conn.hopen[`$":tcps://",":" sv .util.string conn[`host`port];tmout];
        (conn[`encrypt] in `ws`wss)&(.z.K>=3.0);
            .conn.wsOpen[string conn[`host];query;WS_KEY;WS_SECRET];
            (conn[`host] in (`localhost;.z.h))&(.z.o in `m64`l64)&(.z.K>=3.4);
                .conn.hopen[hsym `$"unix://",.util.string conn[`port];tmout];
                .conn.hopen[hsym `$":" sv .util.string conn[`host`port];tmout]
                ];
    .conn.HANDLES[svc]:(h;.z.P;1b);
    h
    }

// FInd out if a connection is already active
// If it isn't then handle opening it and also determine it's sign
.conn.getHandle:{[callback;conn;tmout;query]
    status:.conn.HANDLES[svc:` sv .util.symbol conn[`cluster`service`app`node]];
    handle:$[(null status[`handle])|(0b=status[`active]);
        .conn.connect[svc;conn;tmout;query];
        status[`handle]
        ];
    $[callback;
        abs handle;
        handle<0;
            handle;
            neg[handle]
    ]
    }

// Santiy check on the service name passed by the user 
// Check that it is the right length and also that an address exists for it
.conn.chkSvcName:{[svc]
    c:` vs svc;
    if[not count[c] in 3 4;'ServiceNameWrongLength];
    if[0=count select i from .conn.REGISTER where cluster=c[0],service=c[1],app=c[2];
        'ServiceNotAvailable];
    c
    }

// Find the address  for the requested service
.conn.findService:{[svc]
    $[3=count c:.conn.chkSvcName[svc];
        first select from .conn.REGISTER where cluster=c[0],service=c[1],app=c[2];
        first select from .conn.REGISTER where cluster=c[0],service=c[1],app=c[2],node=c[3]
        ]
    }

.conn.dropConnection:{[h]
    info:first 0!select from .conn.HANDLES where handle=h;
    .log.info("Connection dropped for handle";info);
    @[hclose;h;0b];
    update active:0b,handle:0Ni from `.conn.HANDLES where handle=h;
    }

.z.pc:.z.wc:.conn.dropConnection;

// Execute an asynchronous query without a timeout
.conn.async:.conn.execute[;;0;0b];

// Execute an asynchronous query with a timeout
.conn.asyncTmout:.conn.execute[;;;0b];

// Execute a synchronous query 
.conn.sync:.conn.execute[;;0;1b];

// Execute a synchronous query with a timeout
.conn.syncTmout:.conn.execute[;;;1b];

/
Example:


