package com.e9friends.inain;

import java.util.Map;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.POST;
import retrofit2.http.Query;

public interface ApiService {
    @POST("/include/getLocation.php")
    Call<Void> sendLocation(@Body Map<String, Object> data);
}