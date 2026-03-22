package com.e9friends.inain;
import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.os.Build;
import android.os.Bundle;
import android.os.PersistableBundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.content.ContextCompat;

import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class MainActivity extends FlutterActivity {
    public static Context mainContext;
    private final String CHANNEL = "com.e9friends.inain";
    private final String API_BASE_URL = "http://inain.sanggong.net:1005";
    private final String TAG = "BACKGROUND LOCATION";
    private AlarmManager alarmManager;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        final SharedPreferences spf = getSharedPreferences("com.e9friends.inain", Context.MODE_PRIVATE);
        final MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL);
        final LocationManager locationManager = (LocationManager) this.getSystemService(Context.LOCATION_SERVICE);

        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
        && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{android.Manifest.permission.ACCESS_FINE_LOCATION}, 1);
        }
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            Location lastKnownLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
            if (lastKnownLocation != null) sendLocationToServer(lastKnownLocation);
        }

        final Intent alarmIntent = new Intent(this, LocationReceiver.class);
        final PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 0, alarmIntent, PendingIntent.FLAG_IMMUTABLE);

        channel.setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("startService")) {

                        mainContext = this;
                        this.alarmManager = (AlarmManager) this.getSystemService(Context.ALARM_SERVICE);
                        this.setAlarm(17, 47, pendingIntent);
                        this.setAlarm(19, 0, pendingIntent);

                        final SharedPreferences.Editor editor = spf.edit();
                        editor.putString("device_id", call.argument("device_id"));
                        editor.apply();
//                        this.startLocationService();
                    }
                }
        );
    }

    private void startLocationService() {
        final Intent serviceIntent = new Intent(this, BackgroundLocationService.class);
        startService(serviceIntent);
    }

    public void sendLocationToServer(Location location) {
        final SharedPreferences spf = this.getSharedPreferences("com.e9friends.inain", Context.MODE_PRIVATE);

        final HttpLoggingInterceptor loggingInterceptor = new HttpLoggingInterceptor();
        loggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);

        final OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .addInterceptor(loggingInterceptor)
                .build();
        // Retrofit을 사용하여 API 요청 보내기
        final Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(API_BASE_URL)
                .addConverterFactory(GsonConverterFactory.create())
                .client(okHttpClient)
                .build();

        final ApiService apiService = retrofit.create(ApiService.class); // ApiService는 Retrofit에서 정의한 서비스 인터페이스
        final Map<String, Object> data = new HashMap<>();
        data.put("latitude", location.getLatitude());
        data.put("longitude", location.getLongitude());
        data.put("device", spf.getString("device_id", ""));

        final Call<Void> call = apiService.sendLocation(data);
        call.enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Log.d(TAG, "Location sent to server.");
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Log.e(TAG, "Failed to send location: " + t.getMessage());
            }
        });
    }

    private void setAlarm(int hour, int minute, PendingIntent intent) {
        // 아침 10시와 저녁 7시에 알람 설정
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeInMillis(System.currentTimeMillis());
        calendar.set(Calendar.HOUR_OF_DAY, hour);
        calendar.set(Calendar.MINUTE, minute);

        Log.d(TAG, "HOUR: " + hour);
        Log.d(TAG, "MINUTE: " + minute);
        Log.d(TAG , "INTENT: " + intent);

        if (calendar.getTimeInMillis() <= System.currentTimeMillis()) {
            calendar.add(Calendar.DAY_OF_MONTH, 1); // 이미 지난 경우 다음날로 설정
        }
        long triggerAtMillis = calendar.getTimeInMillis();
        // 알람은 하루에 한 번 호출 (매일 오후 7시)
        long intervalMillis = 24 * 60 * 60 * 1000; // 24시간
        this.alarmManager.setInexactRepeating(AlarmManager.RTC, triggerAtMillis, intervalMillis, intent);
    }

}
