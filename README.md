# steps_health

Flutter app to test sensors.

<h2>Steps</h2>

Showing daily and weekly steps 

<ins>Libraries used:</ins>

https://pub.dev/packages/health

<h2>GPS Location</h2>

Acessing the current location in latitude and longitude when a button in clicked and recording it in the background every 15 minutes
>[!IMPORTANT]
> For this to work in the background the user must have to manually access permissions settings and set it to "always allow". We can help the user get to the settings with the click of a button (already did) but it must be the user who actually sets the permission.  

> [!WARNING]
> Battery saver may kill the app in the background. The user must set the app settings to "Unrestricted" manually.

<ins>Libraries used:</ins>
https://pub.dev/packages/geolocator //for the actual gps location  
https://pub.dev/packages/workmanager //to schedule tasks in the background  
https://pub.dev/packages/shared_preferences //to use local_storage (might not be needed in the final version)  
https://pub.dev/packages/geocoding/install  //to translate latitude and logitude in actuall adress names  

<h2>Total Distance travelled</h2>
Using the GPS location implementation to calculate the distance between each point recorded and adding it together.

<ins>Libraries used:</ins>
https://pub.dev/packages/geolocator //for the actual gps location  
https://pub.dev/packages/shared_preferences //to use local_storage (might not be needed in the final version)  

<h2>Geofencing</h2>
Defining a radius around a specified point and detecting everytime the radius is left or entered.

>[!IMPORTANT]
> For now implemented with a paid plugin (free for testing) that is specificaly optimized to avoid the system shutting down  the app in the background and battery-saving.

<ins>Libraries used:</ins>
https://pub.dev/packages/flutter_background_geolocation#-using-the-plugin // geofencing ($\color{red}{\textsf{Not-free}}$)
https://pub.dev/packages/shared_preferences //to use local_storage (might not be needed in the final version)  

<h2>Time spent walking/running/still/in vehicle</h2>
Monitoring the current user activity and saving the amount of time spent on it.

>[!IMPORTANT]
> Has to be implemented as a foreground service (permanent notification in the notification bar) in order to continuously record the activity.

<ins>Libraries used:</ins>  
https://pub.dev/packages/flutter_activity_recognition  
https://pub.dev/packages/flutter_foreground_task
https://pub.dev/packages/sqflite //local database 


<h2>Time spent on the phone and in communication Apps</h2>
Providing records of the time spent in communication apps (apps needed to be indentified by us).
  
<ins>Libraries used:</ins>  
https://pub.dev/packages/usage_stats_new

<h2>Count phone unlocks and pickups</h2>  
Counting the amount of time the user unlocked the phone or interacted with the screen locked.

<ins>Libraries used:</ins>  
https://pub.dev/packages/usage_stats_new
  
<h2>Measure ambient light</h2>
Measures the ambient light in lux when a button is clicked

<ins>Libraries used:</ins>  
https://pub.dev/packages/light
