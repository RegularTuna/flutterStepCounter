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





