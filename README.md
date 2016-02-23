# Cheddar_iOS
neucheddar.com


To run this project in development:

- Clone Repo
- Open .workspace file in Xcode
- Need to add EnvironmentConstants.swift file which should contain the following:


      // Start File
      
      import Foundation

      class EnvironmentConstants {
          static var pubNubSubscribeKey = "XXX"
          static var pubNubPublishKey = "XXX"
          static var parseApplicationId = "XXX"
          static var parseClientKey = "XXX"
      }
      
      // End File
      
      
- Click play button at top left
