# Robocorp Level 2 course

This repo contains the robot files for the completion of Course II as per the requirements given in  
https://robocorp.com/docs/courses/build-a-robot#rules-for-the-robot


The robot has been tested in both linux and windows OS. 

Issue: 
Note that the vault.json file is only accessible when the robot is run locally in robocorp lab or visual studio code. 

I observed that if the robot is run from the assistant the vault.json file is not accessible to the robot even though we have specified the vault.json location in devdata/env.json file. I am unsure why the course page suggest we use local json file while the best practice is to avoud using vault.json in the repository. Nonetheless if you want to know more about how to use the vault here is the link: https://robocorp.com/docs/development-guide/variables-and-secrets/vault


The robot will therefore only work if you clone this repo and then run the tasks.robot file in Robocorp Lab or Visual Studio code extension of Robocorp.
