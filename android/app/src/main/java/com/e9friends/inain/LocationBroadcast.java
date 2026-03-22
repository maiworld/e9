//package com.e9friends.inain;
//import android.app.AlarmManager;
//import android.app.PendingIntent;
//import android.content.BroadcastReceiver;
//import android.content.Context;
//import android.content.Intent;
//import android.util.Log;
//
//import java.util.Calendar;
//
//public class LocationBroadcast extends BroadcastReceiver {
//
//    @Override
//    public void onReceive(Context context, Intent intent) {
//
//        if (intent.getAction() != null) {
//            if (intent.getAction().equals("android.intent.action.BOOT_COMPLETED")) {
//                setAlarm(context, 10, 0); // 오전 10시
//                setAlarm(context, 17, 59); // 오후 7시
//                Log.d("ALARM OFF", "testestest");
//            } else {
//                Intent serviceIntent = new Intent(context, LocationReceiver.class);
//                context.startService(serviceIntent);
//                Log.d("ALARM ON", "TESTESTSETS");
//
//            }
//        }
//    }
//
//    private void setAlarm(Context context, int hour, int minute) {
//        // 아침 10시와 저녁 7시에 알람 설정
//        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
//        Intent alarmIntent = new Intent(context, this.getClass());
//        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 0, alarmIntent, 0);
//
//        Calendar calendar = Calendar.getInstance();
//        calendar.setTimeInMillis(System.currentTimeMillis());
//        calendar.set(Calendar.HOUR_OF_DAY, hour);
//        calendar.set(Calendar.MINUTE, minute);
//
//        if (calendar.before(Calendar.getInstance())) {
//            calendar.add(Calendar.DAY_OF_YEAR, 1);
//        }
//
//        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), AlarmManager.INTERVAL_DAY, pendingIntent);
//    }
//}
