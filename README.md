# connectionManager

Connection manmagement tools for the q programming language.

Allows initialisation, management and optimsiation of network connections between q processes.

Will look for the default connections.csv file in the same directory as the script but it can be overwritten by setting the .conn.DIR variable before loading

Wrap dropConnection function in projects .z.pc handling for dropped connection monitoring
