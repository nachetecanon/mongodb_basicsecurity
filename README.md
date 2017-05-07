
https://docs.mongodb.com/manual/tutorial/enforce-keyfile-access-control-in-existing-replica-set/

https://blog.cloudandheat.com/index.php/de/2015/04/19/mongodb-replica-set-with-x509-authentication-and-self-signed-certificates/

admin=db.getSiblingDB("admin")
admin.createUser({ user: "mongoAdmin", pwd:"nachete1", roles: [ 
    { role: "userAdminAnyDatabase", db: "admin" }, 
    { role: "dbAdminAnyDatabase", db: "admin" }, 
    { role: "readWriteAnyDatabase", db:"admin" },
    { role: "clusterAdmin",  db: "admin" } 
] })