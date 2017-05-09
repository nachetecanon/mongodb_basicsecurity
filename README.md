# MongoDB docker image

This image is based upon the original/official image from MongoDB at [GitHub](https://github.com/docker-library/mongo) 
  using the *3.4* version.
  
## Security
  
The original image has been altered in order to setup a basic *user/password* security scheme, so admin user
  is created and set up with *mongoAdmin* user and a generated password that can be found at */srv/mongodb/pwd*
  file.
  
## Use

You can run the image like this

    mongo -u "mongoAdmin" -p "tdhrqPcCvdU+0HWEcg==" --authenticationDatabase "admin"
    
Then create the database/s and user/s you want, 

    >use newDatabase
    >db.createUser({
          user: "john",
          pwd: "jomKeagAcmeaj7OftIrfegHok",
          roles: [
            { role: "readWrite", db: "newDatabase" }
          ]
          })

exit and test to enter again with the new u/p/database
    
    mongo -u "john" -p "jomKeagAcmeaj7OftIrfegHok" newDatabase
    
## Other params
    
You can use this image the same as the original, following the [official docs](https://github.com/docker-library/docs/tree/master/mongo), 
     the only difference is that an admin user will be created and given permissions to the following roles:
     
 * _userAdminAnyDatabase_
 * _dbAdminAnyDatabase_
 * _readWriteAnyDatabase_
 * _clusterAdmin_
 
 