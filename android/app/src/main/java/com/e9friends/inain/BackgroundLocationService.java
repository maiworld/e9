package com.e9friends.inain;

import android.Manifest;
import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;

import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class BackgroundLocationService extends Service {
    private final String TAG = "BACKGROUND LOCATION";
    private final String API_BASE_URL = "http://inain.sanggong.net:1005";
    static private final String NOTIFICATION_CHANNEL_ID = "com.e9friends.inain.background";
    static private final String NOTIFICATION_CHANNEL_NAME = "com.e9friends.inain.background";
    private NotificationManager notificationManager;
    private NotificationCompat.Builder notification;
    private AlarmManager alarmManager;
    private PendingIntent pendingIntent;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        this.createChannel();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (this.notificationManager.getActiveNotifications().length == 0) {
                this.alarmManager = (AlarmManager) this.getSystemService(Context.ALARM_SERVICE);
                final Intent alarmIntent = new Intent(this, LocationReceiver.class);
                this.pendingIntent = PendingIntent.getBroadcast(this, 0, alarmIntent, PendingIntent.FLAG_IMMUTABLE);

                this.setAlarm( 11, 17);
                this.setAlarm( 19, 0);
                this.startForeground(startId, notification.build());
            }
        }
        return START_STICKY;
    }

    private void createChannel() {
        NotificationChannel channel = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            this.notificationManager = getSystemService(NotificationManager.class);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            channel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, NOTIFICATION_CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT);
            this.notificationManager.createNotificationChannel(channel);
        }
        this.notification = new NotificationCompat.Builder(getApplicationContext(), NOTIFICATION_SERVICE)
                .setContentTitle("E9 위치 서비스")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setChannelId(NOTIFICATION_CHANNEL_ID);
    }

    private void setAlarm(int hour, int minute) {
        // 아침 10시와 저녁 7시에 알람 설정
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeInMillis(System.currentTimeMillis());
        calendar.set(Calendar.HOUR_OF_DAY, hour);
        calendar.set(Calendar.MINUTE, minute);

        if (calendar.getTimeInMillis() <= System.currentTimeMillis()) {
            calendar.add(Calendar.DAY_OF_MONTH, 1); // 이미 지난 경우 다음날로 설정
        }
        long triggerAtMillis = calendar.getTimeInMillis();
        // 알람은 하루에 한 번 호출 (매일 오후 7시)
        long intervalMillis = 24 * 60 * 60 * 1000; // 24시간
        this.alarmManager.setRepeating(AlarmManager.RTC, triggerAtMillis, intervalMillis, this.pendingIntent);
    }
}