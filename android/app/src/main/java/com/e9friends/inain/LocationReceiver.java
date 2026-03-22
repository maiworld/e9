package com.e9friends.inain;

import android.Manifest;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.os.Build;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class LocationReceiver extends BroadcastReceiver {
    private final String API_BASE_URL = "http://inain.sanggong.net:1005";
    private final String TAG = "BACKGROUND LOCATION";

    @Override
    public void onReceive(Context context, Intent intent) {
        final LocationManager locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);

        Log.d(TAG, "ON RECEIVE");
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if(ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                if(locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                    Location lastKnownLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
                    if (lastKnownLocation != null) {
                        ((MainActivity) MainActivity.mainContext).sendLocationToServer(lastKnownLocation);
                    }
                }
            }
        } else {
            if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    && ActivityCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                Location lastKnownLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
                if (lastKnownLocation != null) {
                    ((MainActivity) MainActivity.mainContext).sendLocationToServer(lastKnownLocation);
                }
            }
        }
    }
}