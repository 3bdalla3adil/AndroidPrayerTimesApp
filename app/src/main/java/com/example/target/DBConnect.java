package com.example.target;


import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import java.util.ArrayList;


public class DBConnect extends SQLiteOpenHelper {
    public static final String DBName = "Milk.db";
    public static final Integer Version = 1;


    public DBConnect(Context context) {
        super(context, DBName, null, Version);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF Not EXISTS Customer " +
                "(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT," +
                "Name TEXT NOT NULL,PayType TEXT NOT NULL," +
                "Pound INTEGER NOT NULL)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int i, int i1) {
        db.execSQL("Drop Table IF EXISTS Customer");
        onCreate(db);

    }
    public void insertIntoRow(String name,String paytype,String pound){
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues contentValues = new ContentValues();
        contentValues.put("name",'|'+name+'|');
        contentValues.put("PayType",paytype+'|');
        contentValues.put("Pound",pound+'|');
        db.insert("Customer",null,contentValues);

    }
    public ArrayList getAllrecord(){

        ArrayList arrayList = new ArrayList();
        SQLiteDatabase db   = this.getReadableDatabase();
        Cursor cursor = db.rawQuery("select * from Customer",null);
        cursor.moveToFirst();
        String id = cursor.getString(cursor.getColumnIndex("id"));
        String name = cursor.getString(cursor.getColumnIndex("name"));
        String paytype = cursor.getString(cursor.getColumnIndex("paytype"));
        String pound = cursor.getString(cursor.getColumnIndex("pound"));
        while (!cursor.isAfterLast()){

            arrayList.add(Integer.valueOf(id),id);
//            arrayList.add(Integer.valueOf(id),name);
//            arrayList.add(Integer.valueOf(id),paytype);
//            arrayList.add(Integer.valueOf(id),pound);
            cursor.moveToNext();
        }

        return arrayList;
    }

}
